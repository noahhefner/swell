import Foundation

/// Placeholder for dedicated signal handler utilities.
/// Signal handling is currently managed in REPL.swift via DispatchSource.
public enum SignalHandler {
    public static func ignore(_ signal: Int32) {
        Foundation.signal(signal, SIG_IGN)
    }
}
