import Testing
import Foundation
@testable import swell

@Suite("Execution Integration Tests")
struct ExecutionIntegrationTests {
    @Test("Run echo and capture output")
    func testRunEcho() async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/echo")
        process.arguments = ["hello world"]

        let outPipe = Pipe()
        process.standardOutput = outPipe
        try process.run()
        process.waitUntilExit()

        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(output == "hello world")
        #expect(process.terminationStatus == 0)
    }

    @Test("Run nonexistent command returns error")
    func testRunNonexistent() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/nonexistent_xyz123")
        do {
            try process.run()
            process.waitUntilExit()
            #expect(process.terminationStatus != 0)
        } catch {
            #expect(error != nil)
        }
    }

    @Test("Pipeline of echo and wc produces correct count")
    func testEchoWcPipeline() async throws {
        let echo = Process()
        echo.executableURL = URL(fileURLWithPath: "/bin/echo")
        echo.arguments = ["one two three"]

        let wc = Process()
        wc.executableURL = URL(fileURLWithPath: "/usr/bin/wc")
        wc.arguments = ["-w"]

        let pipe = Pipe()
        echo.standardOutput = pipe
        wc.standardInput = pipe

        let outPipe = Pipe()
        wc.standardOutput = outPipe

        try wc.run()
        try echo.run()

        echo.waitUntilExit()
        wc.waitUntilExit()

        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(output == "3")
    }

    @Test("File redirect creates file with correct content")
    func testFileRedirect() throws {
        let tempPath = "/tmp/swell-exec-test-\(UUID().uuidString).txt"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        guard FileManager.default.createFile(atPath: tempPath, contents: nil) else {
            Issue.record("Could not create temp file")
            return
        }
        let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: tempPath))
        defer { try? fileHandle.close() }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/echo")
        process.arguments = ["test data"]
        process.standardOutput = fileHandle

        try process.run()
        process.waitUntilExit()

        let content = try String(contentsOfFile: tempPath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(content == "test data")
    }
}
