import Foundation

enum Token {
    case stringLiteral(String)  // "some string literal"
    case pipe                   // |
    case redirect               // >
    case redirectAppend         // >>
    case redirectOut            // 1>
    case redirectOutAppend      // 1>>
    case redirectErr            // 2>
    case redirectErrAppend      // 2>>
    case word(String)           // ls, whoami, pwd
}

enum LexerError: Error {
    case matchNotFound(String)
}

protocol Tokenizer {
    var regexPattern: Regex<Substring> { get }
    func token (_ match: String) -> Token
}

struct StringLiteral:Tokenizer {
    
    var regexPattern: Regex<Substring> = try! Regex(#""(?:[^"\\]|\\.)*""#)

    func token (_ match: String) -> Token {

        return Token.stringLiteral(match)

    }

}

struct Pipe:Tokenizer {

    var regexPattern: Regex<Substring> = try! Regex(#"\|"#)

    func token (_ match: String) -> Token {

        return Token.pipe

    }

}

struct Redirect: Tokenizer {

    var regexPattern: Regex<Substring> = try! Regex(#">"#)
    
    func token(_ match: String) -> Token {
        return Token.redirect
    }
}

struct RedirectAppend: Tokenizer {

    var regexPattern: Regex<Substring> = try! Regex(#">>"#)

    func token(_ match: String) -> Token {
        return Token.redirectAppend
    }
}

struct RedirectOut: Tokenizer {

    var regexPattern: Regex<Substring> = try! Regex(#"1>"#)

    func token(_ match: String) -> Token {
        return Token.redirectOut
    }
}

struct RedirectOutAppend: Tokenizer {

    var regexPattern: Regex<Substring> = try! Regex(#"1>>"#)

    func token(_ match: String) -> Token {
        return Token.redirectOutAppend
    }
}

struct RedirectErr: Tokenizer {

    var regexPattern: Regex<Substring> = try! Regex(#"2>"#)

    func token(_ match: String) -> Token {
        return Token.redirectErr
    }
}

struct RedirectErrAppend: Tokenizer {

    var regexPattern: Regex<Substring> = try! Regex(#"2>>"#)

    func token(_ match: String) -> Token {
        return Token.redirectErrAppend
    }
}

struct Word: Tokenizer {
    
    var regexPattern: Regex<Substring> = try! Regex(#"[^\s|><"]+"#)

    func token(_ match: String) -> Token {
        return Token.word(match)
    }
}

final class Lexer {

    var tokenizers: [Tokenizer]

    init(tokenizers: [Tokenizer]) {
        self.tokenizers = tokenizers
    }

    func parse(_ cmd: String) throws -> [Token] {

        let trimmed = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [Token]() }

        var content = trimmed
        var tokens = [Token]()

        while content.count > 0 {

            var foundMatch = false

            for tokenizer in self.tokenizers {

                if let match = try tokenizer.regexPattern.prefixMatch(in: content) {

                    let token = tokenizer.token(String(match.output))

					tokens.append(token)
					content.removeFirst(match.count)
					foundMatch = true

					break

                }

            }

            if !foundMatch {
				throw LexerError.matchNotFound(content)
			}

            // trim any leading whitespace
            content = String(content.drop(while: { $0.isWhitespace }))

        }

        return tokens

    }

}