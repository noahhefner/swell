import Foundation

#if os(Linux)
import Glibc
#else
import Darwin
#endif

private nonisolated(unsafe) var sigintReceivedDuringInput = false

private let sigintHandler: @convention(c) (Int32) -> Void = { _ in
    sigintReceivedDuringInput = true
}

public struct LineEditor {
    public var history: CommandHistory
    public var prompt: String = ""

    public init(history: CommandHistory = CommandHistory()) {
        self.history = history
    }

    public mutating func readCommand() -> String {
        guard isatty(STDIN_FILENO) != 0 else {
            return readLine() ?? ""
        }

        let previousSigintHandler = signal(SIGINT, sigintHandler)
        defer {
            signal(SIGINT, previousSigintHandler)
        }

        guard let orig = enableRawMode() else {
            signal(SIGINT, previousSigintHandler)
            return readLine() ?? ""
        }

        defer {
            restoreRawMode(orig)
        }

        var buffer = ""
        while true {
            if sigintReceivedDuringInput {
                sigintReceivedDuringInput = false
                return ""
            }

            var byte: UInt8 = 0
            let count = read(STDIN_FILENO, &byte, 1)
            if count < 0 {
                if errno == EINTR {
                    sigintReceivedDuringInput = false
                    return ""
                }
                return ""
            }
            if count == 0 {
                return ""
            }

            if byte == 0x1B {
                var next: UInt8 = 0
                guard read(STDIN_FILENO, &next, 1) == 1 else { continue }
                guard next == 0x5B else { continue }
                var finalByte: UInt8 = 0
                guard read(STDIN_FILENO, &finalByte, 1) == 1 else { continue }
                if finalByte == 0x41 {
                    let cmd = history.moveUp()
                    buffer = cmd
                    updateDisplay(buffer)
                } else if finalByte == 0x42 {
                    let cmd = history.moveDown()
                    buffer = cmd
                    updateDisplay(buffer)
                }
                continue
            }

            if byte == 0x0A || byte == 0x0D {
                FileHandle.standardOutput.write(Data("\r\n".utf8))
                try? FileHandle.standardOutput.synchronize()
                return buffer
            }

            if byte == 0x7F {
                if !buffer.isEmpty {
                    buffer.removeLast()
                    FileHandle.standardOutput.write(Data([0x08, 0x20, 0x08]))
                    try? FileHandle.standardOutput.synchronize()
                }
                continue
            }

            if byte >= 0x20 && byte < 0x7F {
                buffer.append(Character(UnicodeScalar(byte)))
                FileHandle.standardOutput.write(Data([byte]))
                try? FileHandle.standardOutput.synchronize()
                continue
            }
        }
    }

    private func enableRawMode() -> termios? {
        var term = termios()
        guard tcgetattr(STDIN_FILENO, &term) == 0 else {
            return nil
        }
        let original = term

        term.c_iflag &= ~tcflag_t(IXON | ICRNL | INLCR | IGNCR)
        term.c_lflag &= ~tcflag_t(ECHO | ICANON | ISIG | IEXTEN)
        term.c_oflag &= ~tcflag_t(OPOST)
        term.c_cc.6 = 1
        term.c_cc.5 = 0

        guard tcsetattr(STDIN_FILENO, TCSAFLUSH, &term) == 0 else {
            return nil
        }

        return original
    }

    private func restoreRawMode(_ original: termios) {
        var term = original
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &term)
    }

    private func updateDisplay(_ buffer: String) {
        let line = prompt + buffer
        let spaces = String(repeating: " ", count: line.count)
        FileHandle.standardOutput.write(Data("\r\(spaces)\r\(line)".utf8))
        try? FileHandle.standardOutput.synchronize()
    }
}
