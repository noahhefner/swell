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

        let content = try String(contentsOfFile: tempPath, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
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

    // MARK: - REPL-level redirect tests (via shell parser + executor)

    @Test("REPL stdout overwrite redirect via > creates file")
    func testStdoutOverwriteRedirect() throws {
        let tempPath = "/tmp/swell-repl-redirect-\(UUID().uuidString).txt"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let repl = REPL()
        let result = repl.execute("/bin/echo hello world > \(tempPath)")
        if case .success = result {
            let content = try String(contentsOfFile: tempPath, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            #expect(content == "hello world")
        } else {
            Issue.record("Expected success but got \(result)")
        }
    }

    @Test("REPL stdout append redirect via >> appends to file")
    func testStdoutAppendRedirect() throws {
        let tempPath = "/tmp/swell-repl-append-\(UUID().uuidString).txt"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let repl = REPL()
        let r1 = repl.execute("/bin/echo line1 > \(tempPath)")
        if case .exit = r1 { Issue.record("First command should not exit") }

        let r2 = repl.execute("/bin/echo line2 >> \(tempPath)")
        if case .exit = r2 { Issue.record("Second command should not exit") }

        let content = try String(contentsOfFile: tempPath, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(content == "line1\nline2" || content == "line1\nline2\n")
    }

    @Test("REPL stderr overwrite redirect via 2> captures stderr")
    func testStderrOverwriteRedirect() throws {
        let tempPath = "/tmp/swell-repl-err-\(UUID().uuidString).txt"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let repl = REPL()
        let result = repl.execute("/bin/ls /nonexistent_path_xyz 2> \(tempPath)")
        if case .failure = result {
            let content = try String(contentsOfFile: tempPath, encoding: .utf8)
            #expect(!content.isEmpty, "Expected error output in stderr redirect file")
        } else {
            Issue.record("Expected failure but got \(result)")
        }
    }

    @Test("REPL stderr append redirect via 2>> appends stderr")
    func testStderrAppendRedirect() throws {
        let tempPath = "/tmp/swell-repl-err-append-\(UUID().uuidString).txt"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let repl = REPL()
        let r1 = repl.execute("/bin/ls /nonexistent_1 2> \(tempPath)")
        let r2 = repl.execute("/bin/ls /nonexistent_2 2>> \(tempPath)")

        if case .exit = r1 { Issue.record("First command should not exit") }
        if case .exit = r2 { Issue.record("Second command should not exit") }

        let content = try String(contentsOfFile: tempPath, encoding: .utf8)
        #expect(!content.isEmpty, "Expected error output in stderr redirect file")
        // Content should have two error lines (or one multi-line)
        let lines = content.split(separator: "\n")
        #expect(lines.count >= 1)
    }

    @Test("REPL both stdout and stderr redirect in same command")
    func testBothStdoutAndStderrRedirect() throws {
        let outPath = "/tmp/swell-repl-both-out-\(UUID().uuidString).txt"
        let errPath = "/tmp/swell-repl-both-err-\(UUID().uuidString).txt"
        defer {
            try? FileManager.default.removeItem(atPath: outPath)
            try? FileManager.default.removeItem(atPath: errPath)
        }

        let repl = REPL()
        // /bin/ls /tmp succeeds on stdout, no stderr
        let result = repl.execute("/bin/ls /tmp 2> \(errPath) > \(outPath)")
        if case .success = result {
            let outContent = try String(contentsOfFile: outPath, encoding: .utf8)
            #expect(!outContent.isEmpty, "Expected stdout output in redirect file")
            let errContent = try? String(contentsOfFile: errPath, encoding: .utf8)
            #expect(errContent == nil || errContent?.isEmpty == true || errContent == "\n",
                    "Expected no stderr output for /bin/ls /tmp")
        } else {
            Issue.record("Expected success but got \(result)")
        }
    }

    @Test("REPL pipeline with redirect writes filtered output")
    func testPipelineWithRedirect() throws {
        let tempPath = "/tmp/swell-repl-pipe-\(UUID().uuidString).txt"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let repl = REPL()
        let result = repl.execute("/bin/ls /tmp | /usr/bin/grep -v nonexistent > \(tempPath)")
        if case .success = result {
            let content = try String(contentsOfFile: tempPath, encoding: .utf8)
            #expect(!content.isEmpty, "Expected piped output in redirect file")
        } else {
            Issue.record("Expected success but got \(result)")
        }
    }

    @Test("REPL redirect to unwritable path returns error")
    func testRedirectUnwritablePath() throws {
        let repl = REPL()
        // /proc is not writable by normal users
        let result = repl.execute("/bin/echo test > /proc/swell-test-\(UUID().uuidString)")
        if case .failure(let error, let code) = result {
            #expect(code == 1)
            #expect(!error.isEmpty, "Expected error message for unwritable path")
        } else {
            Issue.record("Expected failure for unwritable path but got \(result)")
        }
    }

    @Test("REPL external command stdout redirect with full path")
    func testExternalCommandStdoutRedirect() throws {
        let tempPath = "/tmp/swell-repl-ext-\(UUID().uuidString).txt"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let repl = REPL()
        let result = repl.execute("/bin/echo external test > \(tempPath)")
        if case .success = result {
            let content = try String(contentsOfFile: tempPath, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            #expect(content == "external test")
        } else {
            Issue.record("Expected success but got \(result)")
        }
    }

    @Test("REPL stdout redirect creates new file when target does not exist")
    func testStdoutRedirectCreatesNewFile() throws {
        let tempPath = "/tmp/swell-repl-newfile-\(UUID().uuidString).txt"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        // File should NOT exist yet
        #expect(!FileManager.default.fileExists(atPath: tempPath))

        let repl = REPL()
        let result = repl.execute("/bin/echo new file content > \(tempPath)")
        if case .success = result {
            #expect(FileManager.default.fileExists(atPath: tempPath),
                    "Redirect should create the target file")
            let content = try String(contentsOfFile: tempPath, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            #expect(content == "new file content")
        } else {
            Issue.record("Expected success but got \(result)")
        }
    }

    @Test("REPL redirect to /dev/null succeeds silently")
    func testRedirectToDevNull() throws {
        let repl = REPL()
        let result = repl.execute("/bin/echo silent > /dev/null")
        if case .success(let output) = result {
            #expect(output.isEmpty || output == "\n")
        } else {
            Issue.record("Expected success but got \(result)")
        }
    }

    @Test("REPL redirect to a directory returns error")
    func testRedirectToDirectory() throws {
        let repl = REPL()
        // /tmp is a directory, writing to it should fail
        let result = repl.execute("/bin/echo test > /tmp")
        if case .failure(let error, let code) = result {
            #expect(code == 1)
            #expect(!error.isEmpty, "Expected error message for directory redirect")
        } else {
            Issue.record("Expected failure for directory redirect but got \(result)")
        }
    }
}
