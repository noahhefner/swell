import Foundation

enum TokenType {
    case stringLiteral
    case pipe
    case redirectOut
    case redirectAppend
    case redirectErr
    case redirectErrAppend
    case word
}

enum LexerError: Error {
    case runtimeError(String)
}

class Token {
    
    // Raw text of the token
    var text: String
    // Enum for the type of the token
    var type: TokenType    

    /// Creates a new instance of a Token object. This constructor sets
    /// the self.type property based on the content of text.
    ///
    /// Paramater text: The text of the token.
    init(text:String) {

        self.text = text

        switch text {
        case "|":
            self.type = TokenType.pipe
        case ">":
            self.type = TokenType.redirectOut
        case ">>":
            self.type = TokenType.redirectAppend
        case "2>":
            self.type = TokenType.redirectErr
        case "2>>":
            self.type = TokenType.redirectErrAppend
        case let s where s.hasPrefix("\"") && s.hasSuffix("\""):
            self.type = TokenType.stringLiteral
        default:
            self.type = TokenType.word
        }

    }

    // returns true if the token is a redirection token, false otherwise
    func isRedirectionToken() -> Bool {
        switch self.type {
        case .redirectOut, .redirectAppend, .redirectErr, .redirectErrAppend:
            return true
        default:
            return false
        }
    }
    
}

func Lexer(cmd: String) throws -> [Token]? {
   
    let trimmed = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
    
    guard !trimmed.isEmpty else {
        return nil
    }

    // Index of current character
    var currentIndex = trimmed.startIndex

    // Computed property: Current character
    var currentChar: Character? {
        return currentIndex < trimmed.endIndex ? trimmed[currentIndex] : nil
    }

    // move forward one character
    func advance() {
        if currentIndex != trimmed.endIndex {
            currentIndex = trimmed.index(currentIndex, offsetBy: 1)
        }
    }

    // look at the next character
    func peek() -> Character? {
        let nextIndex = trimmed.index(currentIndex, offsetBy: 1)
        if nextIndex != trimmed.endIndex {
            return trimmed[nextIndex]
        }
        return nil
    }

    var tokenList: [Token] = []

    while currentIndex != trimmed.endIndex {

        //print("Spiinning in lexer")

        var tokenString: String = ""

        guard let char = currentChar else {
            throw LexerError.runtimeError("Can't find current character in lexer.")
        }

        if char == "\"" {
            // next token is a string literal

            // add leading double quote to token string
            tokenString.append("\"")

            // increment the consumed index
            advance()

            // evaluate two characters per iteration so that we can skip over
            // escaped double qoutes
            var end = trimmed.index(currentIndex, offsetBy: 2, limitedBy: trimmed.endIndex) ?? trimmed.endIndex
            var window = trimmed[currentIndex..<end]
           
            while true {

                if let firstChar = window.first {
                    tokenString.insert(firstChar, at: tokenString.endIndex)
                }

                // Move window forward one character
                advance()
                end = trimmed.index(currentIndex, offsetBy: 2, limitedBy: trimmed.endIndex) ?? trimmed.endIndex
                window = trimmed[currentIndex..<end]
                
                if window != "\\\"" && window.last == "\"" {
                    tokenString += window
                    currentIndex = end
                    break
                }
                
            }

        } else if char == "|" {
            // next token is a pipe character

            tokenString.append(char)
            advance()
        
        } else if char.isWhitespace {
            // ignore whitespace characters
            
            advance()

        } else if char == ">" {
            // next token is redirect
        
            tokenString.append(char)
            advance()

        } else {
            // next token is a word

            while let wordChar = currentChar {

                // Break on delimiters (whitespace or known punctuation)
                if wordChar.isWhitespace || wordChar == "|" {
                    break
                }

                tokenString.append(wordChar)
                advance()
            }
        }

        if !tokenString.isEmpty {
            tokenList.append(Token(text: tokenString))
        }

    }

    return tokenList

}
