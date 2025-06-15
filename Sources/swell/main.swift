/// Swell shell

// @preconcurrency is used so that we can access stdout variable without 
// getting compile-time concurrency errors.
@preconcurrency import Glibc
import Foundation

/// Enables terminal "raw" mode.
func enableRawMode() {

    var raw = termios()
    tcgetattr(STDIN_FILENO, &raw)

    // input flags
    raw.c_iflag &= ~(UInt32(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | IXON))
    raw.c_iflag |= UInt32(ICRNL)

    // output flags
    raw.c_oflag |= UInt32(OPOST)
    raw.c_oflag |= UInt32(ONLCR)

    // local flags
    raw.c_lflag &= ~(UInt32(ECHO | ICANON | ISIG | IEXTEN))
    raw.c_lflag |= UInt32(ECHONL)

    // control flags
    raw.c_cflag |= UInt32(CS8)

    tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
}

/// Restores terminal attributes to the attributes in original.
///
/// - Parameter termios: Users terminal attributes.
func disableRawMode(original: inout termios) {
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &original)
}

/// Get the command from the user.
///
/// This function retrieves the input from the user. It also handles escape
/// sequences and redrawing the command line when the user moves the cursor by
/// pressing the arrow keys.
///
/// - Returns String: String representation of the users command.
func getCommandFromUser () throws -> String {

    var buffer = [Character]()
    var cursor = 0

    loop: repeat {

        // read a single character from standard in
        var c: UInt8 = 0
        let readBytes = read(STDIN_FILENO, &c, 1)

        // check number of read bytes is greater than zero to ensure read was
        // successful
        if readBytes <= 0 { break }

        switch c {

        // Enter key
        case 10:
            break loop

        // Backspace
        case 127:
            if cursor > 0 {
                cursor -= 1
                buffer.remove(at: cursor)
                try redrawLine(buffer, cursor)
            }

        // Escape sequences
        case 27:
            var seq = [UInt8](repeating: 0, count: 3)
            let n = read(STDIN_FILENO, &seq, 2)

            if n == 2 && seq[0] == 91 {
                switch seq[1] {

                // Left arrow
                case 68:
                    if cursor > 0 {
                        cursor -= 1
                        printAndFlush("\u{1B}[1D")
                    }
                
                // Right arrow
                case 67:
                    if cursor < buffer.count {
                        cursor += 1
                        printAndFlush("\u{1B}[1C")
                    }

                // Delete key
                case 51:
                    var tilde: UInt8 = 0
                    if read(STDIN_FILENO, &tilde, 1) == 1 && tilde == 126 {
                        if cursor < buffer.count {
                            buffer.remove(at: cursor)
                            try redrawLine(buffer, cursor)
                        }
                    }
                default:
                    break
                }
            }


        default:

            // add character to buffer
            let char = Character(UnicodeScalar(c))
            buffer.insert(char, at: cursor)
            cursor += 1
            try redrawLine(buffer, cursor)

        }

    } while true

    return String(buffer)

}

/// Redraws the command line with command buffer, placing cursor at cursor.
func redrawLine(_ buffer: [Character], _ cursor: Int) throws {

    // \u{1B}[2K is an ANSI escape sequence to clear the entire current line in 
    // the terminal.
    //
    // \r is a carriage return (moves cursor back to start of the line).
    //
    // # is the prompt.

    printAndFlush("\u{1B}[2K\r# " + String(buffer))

    // calculate the position of the cursor
    let pos = buffer.count - cursor

    // re-place cursor if it is not at the end of the line
    if pos > 0 {
        // \u{1B}[\(pos)D is an ANSI escape sequence to move the cursor left by 
        // pos columns.
        printAndFlush("\u{1B}[\(pos)D")
    }

}

/// Print the given string and terminator, then immediately flush stdout.
///
/// When Swift's print() is called without the terminator argument, standard
/// out is line-buffered. When print() is called with the terminator argument, 
/// standard out is fully buffered.
///
/// Since we've enabled raw mode, we need to manually flush standard out every 
/// time print() is called. This is accomplished by calling fflush(stdout).
func printAndFlush(_ str: String, terminator: String = "") {

    print(str, terminator: terminator)
    fflush(stdout)

}

/// Swell entrypoint.
func mainLoop () throws {

    // save users terminal attributes
    var userTermAttr = termios()
    tcgetattr(STDIN_FILENO, &userTermAttr)

    // enable raw mode
    enableRawMode()

    // restore terminal attributes when the shell exits
    defer {
        disableRawMode(original: &userTermAttr)
    }

    // move cursor to beginning of current line
    printAndFlush("\r")

    // create list of tokenizers
    let tokenizers: [Tokenizer] = [
        StringLiteral(),
        RedirectErrAppend(),
        RedirectOutAppend(),
        RedirectAppend(),
        RedirectErr(),
        RedirectOut(),
        Redirect(),
        Pipe(),
        Word()
    ]

    // create a lexer
    let lexer = Lexer(tokenizers: tokenizers)

    // main loop
    loop: repeat {

        // print prompt
        try redrawLine([Character](), 0)
    
        // read command
        let cmd = try getCommandFromUser()

        // move cursor to beginning of next line
        printAndFlush("\r", terminator: "\n")

        switch cmd {
        case "":
            // ignore blank commands
            continue
        case "exit":
            // exit shell
            break loop
        default:
            // execute command
            let tokens = try lexer.parse(cmd)
            if let parsedCommand = try Parse(tokens) {
                let executor = Executor()
                try executor.execute(command: parsedCommand)
            }
        }

    } while true

}

// execute swell shell
try mainLoop()

// successful exit
exit(0)