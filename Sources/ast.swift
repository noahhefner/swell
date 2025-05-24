// Abstract Syntax Tree for Swell shell

/*

Grammar rules:

command ::= pipeline ;

pipeline ::= redirection_command { "|" redirection_command }

redirection_command ::= simple_command { redirection }

simple_command ::= WORD { WORD } ;

redirection ::= output_redirect | error_redirect ;

output_redirect ::= ( ">" | ">>" ) WORD;

error_redirect ::= ( "2>" | "2>>" ) WORD ;

WORD ::= ? any sequence of non special characters ? ;
*/

// command ::= pipeline ;
struct Command {
    var pipeline: Pipeline
}

// pipeline ::= redirection_command { "|" redirection_command }
struct Pipeline {
    var commandsWithRedirections: [commandWithRedirections] 
}

// redirection_command ::= simple_command { redirection }
struct CommandWithRedirections {
    var simpleCommand: SimpleCommand
    var redirections: [Redirections]
}

struct Redirection {
    // 1 for stdout, 2 for stderr
    var fileDescriptor: Int
    // true if ">>" or "2>>"
    var append: Bool
    // file to redirect to
    var filename: String
}

// simple_command ::= WORD { WORD } ;
struct SimpleCommand {
    var command: String
    var args: [String]
}
