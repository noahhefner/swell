// swell shell

import Glibc

func read_cmd() -> String {
    if let cmd = readLine() {
        return cmd
    }
    return ""
}

func prompt() {
    print("# ", terminator: "")
}

loop: repeat {

    // print prompt
    prompt()
   
    // read command
    let cmd = read_cmd()


    switch cmd {
    case "":
        continue
    case "exit":
        print("Goodbye!")
        break loop
    default:
        if let tokens = Lexer(cmd: cmd) {
            for t in tokens {
                print(t.text)
            }
            if let parsed = try Parse(tokens: tokens) {
                print(parsed)
            }
        }
    }

} while true

exit(0)
