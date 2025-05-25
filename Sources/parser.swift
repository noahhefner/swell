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
   
    // do not parse empty token list
    guard !tokens.isEmpty else {
        return nil
    }

    // to track which token the parser is currently evaluating
    var current: Int = 0
    var currentToken: Token? {
        return current < tokens.count ? tokens[current] : nil
    }

    // step to next token
    func advance () {
        if current < tokens.count {
            current += 1
        }
    }

    // returns next token in the list
    func peek () -> Token? {
        return current < (tokens.count - 2) ? tokens[current + 1] : nil
    }

    // determines if the current token is a given type 
    func match(_ tokenType: TokenType) throws -> Bool {
        guard let token = currentToken else {
            throw ParserError.runtimeError("Unexpected nil token in match().")
        }
        return token.type == tokenType
    }

    // NON-TERMINAL: Parse a command.
    func ParseCommand () throws -> Command {
        let pipeline:Pipeline = try ParsePipeline()
        return Command(pipeline: pipeline)
    }

    // NON-TERMINAL: Parse a pipeline.
    func ParsePipeline () throws -> Pipeline {
        var commands: [CommandWithRedirections] = []
    
        let firstCommand = try ParseRedirectionCommand()
        commands.append(firstCommand)
    
        while let token = currentToken, token.type == TokenType.pipe {
            print("Spinning in ParsePipeline")
            advance()
            let nextCommand = try ParseRedirectionCommand()
            commands.append(nextCommand)
        }
    
        return Pipeline(commandsWithRedirections: commands) 
    }

    // NON-TERMINAL: Parse a redirection command.
    func ParseRedirectionCommand () throws -> CommandWithRedirections {
        let simple = try ParseSimpleCommand()
        var redirs: [Redirection] = []
    
        while let token = currentToken, token.isRedirectionToken() {
            print("Spinning in ParseRedirectionCommand")
            let redir = try ParseRedirection()
            redirs.append(redir)
        }
    
        return CommandWithRedirections(simpleCommand: simple, redirections: redirs)
    }

    // parse a simple command
    func ParseSimpleCommand() throws -> SimpleCommand {
       
        // current token is not a word token
        guard let token = currentToken, token.type == TokenType.word else {
            throw ParserError.runtimeError("Unexpected token: \(tokens[current].text)")
        }

        // consume command name
        let commandName = token.text
        advance()
        
        // match the command args
        var args: [String] = []
        while let token = currentToken, token.type == TokenType.word {
            print("Spinning in ParseSimpleCommand")
            args.append(tokens[current].text)
            advance()
        }
    
        return SimpleCommand(command: commandName, args: args)
    }

    // parse a redirection
    func ParseRedirection() throws -> Redirection {
        
        guard let token = currentToken else {
            throw ParserError.runtimeError("Unexpected token: \(tokens[current].text)")
        }

        let fd: Int
        let append: Bool
        
        // determine what kind of redirection it is
        switch token.type {
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
    
        advance()  // consume redirection token
   
        guard let token = currentToken, token.type == TokenType.word else {
            throw ParserError.runtimeError("Unexpected token: \(tokens[current].text)")
        }
        let filename = token.text

        advance()  // consume filename
    
        return Redirection(fileDescriptor: fd, append: append, filename: filename)
    }
    
    // parse the command
    let node = try ParseCommand()

    // dangling token did not get parsed
    if let _ = peek() {
        return nil
    }

    return node

}


