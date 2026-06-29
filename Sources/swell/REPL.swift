import Foundation

public enum CommandResult: Sendable {
    case success(output: String)
    case failure(error: String, exitCode: Int32)
    case exit
}

public final class REPL: @unchecked Sendable {
    private let parser = Parser()
    private var environment = ShellEnvironment()
    private var running = true
    private let colorResolver = ColorResolver()
    private let colorConfig = ColorConfig.default
    private var promptRenderer = PromptRenderer(config: PromptConfig.load())
    private var sigintReceived = false
    private var lastExitCode: Int32 = 0
    private var history = CommandHistory()
    private var lineEditor = LineEditor()

    public init() {
        applyEnvOverrides()
    }

    private func applyEnvOverrides() {
        if let pager = ProcessInfo.processInfo.environment["PAGER"] {
            environment.setVariable("PAGER", value: pager)
        }
        if let editor = ProcessInfo.processInfo.environment["EDITOR"] {
            environment.setVariable("EDITOR", value: editor)
        }
    }

    public func run() {
        setupSignalHandling()

        while running {
            if sigintReceived {
                sigintReceived = false
            }

            let colorState = colorResolver.resolve()
            let prompt = promptRenderer.render(env: environment, colorState: colorState)
            FileHandle.standardOutput.write(Data(prompt.utf8))
            try? FileHandle.standardOutput.synchronize()
            lineEditor.prompt = prompt

            let input = lineEditor.readCommand()
            guard !input.isEmpty else {
                if isatty(STDIN_FILENO) == 0 { break }
                continue
            }

            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let commandName = trimmed.split(separator: " ").first.map(String.init) ?? trimmed

            let result = execute(input)

            if commandName != "history" {
                history.add(input)
            }
            switch result {
            case .success(let output):
                if !output.isEmpty {
                    print(output, terminator: "")
                    if !output.hasSuffix("\n") { print() }
                }
                lastExitCode = 0
            case .failure(let error, let code):
                let colorState = colorResolver.resolve()
                if colorState.isEnabled {
                    let msg = "\(colorConfig.errorPrefix)error: \(error)\(colorConfig.errorSuffix)\n"
                    FileHandle.standardError.write(Data(msg.utf8))
                } else {
                    FileHandle.standardError.write(Data("error: \(error)\n".utf8))
                }
                lastExitCode = code
            case .exit:
                running = false
            }
        }
    }

    func execute(_ input: String) -> CommandResult {
        do {
            let pipeline = try parser.parse(input)

            guard let first = pipeline.commands.first else {
                return .failure(error: "empty command", exitCode: 1)
            }

            if pipeline.commands.count == 1 {
                return executeSingle(first)
            } else {
                return executePipeline(pipeline)
            }
        } catch ParseError.emptyInput {
            return .success(output: "")
        } catch ParseError.unexpectedToken(let msg) {
            return .failure(error: "unexpected token: \(msg)", exitCode: 1)
        } catch ParseError.missingFilename {
            return .failure(error: "expected filename after redirect", exitCode: 1)
        } catch ParseError.unmatchedQuote {
            return .failure(error: "unmatched quote", exitCode: 1)
        } catch {
            return .failure(error: "parse error: \(error)", exitCode: 1)
        }
    }

    private func executeSingle(_ command: ParsedCommand) -> CommandResult {
        if let result = executeBuiltin(command) {
            return handleBuiltinRedirect(result, command: command)
        }

        do {
            let stdoutDest = try command.stdoutRedirect.map(openRedirectFile)
            let stderrDest = try command.stderrRedirect.map(openRedirectFile)
            return executeExternal(command: command, stdin: nil, stdoutDest: stdoutDest, stderrDest: stderrDest)
        } catch {
            return .failure(error: "cannot open file for writing: \(error.localizedDescription)", exitCode: 1)
        }
    }

    private func openRedirectFile(_ target: RedirectTarget) throws -> FileHandle {
        switch target {
        case .overwrite(let path): return try Redirection.openForOverwrite(path)
        case .append(let path): return try Redirection.openForAppend(path)
        }
    }

    private func handleBuiltinRedirect(_ result: CommandResult, command: ParsedCommand) -> CommandResult {
        guard case .success(let output) = result else { return result }
        guard let stdoutRedirect = command.stdoutRedirect else { return result }
        do {
            let handle = try openRedirectFile(stdoutRedirect)
            handle.write(Data(output.utf8))
            try handle.close()
            return .success(output: "")
        } catch {
            return .failure(error: "cannot open file for writing: \(error.localizedDescription)", exitCode: 1)
        }
    }

    private func executeBuiltin(_ command: ParsedCommand) -> CommandResult? {
        switch command.name {
        case "exit":
            return Exit.execute()
        case "cd":
            return CdCommand.execute(path: command.arguments.first ?? "~", environment: &environment)
        case "pwd":
            return PWD.execute(environment: environment)
        case "export":
            return Export.execute(arguments: command.arguments, environment: &environment)
        case "echo":
            return Echo.execute(arguments: command.arguments)
        case "history":
            let output = History.execute(history: history.entries)
            return .success(output: output + "\n")
        default:
            return nil
        }
    }

