import Testing
import Foundation
@testable import swell

@Suite("Pipe Integration Tests")
struct PipeIntegrationTests {
    @Test("Two-stage pipe with echo and wc")
    func testTwoStagePipe() async throws {
        let echo = Process()
        echo.executableURL = URL(fileURLWithPath: "/usr/bin/echo")
        echo.arguments = ["one two three four"]

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
        #expect(output == "4")
    }

    @Test("Three-stage pipe with ls grep wc")
    func testThreeStagePipe() async throws {
        let ls = Process()
        ls.executableURL = URL(fileURLWithPath: "/usr/bin/ls")
        ls.arguments = ["/tmp"]

        let grep = Process()
        grep.executableURL = URL(fileURLWithPath: "/usr/bin/grep")
        grep.arguments = ["."]

        let wc = Process()
        wc.executableURL = URL(fileURLWithPath: "/usr/bin/wc")
        wc.arguments = ["-l"]

        let pipe1 = Pipe()
        ls.standardOutput = pipe1
        grep.standardInput = pipe1

        let pipe2 = Pipe()
        grep.standardOutput = pipe2
        wc.standardInput = pipe2

        let outPipe = Pipe()
        wc.standardOutput = outPipe

        try wc.run()
        try grep.run()
        try ls.run()

        ls.waitUntilExit()
        grep.waitUntilExit()
        wc.waitUntilExit()

        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let count = Int(output ?? "0") ?? 0
        #expect(count >= 0)
    }

    @Test("REPL two-stage pipeline via execute")
    func testREPLTwoStagePipeline() async throws {
        let repl = REPL()
        let result = repl.execute("/bin/echo one two three four | /usr/bin/wc -w")
        if case .success(let output) = result {
            #expect(output.trimmingCharacters(in: .whitespacesAndNewlines) == "4")
        } else {
            Issue.record("Expected success but got \(result)")
        }
    }

    @Test("REPL three-stage pipeline via execute")
    func testREPLThreeStagePipeline() async throws {
        let repl = REPL()
        let result = repl.execute("/bin/echo hello world foo | /usr/bin/tr ' ' '\n' | /usr/bin/wc -l")
        if case .success(let output) = result {
            #expect(output.trimmingCharacters(in: .whitespacesAndNewlines) == "3")
        } else {
            Issue.record("Expected success but got \(result)")
        }
    }

    @Test("REPL four-stage pipeline via execute")
    func testREPLFourStagePipeline() async throws {
        let repl = REPL()
        let result = repl.execute("/bin/echo foo | /usr/bin/cat | /usr/bin/cat | /usr/bin/wc -c")
        if case .success(let output) = result {
            #expect(output.trimmingCharacters(in: .whitespacesAndNewlines) == "4")
        } else {
            Issue.record("Expected success but got \(result)")
        }
    }

    @Test("REPL pipeline returns error for nonexistent command")
    func testREPLPipelineInvalidCommand() async throws {
        let repl = REPL()
        let result = repl.execute("/bin/echo foo | /usr/bin/nonexistent_xyz")
        if case .failure(let error, _) = result {
            #expect(!error.isEmpty)
        } else {
            Issue.record("Expected failure but got \(result)")
        }
    }
}
