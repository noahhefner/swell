import Foundation

public struct PWD: Sendable {
    public static func execute(environment: ShellEnvironment) -> CommandResult {
        .success(output: environment.currentDirectory)
    }
}
