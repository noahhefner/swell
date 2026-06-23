import Testing
import Foundation
@testable import swell

@Suite("Prompt Integration Tests")
struct PromptIntegrationTests {
    @Test("PromptConfig loads default template when no config file exists")
    func testDefaultPromptConfig() {
        let config = PromptConfig.load()
        #expect(config.template == "swell $ ")
    }

    @Test("PromptRenderer renders default prompt")
    func testDefaultRender() {
        let renderer = PromptRenderer()
        let env = ShellEnvironment()
        let prompt = renderer.render(env: env)
        #expect(prompt == "swell $ ")
    }

    @Test("PromptRenderer expands username escape")
    func testUserEscape() {
        let config = PromptConfig(template: "\\u> ")
        let renderer = PromptRenderer(config: config)
        let env = ShellEnvironment()
        let prompt = renderer.render(env: env)
        let user = ProcessInfo.processInfo.environment["USER"] ?? "unknown"
        #expect(prompt == "\(user)> ")
    }

    @Test("PromptRenderer expands directory escape")
    func testDirectoryEscape() {
        let config = PromptConfig(template: "\\w$ ")
        let renderer = PromptRenderer(config: config)
        let env = ShellEnvironment()
        let prompt = renderer.render(env: env)
        #expect(prompt.hasPrefix("/"))
        #expect(prompt.hasSuffix("$ "))
    }

    @Test("PromptRenderer expands literal backslash")
    func testBackslashEscape() {
        let config = PromptConfig(template: "\\\\> ")
        let renderer = PromptRenderer(config: config)
        let env = ShellEnvironment()
        let prompt = renderer.render(env: env)
        #expect(prompt == "\\> ")
    }
}
