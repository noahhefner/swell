import Foundation

public struct Echo: Sendable {
    public static func execute(arguments: [String]) -> CommandResult {
        .success(output: arguments.joined(separator: " "))
    }
}
