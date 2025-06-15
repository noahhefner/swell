// Abstract Syntax Tree for Swell shell

struct Command {
    var pipeline: Pipeline
}

struct Pipeline {
    var commandsWithRedirections: [CommandWithRedirections] 
}

struct CommandWithRedirections {
    var simpleCommand: SimpleCommand
    var redirections: [Redirection]
}

struct Redirection {
    var fileDescriptor: Int  // 1 for stdout, 2 for stderr
    var append: Bool         // append mode ?
    var filename: String     // name of file to write to
}

struct SimpleCommand {
    var command: String
    var args: [String]
}
