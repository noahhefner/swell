import Foundation

enum TokenType {
    case stringLiteral     // "some string literal"
    case pipe              // |
    case redirectOut       // >
    case redirectAppend    // >>
    case redirectErr       // 2>
    case redirectErrAppend // 2>>
    case redirect1         // 1>
    case redirect1Append   // 1>>
    case word              // ls
}

enum LexerError: Error {
    case runtimeError(String)
}

class Token {
    var text: String
    var type: TokenType

    init(text: String) {
        self.text = text

        switch text {
        case "|":
            self.type = .pipe
        case ">", "1>":
            self.type = .redirectOut
        case ">>", "1>>":
            self.type = .redirectAppend
        case "2>":
            self.type = .redirectErr
        case "2>>":
            self.type = .redirectErrAppend
        case let s where s.hasPrefix("\"") && s.hasSuffix("\""):
            self.type = .stringLiteral
        default:
            self.type = .word
        }
    }

    func isRedirectionToken() -> Bool {
        switch type {
        case .redirectOut, .redirectAppend, .redirectErr, .redirectErrAppend, .redirect1, .redirect1Append:
            return true
        default:
            return false
        }
    }
}

func Lexer(cmd: String) throws -> [Token]? {
    let trimmed = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    var tokens: [Token] = []
    var currentIndex = trimmed.startIndex

    func advance(_ by: Int = 1) {
        currentIndex = trimmed.index(currentIndex, offsetBy: by, limitedBy: trimmed.endIndex) ?? trimmed.endIndex
    }

    func peek(_ offset: Int = 1) -> Character? {
        let idx = trimmed.index(currentIndex, offsetBy: offset, limitedBy: trimmed.endIndex)
        return idx != nil && idx! < trimmed.endIndex ? trimmed[idx!] : nil
    }

    while currentIndex < trimmed.endIndex {
        let char = trimmed[currentIndex]

        // Skip whitespace
        if char.isWhitespace {
            advance()
            continue
        }

        // Pipe
        if char == "|" {
            tokens.append(Token(text: "|"))
            advance()
            continue
        }

        // String literal
        if char == "\"" {
            var str = "\""
            advance()
            while currentIndex < trimmed.endIndex {
                let c = trimmed[currentIndex]
                if c == "\\" && peek() == "\"" {
                    str.append("\\\"")
                    advance(2)
                } else if c == "\"" {
                    str.append("\"")
                    advance()
                    break
                } else {
                    str.append(c)
                    advance()
                }
            }
            tokens.append(Token(text: str))
            continue
        }

        // Redirections: 2>, 2>>, 1>, 1>>
        if char.isNumber, let next = peek(), next == ">" {
            let digit = char
            advance()
            if peek() == ">" {
                tokens.append(Token(text: "\(digit)>>"))
                advance(2)
            } else {
                tokens.append(Token(text: "\(digit)>"))
                advance()
            }
            continue
        }

        // Redirections: >, >>
        if char == ">" {
            if peek() == ">" {
                tokens.append(Token(text: ">>"))
                advance(2)
            } else {
                tokens.append(Token(text: ">"))
                advance()
            }
            continue
        }

        // Word
        var word = ""
        while currentIndex < trimmed.endIndex {
            let c = trimmed[currentIndex]
            if c.isWhitespace || c == "|" || c == ">" || c == "\"" {
                break
            }
            word.append(c)
            advance()
        }
        if !word.isEmpty {
            tokens.append(Token(text: word))
        }
    }

    return tokens
}
