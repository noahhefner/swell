import Testing
@testable import swell

struct PromptRendererTests {
    @Test("Default prompt without config file")
    func testDefaultPrompt() {
        let renderer = PromptRenderer()
        let env = ShellEnvironment()
        let prompt = renderer.render(env: env)
        #expect(prompt == "swell $ ")
    }
}
