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

            guard let input = readLine() else {
                print()
                break
            }

            let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let result = execute(input)
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
                    FileHandle.standardError.write(Data("\(colorConfig.errorPrefix)error: \(error)\(colorConfig.errorSuffix)\n".utf8))
                } else {
                    FileHandle.standardError.write(Data("error: \(error)\n".utf8))
                }
                lastExitCode = code
            case .exit:
                running = false
            }
        }
    }

    private func execute(_ input: String) -> CommandResult {
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
            return result
        }
        return executeExternal(command: command, stdin: nil, stdoutDest: nil, stderrDest: nil)
    }

    private func executeBuiltin(_ command: ParsedCommand) -> CommandResult? {
        switch command.name {
        case "exit":
            return Exit.execute()
        case "cd":
            return CD.execute(path: command.arguments.first ?? "~", environment: &environment)
        case "pwd":
            return PWD.execute(environment: environment)
        case "export":
            return Export.execute(arguments: command.arguments, environment: &environment)
        case "echo":
            return Echo.execute(arguments: command.arguments)
        default:
            return nil
        }
    }

    private func executeExternal(command: ParsedCommand,
                                  stdin: FileHandle?,
                                  stdoutDest: FileHandle?,
                                  stderrDest: FileHandle?) -> CommandResult {
        guard let executable = environment.resolveExecutable(command.name) else {
            return .failure(error: "command not found: \(command.name)", exitCode: 127)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = command.arguments
        process.environment = environment.exportedEnvironment()

        if let stdin = stdin {
            process.standardInput = stdin
        }
        if let stdoutDest = stdoutDest {
            process.standardOutput = stdoutDest
        }
        if let stderrDest = stderrDest {
            process.standardError = stderrDest
        }

        let outPipe = stdoutDest == nil ? Pipe() : nil
        let errPipe = stderrDest == nil ? Pipe() : nil

        if outPipe != nil { process.standardOutput = outPipe! }
        if errPipe != nil { process.standardError = errPipe! }

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return .failure(error: "failed to launch \(command.name): \(error.localizedDescription)", exitCode: 1)
        }

        let output: String
        if let outPipe = outPipe {
            let data = outPipe.fileHandleForReading.readDataToEndOfFile()
            output = String(data: data, encoding: .utf8) ?? ""
        } else {
            output = ""
        }

        let exitCode = process.terminationStatus
        if exitCode != 0 {
            let errOutput: String
            if let errPipe = errPipe {
                let data = errPipe.fileHandleForReading.readDataToEndOfFile()
                errOutput = String(data: data, encoding: .utf8) ?? ""
            } else {
                errOutput = ""
            }
            let msg = errOutput.isEmpty ? "exit code \(exitCode)" : errOutput.trimmingCharacters(in: .whitespacesAndNewlines)
            return .failure(error: msg, exitCode: exitCode)
        }

        return .success(output: output)
    }

    private func executePipeline(_ pipeline: ParsedPipeline) -> CommandResult {
        let commands = pipeline.commands
        let count = commands.count

        var pipes: [Pipe] = []
        for _ in 0..<(count - 1) {
            pipes.append(Pipe())
        }

        var processes: [Process] = []
        var outputHandles: [FileHandle] = []

        for (index, cmd) in commands.enumerated() {
            let isBuiltin = isBuiltinCommand(cmd.name)
            if isBuiltin {
                if cmd.name == "exit" { return .exit }
                continue
            }

            guard let executable = environment.resolveExecutable(cmd.name) else {
                for p in processes { if p.isRunning { p.terminate() } }
                return .failure(error: "command not found: \(cmd.name)", exitCode: 127)
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = cmd.arguments
            process.environment = environment.exportedEnvironment()

            if index == 0 {
                process.standardInput = FileHandle.standardInput
            } else {
                process.standardInput = pipes[index - 1].fileHandleForReading
            }

            if index < count - 1 {
                process.standardOutput = pipes[index].fileHandleForWriting
            }

            for (pi, p) in pipes.enumerated() {
                if pi != index - 1 {
                    try? p.fileHandleForReading.close()
                }
                if pi != index {
                    try? p.fileHandleForWriting.close()
                }
            }

            do {
                try process.run()
                processes.append(process)
                outputHandles.append(process.standardOutput as? FileHandle ?? FileHandle.nullDevice)
            } catch {
                for p in processes { if p.isRunning { p.terminate() } }
                return .failure(error: "failed to launch \(cmd.name): \(error.localizedDescription)", exitCode: 1)
            }
        }

        for p in pipes {
            try? p.fileHandleForWriting.close()
        }

        var output = ""
        if let lastProcess = processes.last {
            let outPipe = Pipe()
            lastProcess.standardOutput = outPipe
            lastProcess.waitUntilExit()
            let data = outPipe.fileHandleForReading.readDataToEndOfFile()
            output = String(data: data, encoding: .utf8) ?? ""
        } else {
            for p in processes { p.waitUntilExit() }
        }

        let exitCode = processes.last?.terminationStatus ?? 0
        if exitCode != 0 {
            return .failure(error: "exit code \(exitCode)", exitCode: exitCode)
        }
        return .success(output: output)
    }

    private func isBuiltinCommand(_ name: String) -> Bool {
        ["cd", "pwd", "exit", "export", "echo"].contains(name)
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
