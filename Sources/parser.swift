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

func Parse(tokens: [Token]) -> Command? {
    
    var current: Int = 0

    // step to next token
    func advance () {
        if current < (tokens.count - 1) {
            current += 1
        }
    }

    // returns next token in the list
    func peek () -> Token? {
        if current < (tokens.count - 1) {
            return tokens[current]
        }
        return nil
    }
    
    func ParseCommand () {

    }

    func ParsePipeline () {
    
    }

    func ParseRedirectionCommand {

    }

    func ParseSimpleCommand {

    }

    func ParseRedirection {
        
    }

    func ParseOutputRedirect {

    }

    func ParseErrorRedirect {

    }

    func ParseWord {

    }
    
    // parse the command
    let node = ParseCommand()

    // dangling token did not get parsed
    if let unexpected = peek() {
        return nil
    }

    return node

}


