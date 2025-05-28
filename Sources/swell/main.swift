/// Swell shell

import Foundation
import Glibc

/// Enables raw mode via C library function cfmakeraw.
///
/// cfmakeraw sets the following terminal attributes in a termios struct:
///   termios_p->c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP
///                   | INLCR | IGNCR | ICRNL | IXON);
///   termios_p->c_oflag &= ~OPOST;
///   termios_p->c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
///   termios_p->c_cflag &= ~(CSIZE | PARENB);
///   termios_p->c_cflag |= CS8;
func enableRawMode() {
    var raw = termios()
    tcgetattr(STDIN_FILENO, &raw)
    cfmakeraw(&raw)
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
        case 13:
            break loop

        // Backspace
        case 127:
            if cursor > 0 {
                cursor -= 1
                buffer.remove(at: cursor)
                try redrawLine(buffer, cursor)
            }

        // Escape
        case 27:

            var seq = [UInt8](repeating: 0, count: 2)
            if read(STDIN_FILENO, &seq, 2) == 2 {
                if seq[0] == 91 {
                    switch seq[1] {

                    // left arrow key
                    case 68:
                        if cursor > 0 {
                            // \u{1B}[1D is the ANSI escape sequence to move
                            // the cursor one character to the left
                            cursor -= 1
                            printAndFlush("\u{1B}[1D")
                        }
                    
                    // right arrow key
                    case 67:
                        // \u{1B}[1C is the ANSI escape sequence to move
                        // the cursor one character to the left
                        if cursor < buffer.count {
                            cursor += 1
                            printAndFlush("\u{1B}[1C")
                        }
                    
                    default:
                        break loop
                    }
                }
            }

        default:
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

/// Print the given string and terminator, then flush.
///
/// A note on Swift's print() function:
/// When Swift's print() is called without the terminator argument, standard
/// out is line-buffered. When print() is called with the terminator argument, 
/// standard out is fully buffered.
///
/// Since we've enabled raw mode, we need to manually flush standard out every 
/// time print() is called. This is accomplished by calling fflush(nil).
///
/// Due to Swift's strict concurrency model, we cannot call fflush(stdout)
/// directly. Swift gives the following error:
///
/// fflush(stdout)
///        `- error: reference to var 'stdout' is not concurrency-safe because 
///           it involves shared mutable state
///
/// As a workaround, we can call fflush(nil) to flush all streams.
func printAndFlush(_ str: String, terminator: String = "") {

    print(str, terminator: terminator)
    fflush(nil)

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
            if let tokens = try Lexer(cmd: cmd) {
                if let parsedCommand = try Parse(tokens: tokens) {
                    let executor = Executor()
                    try executor.execute(command: parsedCommand)
                }
            }
        }

    } while true

}

// execute swell shell
try mainLoop()

// successful exit
exit(0)