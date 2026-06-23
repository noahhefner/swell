import Foundation

public struct ShellEnvironment: Sendable {
    public private(set) var variables: [String: String]
    public private(set) var currentDirectory: String

    public init() {
        self.variables = ProcessInfo.processInfo.environment
        self.currentDirectory = FileManager.default.currentDirectoryPath
        self.variables["PWD"] = currentDirectory
    }

    public func pathEntries() -> [String] {
        guard let path = variables["PATH"] else { return [] }
        return path.split(separator: ":").map(String.init)
    }

    public func resolveExecutable(_ name: String) -> String? {
        if name.hasPrefix("/") || name.hasPrefix(".") {
            return FileManager.default.isExecutableFile(atPath: name) ? name : nil
        }
        for dir in pathEntries() {
            let full = (dir as NSString).appendingPathComponent(name)
            if FileManager.default.isExecutableFile(atPath: full) {
                return full
            }
        }
        return nil
    }

    public mutating func setVariable(_ key: String, value: String) {
        variables[key] = value
    }

    public mutating func changeDirectory(_ path: String) -> Bool {
        guard FileManager.default.changeCurrentDirectoryPath(path) else { return false }
        currentDirectory = FileManager.default.currentDirectoryPath
        variables["PWD"] = currentDirectory
        return true
    }

    public func exportedEnvironment() -> [String: String] {
        variables
    }
}
