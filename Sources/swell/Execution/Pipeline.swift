import Foundation

private enum LaunchResult {
    case process(Process)
    case failure(error: String, exitCode: Int32)
}

public struct PipelineExecutor: Sendable {
    public static func execute(
        commands: [ParsedCommand],
        environment: ShellEnvironment
    ) -> CommandResult {
        guard commands.count > 1 else {
            return .failure(error: "pipeline requires at least 2 commands", exitCode: 1)
        }

        let pipes = makePipes(count: commands.count - 1)
        var processes: [Process] = []

        for (index, cmd) in commands.enumerated() {
            let result = launchProcess(
                command: cmd,
                at: index,
                total: commands.count,
                environment: environment,
                pipes: pipes
            )
            switch result {
            case .process(let process):
                processes.append(process)
            case .failure(let error, let code):
                terminateAll(processes)
                return .failure(error: error, exitCode: code)
            }
        }

        closePipeWriters(pipes)
        return collectResults(processes: processes)
    }

    private static func makePipes(count: Int) -> [Pipe] {
        (0..<count).map { _ in Pipe() }
    }

    private static func launchProcess(
        command: ParsedCommand,
        at index: Int,
        total: Int,
        environment: ShellEnvironment,
        pipes: [Pipe]
    ) -> LaunchResult {
        guard let executable = environment.resolveExecutable(command.name) else {
            return .failure(error: "command not found: \(command.name)", exitCode: 127)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = command.arguments
        process.environment = environment.exportedEnvironment()

        if index == 0 {
            process.standardInput = FileHandle.standardInput
        } else if index - 1 < pipes.count {
            process.standardInput = pipes[index - 1].fileHandleForReading
        }

        if index < total - 1, index < pipes.count {
            process.standardOutput = pipes[index].fileHandleForWriting
        }

        closeUnusedPipes(at: index, pipes: pipes)

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

    private static func closeUnusedPipes(at index: Int, pipes: [Pipe]) {
        for (pipeIndex, pipe) in pipes.enumerated() {
            if pipeIndex != index - 1 {
                try? pipe.fileHandleForReading.close()
            }
            if pipeIndex != index {
                try? pipe.fileHandleForWriting.close()
            }
        }
    }

    private static func closePipeWriters(_ pipes: [Pipe]) {
        for pipe in pipes {
            try? pipe.fileHandleForWriting.close()
        }
    }

    private static func terminateAll(_ processes: [Process]) {
        for process in processes where process.isRunning {
            process.terminate()
        }
    }

    private static func collectResults(processes: [Process]) -> CommandResult {
        if let lastProcess = processes.last {
            let outPipe = Pipe()
            lastProcess.standardOutput = outPipe
            lastProcess.waitUntilExit()
            let data = outPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if lastProcess.terminationStatus != 0 {
                let code = lastProcess.terminationStatus
                return .failure(error: "exit code \(code)", exitCode: code)
            }
            return .success(output: output)
        }

        for process in processes {
            process.waitUntilExit()
        }
        return .success(output: "")
    }
}
