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
        if let tokens = try Lexer(cmd: cmd) {
            if let parsedCommand = try Parse(tokens: tokens) {
                let executor = Executor()
                try executor.execute(command: parsedCommand)
            }
        }
    }

} while true

exit(0)
