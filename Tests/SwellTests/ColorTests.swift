import Testing
import Foundation
@testable import swell

@Suite("ColorResolver Tests")
struct ColorResolverTests {
    @Test("NO_COLOR set disables color")
    func testColorResolverNoColor() {
        let env = ["NO_COLOR": "1"]
        let resolver = ColorResolver(env: env)
        let state = resolver.resolve()
        #expect(!state.isEnabled)
    }

    @Test("NO_COLOR overrides CLICOLOR_FORCE")
    func testColorResolverNoColorWins() {
        let env = ["NO_COLOR": "1", "CLICOLOR_FORCE": "1"]
        let resolver = ColorResolver(env: env)
        let state = resolver.resolve()
        #expect(!state.isEnabled)
    }

    @Test("TERM=dumb disables color")
    func testColorResolverTermDisabled() {
        let env = ["TERM": "dumb"]
        let resolver = ColorResolver(env: env)
        let state = resolver.resolve()
        #expect(!state.isEnabled)
    }

    @Test("TERM=xterm-mono disables color")
    func testColorResolverTermMono() {
        let env = ["TERM": "xterm-mono"]
        let resolver = ColorResolver(env: env)
        let state = resolver.resolve()
        #expect(!state.isEnabled)
    }

    @Test("TERM=vt100 disables color")
    func testColorResolverTermVt100() {
        let env = ["TERM": "vt100"]
        let resolver = ColorResolver(env: env)
        let state = resolver.resolve()
        #expect(!state.isEnabled)
    }

    @Test("CLICOLOR=0 disables color")
    func testColorResolverClicolor0() {
        let env = ["CLICOLOR": "0"]
        let resolver = ColorResolver(env: env)
        let state = resolver.resolve()
        #expect(!state.isEnabled)
    }

    @Test("CLICOLOR_FORCE=1 enables color")
    func testColorResolverClicolorForce() {
        let env = ["CLICOLOR_FORCE": "1"]
        let resolver = ColorResolver(env: env)
        let state = resolver.resolve(stdoutIsTTY: false, stderrIsTTY: false)
        #expect(state.isEnabled)
    }

    @Test("Default env with TTY enables color")
    func testColorResolverDefault() {
        let resolver = ColorResolver(env: [:])
        let state = resolver.resolve(stdoutIsTTY: true, stderrIsTTY: true)
        #expect(state.isEnabled)
    }

    @Test("Non-TTY disables color without CLICOLOR_FORCE")
    func testColorResolverTtyAutoDisable() {
        let resolver = ColorResolver(env: [:])
        let state = resolver.resolve(stdoutIsTTY: false, stderrIsTTY: false)
        #expect(!state.isEnabled)
    }

    @Test("Prompt color escape renders ANSI when enabled")
    func testPromptColorEscapeEnabled() {
        let config = PromptConfig(template: "\\[\\e[31m\\]dir\\[\\e[0m\\]$ ")
        let renderer = PromptRenderer(config: config)
        let env = ShellEnvironment()
        let prompt = renderer.render(env: env, colorState: .enabled)
        #expect(prompt == "\u{1B}[31mdir\u{1B}[0m$ ")
    }

    @Test("Prompt color escape renders plain when disabled")
    func testPromptColorEscapeDisabled() {
        let config = PromptConfig(template: "\\[\\e[31m\\]dir\\[\\e[0m\\]$ ")
        let renderer = PromptRenderer(config: config)
        let env = ShellEnvironment()
        let prompt = renderer.render(env: env, colorState: .disabled)
        #expect(prompt == "dir$ ")
    }
}
