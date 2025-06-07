import Foundation

enum ParserError: Error {
    case runtimeError(String)
}

func Parse(_ tokens: [Token]) throws -> Command? {
   
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
    
        while case Token.pipe? = currentToken {
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

        loop:repeat {

            guard let token = currentToken else {
                break loop
            }

            switch token {
            case .redirect, .redirectAppend, .redirectOut, .redirectOutAppend, .redirectErr, .redirectErrAppend:
                let redir = try ParseRedirection()
                redirs.append(redir)
            default:
                break loop
            }
            
        } while true
    
        return CommandWithRedirections(simpleCommand: simple, redirections: redirs)
    }

    // parse a simple command
    func ParseSimpleCommand() throws -> SimpleCommand {

        guard case let Token.word(command)? = currentToken else {
            throw ParserError.runtimeError("Unexpected token in ParseSimpleCommand")
        }

        // consume command name
        advance()
        
        // match the command args. args can be either words or string literals
        var args: [String] = []

        loop:repeat {

            guard let token = currentToken else {
                break loop
            }

            switch token {
            case .word, .stringLiteral:
                let arg = try parseArgument(token)
                args.append(arg)
                advance()
            default:
                break loop
            }

        } while true
    
        return SimpleCommand(command: command, args: args)
    }

    // parse a redirection
    func ParseRedirection() throws -> Redirection {
        
        guard let token = currentToken else {
            throw ParserError.runtimeError("Can't find token in ParseRedirection")
        }

        let fd: Int
        let append: Bool
        
        // determine what kind of redirection it is
        switch token {
        case .redirect, .redirectOut:
            fd = 1
            append = false
        case .redirectAppend, .redirectOutAppend:
            fd = 1
            append = true
        case .redirectErr:
            fd = 2
            append = false
        case .redirectErrAppend:
            fd = 2
            append = true
        default:
            throw ParserError.runtimeError("Unexpected token in ParseRedirection")
        }
    
        advance()  // consume redirection token
   
        guard case let Token.word(filename)? = currentToken else {
            throw ParserError.runtimeError("Unexpected token in ParseRedirection")
        }

        advance()  // consume filename
    
        return Redirection(fileDescriptor: fd, append: append, filename: filename)
    }

    func parseArgument(_ token: Token) throws -> String {
        switch token {
        case Token.stringLiteral(let str), Token.word(let str):
            return str.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        default:
            throw ParserError.runtimeError("Argument is not a string literal or word in ParseArgument")
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


