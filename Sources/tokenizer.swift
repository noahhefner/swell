/*

Goals:

given a string, return a list of tokens

example commands:

ls("/path/to/dir").grep(".bashrc")

*/

import Foundation

enum TokenType {
    case identifier
    case parenthesis
    case comma
    case dot
    case assignmentOperator
    case stringLiteral
    case eof
    case null
    case unknown
}

class Token {
    
    var text: String
    var type: TokenType    

    init(text:String) {

        self.text = text

        switch text {
        case "(", ")":
            self.type = TokenType.parenthesis
        case ",":
            self.type = TokenType.comma
        case ".":
            self.type = TokenType.dot
        case "=":
            self.type = TokenType.assignmentOperator
        case let s where s.hasPrefix("\"") && s.hasSuffix("\""):
            self.type = TokenType.stringLiteral
        case let s where Token.isValidIdentifier(text: s):
            self.type = TokenType.identifier
        default:
            self.type = TokenType.unknown
        }

    }

    private static func isValidIdentifier(text: String) -> Bool {
        
        // validate the first character
        guard let first = text.first, first.isLetter || first == "_" else {
            return false
        }
        // validate remainder of the text
        return text.dropFirst().allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }

}
func Tokenize(cmd: String) -> [Token]? {
   
    // trim leading and trailing whitespace off of the command
    let trimmed = cmd.trimmingCharacters(in: .whitespacesAndNewlines)

    // command is empty
    if (trimmed.isEmpty) {
        return nil
    }

    var tokenList: [Token] = []
    
    var consumedToIndex: String.Index = trimmed.startIndex
    
    while consumedToIndex != trimmed.endIndex {

        var tokenString: String = ""

        if trimmed[consumedToIndex] == "\"" {
            // next token is a string literal

            // add leading double quote to token string
            tokenString.insert("\"", at: tokenString.startIndex)

            // increment the consumed index
            consumedToIndex = trimmed.index(consumedToIndex, offsetBy: 1)
            
            // evaluate two characters per iteration so that we can skip over
            // escaped double qoutes
            var end = trimmed.index(consumedToIndex, offsetBy: 2, limitedBy: trimmed.endIndex) ?? trimmed.endIndex
            var window = trimmed[consumedToIndex..<end]
           
            while true {

                if let firstChar = window.first {
                    tokenString.insert(firstChar, at: tokenString.endIndex)
                }

                // Move window forward one character
                consumedToIndex = trimmed.index(consumedToIndex, offsetBy: 1)
                end = trimmed.index(consumedToIndex, offsetBy: 2, limitedBy: trimmed.endIndex) ?? trimmed.endIndex
                window = trimmed[consumedToIndex..<end]
                
                if window != "\\\"" && window.last == "\"" {
                    tokenString += window
                    consumedToIndex = end
                    break
                }
                
            }

        } else if trimmed[consumedToIndex] == "|" {
            // next token is a pipe character

            // add pipe character to token string
            tokenString.insert(trimmed[consumedToIndex], at: tokenString.endIndex)
            // move consumed to index forward one character
            consumedToIndex = trimmed.index(consumedToIndex, offsetBy: 1)
        
        } else if trimmed[consumedToIndex].isWhitespace {
            // ignore whitespace characters
            
            // move consumed to index forward one character
            consumedToIndex = trimmed.index(consumedToIndex, offsetBy: 1)

        }

        if !tokenString.isEmpty {
            tokenList.append(Token(text: tokenString))
        }

    }

    return tokenList

}
