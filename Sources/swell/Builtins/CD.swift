import Foundation

public struct CdCommand: Sendable {
    public static func execute(path: String, environment: inout ShellEnvironment) -> CommandResult {
        let target = path == "~" ? (environment.variables["HOME"] ?? "/root") : path
        guard environment.changeDirectory(target) else {
            return .failure(error: "cd: \(target): No such directory", exitCode: 1)
        }
        return .success(output: "")
    }
}
