/*

Goals:

given a string, return a list of tokens

*/

import Foundation

let SpecialCharacters: [Character] = ["|"]

func Tokenize(cmd: String) -> [Token]? {
   
    // trim leading and trailing whitespace off of the command
    let trimmed = cmd.trimmingCharacters(in: .whitespacesAndNewlines)

    // command is empty
    if (trimmed.isEmpty) {
        return nil
    }

    var tokenList: [Token] = []
    var currentToken: Token = ""

    // extract tokens from command
    for character in trimmed {

        // handle whitespace characters
        if character.isWhitespace {

            if currentToken != "" {

                // add current token to token list
                tokenList.append(currentToken)

                // reset current token
                currentToken = ""

            }

        // handle special characters
        } else if SpecialCharacters.contains(character) {

            // add currentToken to token list
            if (currentToken != "") {
                tokenList.append(currentToken)
            }

            // add special character to token list
            tokenList.append(String(character))

            // reset current token
            currentToken = ""

        // handle command characters
        } else {

            // append character to current token
            currentToken = currentToken + String(character)
        }
    }

    // last token in the command
    if currentToken != "" {
        tokenList.append(currentToken)
    }

    return tokenList

}
