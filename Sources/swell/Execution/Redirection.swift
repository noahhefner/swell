import Foundation

public struct Redirection: Sendable {
    @discardableResult
    public static func openForOverwrite(_ path: String) throws -> FileHandle {
        let url = URL(fileURLWithPath: path)
        _ = FileManager.default.createFile(atPath: path, contents: nil)
        return try FileHandle(forWritingTo: url)
    }

    @discardableResult
    public static func openForAppend(_ path: String) throws -> FileHandle {
        let url = URL(fileURLWithPath: path)
        if !FileManager.default.fileExists(atPath: path) {
            _ = FileManager.default.createFile(atPath: path, contents: nil)
        }
        let handle = try FileHandle(forWritingTo: url)
        try handle.seekToEnd()
        return handle
    }
}
