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

        case 13: // Enter key
            break loop

        case 127: // Backspace
            if cursor > 0 {
                cursor -= 1
                buffer.remove(at: cursor)
                try redrawLine(buffer, cursor)
            }

        case 27: // Escape
            var seq = [UInt8](repeating: 0, count: 2)
            if read(STDIN_FILENO, &seq, 2) == 2 {
                if seq[0] == 91 {
                    switch seq[1] {
                    case 68: // Left
                        if cursor > 0 {
                            cursor -= 1
                            print("\u{1B}[1D", terminator: "")
                            fflush(nil)
                        }
                    case 67: // Right
                        if cursor < buffer.count {
                            cursor += 1
                            print("\u{1B}[1C", terminator: "")
                            fflush(nil)
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

    print("\u{1B}[2K\r# " + String(buffer), terminator: "")
    fflush(nil)

    // calculate the position of the cursor
    let pos = buffer.count - cursor

    // re-place cursor if it is not at the end of the line
    if pos > 0 {
        // \u{1B}[\(pos)D is an ANSI escape sequence to move the cursor left by 
        // pos columns.
        print("\u{1B}[\(pos)D", terminator: "")
        fflush(nil)
    }

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

    print("\r", terminator: "")
    fflush(nil)

    // main loop
    loop: repeat {

        // print prompt
        try redrawLine([Character](), 0)
    
        // read command
        let cmd = try getCommandFromUser()

        // move cursor to beginning of next line
        print("\r")
        fflush(nil)

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

    // successful exit
    exit(0)

}

// execute swell shell
try mainLoop()