import Testing
import Foundation
@testable import swell

@Suite("Redirection Integration Tests")
struct RedirectionIntegrationTests {
    @Test("Redirect stdout to file creates correct content")
    func testStdoutRedirect() throws {
        let tempPath = "/tmp/swell-redirect-\(UUID().uuidString).txt"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        FileManager.default.createFile(atPath: tempPath, contents: nil)
        let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: tempPath))

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/echo")
        process.arguments = ["redirected content"]
        process.standardOutput = fileHandle

        try process.run()
        process.waitUntilExit()
        try fileHandle.close()

        let content = try String(contentsOfFile: tempPath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(content == "redirected content")
    }

    @Test("Redirect stderr to file captures error output")
    func testStderrRedirect() throws {
        let tempPath = "/tmp/swell-err-\(UUID().uuidString).txt"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        FileManager.default.createFile(atPath: tempPath, contents: nil)
        let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: tempPath))

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ls")
        process.arguments = ["/nonexistent_path_xyz"]
        process.standardError = fileHandle
        process.standardOutput = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()
        try fileHandle.close()

        let content = try String(contentsOfFile: tempPath, encoding: .utf8)
        #expect(!content.isEmpty, "Expected error output in stderr redirect file")
    }

    @Test("Unwritable file redirect returns error")
    func testUnwritableRedirect() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/echo")
        process.arguments = ["test"]

        // Try writing to /proc which is not writable
        let invalidURL = URL(fileURLWithPath: "/proc/swell-test-\(UUID().uuidString)")
        #expect(throws: (any Error).self) {
            let handle = try FileHandle(forWritingTo: invalidURL)
            process.standardOutput = handle
        }
    }
}
