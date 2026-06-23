import Foundation

public struct Export: Sendable {
    public static func execute(arguments: [String], environment: inout ShellEnvironment) -> CommandResult {
        guard let arg = arguments.first else {
            return .success(output: "")
        }
        let parts = arg.split(separator: "=", maxSplits: 1).map(String.init)
        if parts.count == 2 {
            environment.setVariable(parts[0], value: parts[1])
        } else {
            environment.setVariable(parts[0], value: "")
        }
        return .success(output: "")
    }
}
