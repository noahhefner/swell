// Command executorfor Swell shell

import Foundation

class Executor {

    func execute(command: Command) throws {

        let pipeline = command.pipeline.commandsWithRedirections
        let isPipeline = pipeline.count > 1

        var previousPipe: Foundation.Pipe?
        var processes: [Process] = []

        for (index, redirCommand) in pipeline.enumerated() {
            let process = Process()
            let pipe = isPipeline && index < pipeline.count - 1 ? Foundation.Pipe() : nil

            // Use PATH resolution via /usr/bin/env
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [redirCommand.simpleCommand.command] + redirCommand.simpleCommand.args

            // Pipe input from previous command (if any)
            if let inputPipe = previousPipe {
                process.standardInput = inputPipe.fileHandleForReading
            }

            // Pipe output to next command (if any)
            if let outputPipe = pipe {
                process.standardOutput = outputPipe
            }

            // Redirections
            for redirection in redirCommand.redirections {

                let filename = redirection.filename
                var fileHandle = FileHandle(forWritingAtPath: filename)

                if fileHandle == nil {
                    let created = FileManager.default.createFile(atPath: filename, contents: nil, attributes: nil)
                    if created {
                        fileHandle = FileHandle(forWritingAtPath: filename)
                    }
                }

                guard let handle = fileHandle else {
                    throw NSError(domain: "Executor", code: 3, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to open file for redirection: \(filename)"
                    ])
                }

                if redirection.append {
                    handle.seekToEndOfFile()
                }

                switch redirection.fileDescriptor {
                case 1:
                    process.standardOutput = handle
                case 2:
                    process.standardError = handle
                default:
                    throw NSError(domain: "Executor", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "Unsupported file descriptor: \(redirection.fileDescriptor)"
                    ])
                }
            }

            try process.run()
            processes.append(process)
            previousPipe = pipe
        }

        // Now wait for all processes
        for process in processes {
            process.waitUntilExit()
        }
    }
}
