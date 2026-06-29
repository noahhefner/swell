import Foundation

public struct History: Sendable {
    public static func execute(history entries: [String]) -> String {
        guard !entries.isEmpty else { return "" }
        return entries.enumerated().map { index, command in
            let padded = String(format: "%4d", index + 1)
            return "\(padded)  \(command)"
        }.joined(separator: "\n")
    }
}
