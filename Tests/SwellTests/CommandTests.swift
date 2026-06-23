import Testing
@testable import swell

struct CommandTests {
    @Test("Parser tokenizes simple command")
    func testParseSimpleCommand() throws {
        let parser = Parser()
        let pipeline = try parser.parse("echo hello")
        #expect(pipeline.commands.count == 1)
        #expect(pipeline.commands[0].name == "echo")
        #expect(pipeline.commands[0].arguments == ["hello"])
    }

    @Test("Parser tokenizes command with multiple arguments")
    func testParseMultipleArgs() throws {
        let parser = Parser()
        let pipeline = try parser.parse("ls -la /tmp")
        #expect(pipeline.commands.count == 1)
        #expect(pipeline.commands[0].name == "ls")
        #expect(pipeline.commands[0].arguments == ["-la", "/tmp"])
    }

    @Test("Parser throws on empty input")
    func testParseEmptyInput() {
        let parser = Parser()
        #expect(throws: ParseError.emptyInput) {
            try parser.parse("")
        }
        #expect(throws: ParseError.emptyInput) {
            try parser.parse("   ")
        }
    }

    @Test("Parser handles quoted strings")
    func testParseQuotedArgs() throws {
        let parser = Parser()
        let pipeline = try parser.parse("echo 'hello world' \"foo bar\"")
        #expect(pipeline.commands[0].arguments == ["hello world", "foo bar"])
    }

    @Test("ShellEnvironment resolves executables via PATH")
    func testResolveExecutable() {
        let env = ShellEnvironment()
        let resolved = env.resolveExecutable("echo")
        #expect(resolved != nil)
        #expect(resolved == "/usr/bin/echo" || resolved == "/bin/echo")
    }

    @Test("ShellEnvironment returns nil for nonexistent command")
    func testResolveNonexistent() {
        let env = ShellEnvironment()
        #expect(env.resolveExecutable("nonexistent_command_xyz") == nil)
    }
}