    private func executeExternal(
        command: ParsedCommand,
        stdin: FileHandle?,
        stdoutDest: FileHandle?,
        stderrDest: FileHandle?
    ) -> CommandResult {
        guard let executable = environment.resolveExecutable(command.name) else {
            return .failure(error: "command not found: \(command.name)", exitCode: 127)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = command.arguments
        process.environment = environment.exportedEnvironment()

        if let stdin { process.standardInput = stdin }
        if let stdoutDest { process.standardOutput = stdoutDest }
        if let stderrDest { process.standardError = stderrDest }

        let outPipe = stdoutDest == nil ? Pipe() : nil
        let errPipe = stderrDest == nil ? Pipe() : nil

        if let outPipe { process.standardOutput = outPipe }
        if let errPipe { process.standardError = errPipe }

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return .failure(error: "failed to launch \(command.name): \(error.localizedDescription)", exitCode: 1)
        }

        let output = readPipeData(outPipe)
        let exitCode = process.terminationStatus
        if exitCode != 0 {
            let errOutput = readPipeData(errPipe)
            let msg = errOutput.isEmpty
                ? "exit code \(exitCode)"
                : errOutput.trimmingCharacters(in: .whitespacesAndNewlines)
            return .failure(error: msg, exitCode: exitCode)
        }

        return .success(output: output)
    }

    private func readPipeData(_ pipe: Pipe?) -> String {
        guard let pipe else { return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func executePipeline(_ pipeline: ParsedPipeline) -> CommandResult {
        let commands = pipeline.commands
        let count = commands.count
        let lastStdoutRedirect = commands.last?.stdoutRedirect

        let pipes: [Pipe] = (0..<(count - 1)).map { _ in Pipe() }
        let outPipe = Pipe()
        var processes: [Process] = []

        for (index, cmd) in commands.enumerated() {
            let result = launchPipelineProcess(
                command: cmd, at: index, total: count,
                pipes: pipes, outPipe: outPipe, environment: environment
            )
            switch result {
            case .process(let process):
                processes.append(process)
            case .failure(let error, let code):
                terminateAll(processes)
                return .failure(error: error, exitCode: code)
            case .exit:
                return .exit
            }
        }

        for pipe in pipes {
            try? pipe.fileHandleForReading.close()
            try? pipe.fileHandleForWriting.close()
        }
        try? outPipe.fileHandleForWriting.close()

        let hasStdout = lastStdoutRedirect != nil
        return collectPipelineOutput(processes: processes, outPipe: outPipe, hasStdoutRedirect: hasStdout)
    }

    private enum LaunchResult {
        case process(Process)
        case exit
        case failure(error: String, exitCode: Int32)
    }

    private func launchPipelineProcess(
        command: ParsedCommand,
        at index: Int,
        total: Int,
        pipes: [Pipe],
        outPipe: Pipe,
        environment: ShellEnvironment
    ) -> LaunchResult {
        if isBuiltinCommand(command.name) {
            return command.name == "exit" ? .exit : .process(Process())
        }

        guard let executable = environment.resolveExecutable(command.name) else {
            return .failure(error: "command not found: \(command.name)", exitCode: 127)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = command.arguments
        process.environment = environment.exportedEnvironment()

        if index == 0 {
            process.standardInput = FileHandle.standardInput
        } else {
            process.standardInput = pipes[index - 1].fileHandleForReading
        }

        if index < total - 1 {
            process.standardOutput = pipes[index].fileHandleForWriting
        } else {
            do {
                if let stdoutRedirect = command.stdoutRedirect {
                    process.standardOutput = try openRedirectFile(stdoutRedirect)
                } else {
                    process.standardOutput = outPipe.fileHandleForWriting
                }
                if let stderrRedirect = command.stderrRedirect {
                    process.standardError = try openRedirectFile(stderrRedirect)
                }
            } catch {
                return .failure(
                    error: "cannot open file for writing: \(error.localizedDescription)",
                    exitCode: 1
                )
            }
        }

        do {
            try process.run()
            return .process(process)
        } catch {
            return .failure(
                error: "failed to launch \(command.name): \(error.localizedDescription)",
                exitCode: 1
            )
        }
    }

    private func terminateAll(_ processes: [Process]) {
        for process in processes where process.isRunning {
            process.terminate()
        }
    }

    private func collectPipelineOutput(processes: [Process], outPipe: Pipe, hasStdoutRedirect: Bool) -> CommandResult {
        if let lastProcess = processes.last {
            lastProcess.waitUntilExit()
            let output: String
            if hasStdoutRedirect {
                output = ""
            } else {
                let data = outPipe.fileHandleForReading.readDataToEndOfFile()
                output = String(data: data, encoding: .utf8) ?? ""
            }

            if lastProcess.terminationStatus != 0 {
                return .failure(
                    error: "exit code \(lastProcess.terminationStatus)",
                    exitCode: lastProcess.terminationStatus
                )
            }
            return .success(output: output)
        }

        for process in processes {
            process.waitUntilExit()
        }
        return .success(output: "")
    }

    private func isBuiltinCommand(_ name: String) -> Bool {
        ["cd", "pwd", "exit", "export", "echo", "history"].contains(name)
    }

    private func useColorOutput() -> Bool {
        colorResolver.resolve().isEnabled
    }

    private func setupSignalHandling() {
        signal(SIGINT, SIG_IGN)
        signal(SIGPIPE, SIG_IGN)

        let sigintSource = DispatchSource.makeSignalSource(signal: SIGINT)
        sigintSource.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.sigintReceived = true
            }
        }
        sigintSource.resume()

        let sigpipeSource = DispatchSource.makeSignalSource(signal: SIGPIPE)
        sigpipeSource.setEventHandler { }
        sigpipeSource.resume()
    }
}
