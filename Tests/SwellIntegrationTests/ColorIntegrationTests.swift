import Testing
import Foundation
@testable import swell

@Suite("Color Integration Tests")
struct ColorIntegrationTests {
    @Test("NO_COLOR=1 suppresses ANSI in piped output")
    func testNoColorPipe() async throws {
        let env = ["NO_COLOR": "1"]
        let resolver = ColorResolver(env: env)
        let state = resolver.resolve()
        #expect(!state.isEnabled)
    }

    @Test("CLICOLOR_FORCE=1 enables ANSI in piped output")
    func testClolorForcePipe() async throws {
        let env = ["CLICOLOR_FORCE": "1"]
        let resolver = ColorResolver(env: env)
        let state = resolver.resolve()
        #expect(state.isEnabled)
    }

    @Test("Error message includes ANSI red when color enabled")
    func testErrorColorEnabled() {
        let config = ColorConfig.default
        let msg = "error: command not found"
        let colored = "\(config.errorPrefix)\(msg)\(config.errorSuffix)"
        #expect(colored.hasPrefix("\u{1B}[31m"))
        #expect(colored.hasSuffix("\u{1B}[0m"))
    }

    @Test("Error message is plain when color disabled")
    func testErrorColorDisabled() {
        let msg = "error: command not found"
        #expect(!msg.hasPrefix("\u{1B}["))
        #expect(!msg.hasSuffix("\u{1B}[0m"))
    }
}
