import Foundation

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

    // Parse a command.
    func ParseCommand () throws -> Command {
        let pipeline:Pipeline = try ParsePipeline()
        return Command(pipeline: pipeline)
    }

    // Parse a pipeline.
    func ParsePipeline () throws -> Pipeline {
        var commands: [CommandWithRedirections] = []
    
        let firstCommand = try ParseRedirectionCommand()
        commands.append(firstCommand)
    
        while let token = currentToken, token.type == TokenType.pipe {
            advance()
            let nextCommand = try ParseRedirectionCommand()
            commands.append(nextCommand)
        }
    
        return Pipeline(commandsWithRedirections: commands) 
    }

    // Parse a redirection command.
    func ParseRedirectionCommand () throws -> CommandWithRedirections {
        let simple = try ParseSimpleCommand()
        var redirs: [Redirection] = []
    
        while let token = currentToken, token.isRedirectionToken() {
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
        
        // match the command args. args can be either words or string literals
        var args: [String] = []
        while let token = currentToken, token.type == TokenType.word || token.type == TokenType.stringLiteral {
            
            let arg = parseArgument(token)
            args.append(arg)
            advance()
        }
    
        return SimpleCommand(command: commandName, args: args)
    }

    // parse a redirection
    func ParseRedirection() throws -> Redirection {
        
        guard let token = currentToken else {
            throw ParserError.runtimeError("Can't find token in ParseRedirection")
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
            throw ParserError.runtimeError("Unexpected token: \(token.text)")
        }
    
        advance()  // consume redirection token
   
        guard let token = currentToken, token.type == TokenType.word else {
            throw ParserError.runtimeError("Unexpected token: \(token.text)")
        }
        let filename = token.text

        advance()  // consume filename
    
        return Redirection(fileDescriptor: fd, append: append, filename: filename)
    }

    func parseArgument(_ token: Token) -> String {
        switch token.type {
        case .stringLiteral:
            return token.text.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        default:
            return token.text
        }
    }
    
    // parse the command
    let node = try ParseCommand()

    // dangling token did not get parsed
    if let _ = peek() {
        return nil
    }

    return node

}


