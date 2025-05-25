import Foundation

class Executor {
    
    func execute(command: Command) throws {
        
        let pipeline = command.pipeline.commandsWithRedirections
        let isPipeline = pipeline.count > 1

        var previousPipe: Pipe?

        for (index, redirCommand) in pipeline.enumerated() {
            
            let process = Process()
            let pipe = isPipeline && index < pipeline.count - 1 ? Pipe() : nil

            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [redirCommand.simpleCommand.command] + redirCommand.simpleCommand.args

            // Connect input from previous pipe if this is not the first command
            if let inputPipe = previousPipe {
                process.standardInput = inputPipe.fileHandleForReading
            }

            // If not last command, pipe output
            if let outputPipe = pipe {
                process.standardOutput = outputPipe
            }

            /* / Redirections
            if let fd = redirCommand.redirections.fileDescriptor, let filename = redirCommand.redirections.filename {
                let mode = redirCommand.redirections.append ? "a" : "w"
                let fileHandle = FileHandle(forWritingAtPath: filename)
                    ?? FileManager.default.createFile(atPath: filename, contents: nil, attributes: nil).flatMap {
                        FileHandle(forWritingAtPath: filename)
                    }

                guard let handle = fileHandle else {
                    throw NSError(domain: "Executor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to open file: \(filename)"])
                }

                switch fd {
                case 1:
                    process.standardOutput = handle
                case 2:
                    process.standardError = handle
                default:
                    throw NSError(domain: "Executor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unsupported file descriptor: \(fd)"])
                }
            }
            */

            try process.run()
            previousPipe = pipe
        }
    }
}

