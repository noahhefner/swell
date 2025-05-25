import Foundation

class Executor {
    
    func execute(command: Command) throws {
        
        let pipeline = command.pipeline.commandsWithRedirections
        let isPipeline = pipeline.count > 1

        var previousPipe: Pipe?

        for (index, redirCommand) in pipeline.enumerated() {
           
            print("Spinning in executor")

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

            // Redirections
            for redirection in redirCommand.redirections {
                
                // file to redirect to
                let filename = redirection.filename

                // Try to open it first
                var fileHandle = FileHandle(forWritingAtPath: filename)

                if fileHandle == nil {
                    // If it doesn't exist, try to create it
                    let created = FileManager.default.createFile(atPath: filename, contents: nil, attributes: nil)
                    if created {
                        fileHandle = FileHandle(forWritingAtPath: filename)
                    }
                }

                guard let handle = fileHandle else {
                        throw NSError(domain: "Executor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to open file for redirection: \(filename)"])
                }
                
                if redirection.append {
                    // Move to the end of the file to append
                    handle.seekToEndOfFile()
                }

                switch redirection.fileDescriptor {
                case 1:
                    process.standardOutput = handle
                case 2:
                    process.standardError = handle
                default:
                    throw NSError(domain: "Executor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unsupported file descriptor: \(redirection.fileDescriptor)"])
                }
                
            }

            try process.run()
            previousPipe = pipe
        }
    }
}

