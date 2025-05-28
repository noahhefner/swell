import Foundation

class Executor {

    func execute(command: Command) throws {

        let pipeline = command.pipeline.commandsWithRedirections
        let isPipeline = pipeline.count > 1

        var previousPipe: Pipe?
        var processes: [Process] = []

        for (index, redirCommand) in pipeline.enumerated() {
            let process = Process()
            let pipe = isPipeline && index < pipeline.count - 1 ? Pipe() : nil

            // Use PATH resolution via /usr/bin/env
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [redirCommand.simpleCommand.command] + redirCommand.simpleCommand.args

            // Pipe input from previous command (if any)
            if let inputPipe = previousPipe {
                process.standardInput = inputPipe.fileHandleForReading
            }

            if let outputPipe = pipe {
                // Pipe output directly to next command
                process.standardOutput = outputPipe
            } else {
                // Command is the last command in the pipeline. Because raw 
                // mode is enabled, we need to intercept the command output
                // and replace the \n characters with \r\n. This ensures that
                // for multi-line command output, the cursor is returned to the
                // start of the next line after each line is printed.
                let outputPipe = Pipe()
                process.standardOutput = outputPipe

                outputPipe.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    guard !data.isEmpty else { return }
                    if let text = String(data: data, encoding: .utf8) {
                        // Normalize newlines
                        let fixed = text.replacingOccurrences(of: "\n", with: "\r\n")
                        printAndFlush(fixed)
                    }
                }
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
