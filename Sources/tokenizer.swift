/*

Goals:

given a string, return a list of tokens

*/

let SpecialCharacters: [Character] = ["|"]

func Tokenize(cmd: String) -> [Token]? {
    
    // empty string
    if (cmd.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
        return nil
    }

    var tokenList: [Token]
    var currentToken: Token? = nil

    // extract tokens from command
    for character in cmd {

        // handle whitespace characters
        if character.isWhitespace {

            if currentToken != nil {

                // add current token to token list
                tokenList.append(currentToken!)

                // reset current token
                currentToken = nil

            }

        // handle special characters
        } else if SpecialCharacters.contains(character) {

            // add currentToken to token list
            if (currentToken != nil) {
                tokenList.append(currentToken!)
            }

            // add special character to token list
            tokenList.append(character)

            // reset current token
            currentToken = nil

        // handle command characters
        } else {

            // append character to current token
            currentToken += character

        }
    }

    return tokenList

}
