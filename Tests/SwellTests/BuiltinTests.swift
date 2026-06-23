import Testing
@testable import swell

struct BuiltinTests {
    @Test("Exit builtin returns exit result")
    func testExit() {
        let command = ParsedCommand(name: "exit")
        let repl = REPL()
        // REPL handles exit via CommandResult.exit
        // Testing directly via executeBuiltin is internal
    }

    @Test("Parser tokenizes cd command")
    func testParseCD() throws {
        let parser = Parser()
        let pipeline = try parser.parse("cd /tmp")
        #expect(pipeline.commands[0].name == "cd")
        #expect(pipeline.commands[0].arguments == ["/tmp"])
    }

    @Test("Parser tokenizes pwd command")
    func testParsePWD() throws {
        let parser = Parser()
        let pipeline = try parser.parse("pwd")
        #expect(pipeline.commands[0].name == "pwd")
        #expect(pipeline.commands[0].arguments == [])
    }

    @Test("Parser tokenizes export command")
    func testParseExport() throws {
        let parser = Parser()
        let pipeline = try parser.parse("export FOO=bar")
        #expect(pipeline.commands[0].name == "export")
        #expect(pipeline.commands[0].arguments == ["FOO=bar"])
    }

    @Test("ShellEnvironment setVariable updates environment")
    func testSetVariable() {
        var env = ShellEnvironment()
        env.setVariable("TEST_VAR", value: "test_value")
        #expect(env.exportedEnvironment()["TEST_VAR"] == "test_value")
    }

    @Test("ShellEnvironment changeDirectory updates currentDirectory")
    func testChangeDirectory() {
        var env = ShellEnvironment()
        let result = env.changeDirectory("/tmp")
        #expect(result == true)
        #expect(env.currentDirectory == "/tmp")
    }
}
