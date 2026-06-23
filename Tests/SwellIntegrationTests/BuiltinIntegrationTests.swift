import Testing
import Foundation
@testable import swell

@Suite("Builtin Integration Tests")
struct BuiltinIntegrationTests {
    @Test("ShellEnvironment cd and pwd work together")
    func testCdAndPwd() {
        var env = ShellEnvironment()
        let originalDir = env.currentDirectory

        let cdResult = env.changeDirectory("/tmp")
        #expect(cdResult == true)
        #expect(env.currentDirectory == "/tmp")

        // Change back
        _ = env.changeDirectory(originalDir)
        #expect(env.currentDirectory == originalDir)
    }

    @Test("ShellEnvironment export affects environment")
    func testExportAffectsEnv() {
        var env = ShellEnvironment()
        env.setVariable("SWELL_TEST_VAR", value: "test_export_value")
        let exported = env.exportedEnvironment()
        #expect(exported["SWELL_TEST_VAR"] == "test_export_value")
    }

    @Test("ShellEnvironment inherits system PATH")
    func testInheritsPath() {
        let env = ShellEnvironment()
        let path = env.pathEntries()
        #expect(!path.isEmpty, "PATH should have entries inherited from system")
    }
}
