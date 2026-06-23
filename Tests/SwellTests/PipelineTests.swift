import Testing
@testable import swell

struct PipelineTests {
    @Test("Parser detects pipe operator")
    func testParsePipe() throws {
        let parser = Parser()
        let pipeline = try parser.parse("echo hello | wc -c")
        #expect(pipeline.commands.count == 2)
        #expect(pipeline.commands[0].name == "echo")
        #expect(pipeline.commands[0].arguments == ["hello"])
        #expect(pipeline.commands[1].name == "wc")
        #expect(pipeline.commands[1].arguments == ["-c"])
    }

    @Test("Parser handles three-stage pipeline")
    func testParseThreeStagePipe() throws {
        let parser = Parser()
        let pipeline = try parser.parse("cat /etc/passwd | grep root | wc -l")
        #expect(pipeline.commands.count == 3)
        #expect(pipeline.commands[0].name == "cat")
        #expect(pipeline.commands[1].name == "grep")
        #expect(pipeline.commands[2].name == "wc")
    }

    @Test("Pipeline with no pipe is single command")
    func testParseNoPipe() throws {
        let parser = Parser()
        let pipeline = try parser.parse("ls -la")
        #expect(pipeline.commands.count == 1)
    }

    @Test("Parser detects redirect operators")
    func testParseRedirect() throws {
        let parser = Parser()
        let pipeline = try parser.parse("echo data > /tmp/out.txt")
        #expect(pipeline.commands.count == 1)
        #expect(pipeline.commands[0].stdoutRedirect != nil)
        let redirect = pipeline.commands[0].stdoutRedirect
        if case .overwrite(let path) = redirect {
            #expect(path == "/tmp/out.txt")
        } else if let redirect {
            Issue.record("Expected overwrite redirect, got \(redirect)")
        }
    }

    @Test("Parser detects append redirect")
    func testParseAppendRedirect() throws {
        let parser = Parser()
        let pipeline = try parser.parse("echo data >> /tmp/out.txt")
        #expect(pipeline.commands.count == 1)
        #expect(pipeline.commands[0].stdoutRedirect != nil)
        let redirect = pipeline.commands[0].stdoutRedirect
        if case .append(let path) = redirect {
            #expect(path == "/tmp/out.txt")
        } else if let redirect {
            Issue.record("Expected append redirect, got \(redirect)")
        }
    }

    @Test("Parser detects stderr redirect")
    func testParseStderrRedirect() throws {
        let parser = Parser()
        let pipeline = try parser.parse("cmd 2> /tmp/err.txt")
        #expect(pipeline.commands.count == 1)
        #expect(pipeline.commands[0].stderrRedirect != nil)
    }

    @Test("Parser detects stderr append redirect")
    func testParseStderrAppendRedirect() throws {
        let parser = Parser()
        let pipeline = try parser.parse("cmd 2>> /tmp/err.txt")
        #expect(pipeline.commands.count == 1)
        #expect(pipeline.commands[0].stderrRedirect != nil)
    }

    @Test("Parser throws on unmatched quote")
    func testUnmatchedQuote() {
        let parser = Parser()
        #expect(throws: ParseError.unmatchedQuote) {
            try parser.parse("echo 'hello")
        }
    }
}
