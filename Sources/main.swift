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

func exec_cmd(cmd: String) {

    let parts = cmd.split(separator: " ").map { String($0) }
    let args: [UnsafeMutablePointer<CChar>?] = parts.map { strdup($0) } + [nil]

    let pid = fork()

    switch pid {
    case 0:
        execvp(args[0]!, args)
        perror("execvp")
        exit(1)
    case let x where x > 0:
        // Parent process
        var status: Int32 = 0
        waitpid(pid, &status, 0)
        print("Child exited with status \(status)")
    default:
        perror("Fork failure!")
    }
}

loop: repeat {

    // print prompt
    prompt()
   
    // read command
    let cmd = read_cmd()

    print(test)

    switch cmd {
    case "":
        continue
    case "exit":
        print("Goodbye!")
        break loop
    default:
        exec_cmd(cmd: cmd)
    }

} while true

exit(0)
