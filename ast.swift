// Abstract Syntax Tree for Swell shell

/* 
Implementation Goals:

1) Support commands with arguments
   ie. ls -al

2) Support pipes
   ie. ls | grep term

*/

struct Command {
    var simpleCommand: SimpleCommand
    var pipelineCommand: PipelineCommand
}

struct SimpleCommand {
    var program: String
    var args: [String]?
}

struct PipelineCommand {
    var commands: [SimpleCommand]
}
