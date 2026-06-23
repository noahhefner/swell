import Foundation

public struct PipelineExecutor: Sendable {
    public static func execute(commands: [ParsedCommand],
                                environment: ShellEnvironment) -> CommandResult {
        guard commands.count > 1 else {
            return .failure(error: "pipeline requires at least 2 commands", exitCode: 1)
        }

        var pipes: [Pipe] = []
        for _ in 0..<(commands.count - 1) {
            pipes.append(Pipe())
        }

        var processes: [Process] = []

        for (index, cmd) in commands.enumerated() {
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
            } else if index - 1 < pipes.count {
                let readHandle = pipes[index - 1].fileHandleForReading
                process.standardInput = readHandle
            }

            if index < commands.count - 1, index < pipes.count {
                let writeHandle = pipes[index].fileHandleForWriting
                process.standardOutput = writeHandle
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
}
