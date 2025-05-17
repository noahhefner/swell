// Abstract Syntax Tree for Swell shell

/* 
Implementation Goals:

1) Support commands with arguments
   ie. ls -al

2) Support pipes
   ie. ls | grep term


typealias Token = String

enum Token 

struct Command {
    var simpleCommand: SimpleCommand
    var pipelineCommand: PipelineCommand
}

struct SimpleCommand {
    var program: Token
    var args: [Token]?
}

struct PipelineCommand {
    var commands: [SimpleCommand]
}*/
