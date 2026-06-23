import Foundation

public struct Exit: Sendable {
    public static func execute() -> CommandResult {
        .exit
    }
}
