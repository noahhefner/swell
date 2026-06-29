import Foundation

#if os(Linux)
import Glibc
#else
import Darwin
#endif

public enum SignalHandler {
    private static nonisolated(unsafe) var savedTermios: termios?
    private static nonisolated(unsafe) var termiosSaved = false

    public static func ignore(_ signal: Int32) {
        Foundation.signal(signal, SIG_IGN)
    }

    public static func saveTerminalState() {
        guard !termiosSaved else { return }
        var term = termios()
        if tcgetattr(STDIN_FILENO, &term) == 0 {
            savedTermios = term
            termiosSaved = true
        }
    }

    public static func restoreTerminalState() {
        guard termiosSaved, var term = savedTermios else { return }
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &term)
        termiosSaved = false
        savedTermios = nil
    }

    public static func restoreOnSignal(_ signal: Int32) {
        restoreTerminalState()
        Foundation.signal(signal, SIG_DFL)
        kill(getpid(), signal)
    }
}
