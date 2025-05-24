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

enum ParserError: Error {
    case runtimeError(String)
}

func Parse(tokens: [Token]) throws -> Command? {
    
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

    // determines if the current token is a given type 
    func match(_ tokenType: TokenType) -> Bool {
        return tokens[current].type == tokenType
    }

    func ParseCommand () throws -> Command {
        let pipeline:Pipeline = try ParsePipeline()
        return Command(pipeline: pipeline)
    }

    func ParsePipeline () throws -> Pipeline {
        var commands: [CommandWithRedirections] = []
    
        let firstCommand = try ParseRedirectionCommand()
        commands.append(firstCommand)
    
        while match(TokenType.pipe) {
            advance()
            let nextCommand = try ParseRedirectionCommand()
            commands.append(nextCommand)
        }
    
        return Pipeline(commandsWithRedirections: commands) 
    }

    func ParseRedirectionCommand () throws -> CommandWithRedirections {
        let simple = try ParseSimpleCommand()
        var redirs: [Redirection] = []
    
        while tokens[current].isRedirectionToken() {
            let redir = try ParseRedirection()
            redirs.append(redir)
        }
    
        return CommandWithRedirections(simpleCommand: simple, redirections: redirs)
    }

    // parse a simple command
    func ParseSimpleCommand() throws -> SimpleCommand {
       
        // current token is not an identifier
        guard TokenType.identifier == tokens[current].type else {
            throw ParserError.runtimeError("Unexpected token: \(tokens[current].text)")
        }

        let name = tokens[current].text
    
        var args: [String] = []
        advance() // consume command name

        // match the command args
        while TokenType.identifier == tokens[current].type {
            args.append(tokens[current].text)
            advance()
        }
    
        return SimpleCommand(command: name, args: args)
    }

    // parse a redirection
    func ParseRedirection() throws -> Redirection {
        let fd: Int
        let append: Bool
        
        // determine what kind of redirection it is
        switch tokens[current].type {
        case .redirectOut:
            fd = 1
            append = false
        case .redirectAppend:
            fd = 1
            append = true
        case .redirectErr:
            fd = 2
            append = false
        case .redirectErrAppend:
            fd = 2
            append = true
        default:
            throw ParserError.runtimeError("Unexpected token: \(tokens[current].text)")
        }
    
        advance() // consume redirection token
   
        guard TokenType.identifier == tokens[current].type else {
            throw ParserError.runtimeError("Unexpected token: \(tokens[current].text)")
        }
        let filename = tokens[current].text

        advance()
    
        return Redirection(fileDescriptor: fd, append: append, filename: filename)
    }

    func ParseIdentifier() -> Bool {
        if TokenType.identifier == tokens[current].type {
            return true
        }
        return false
    }
    
    // parse the command
    let node = try ParseCommand()

    // dangling token did not get parsed
    if let _ = peek() {
        return nil
    }

    return node

}


