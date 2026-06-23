import Foundation

public struct PromptConfig: Sendable {
    public var template: String

    public init(template: String) {
        self.template = template
    }

    public static func load() -> PromptConfig {
        let configPath = configFilePath()
        if let data = try? Data(contentsOf: configPath),
           let template = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !template.isEmpty {
            return PromptConfig(template: template)
        }
        return PromptConfig(template: "swell $ ")
    }

    private static func configFilePath() -> URL {
        if let xdgHome = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] {
            return URL(fileURLWithPath: xdgHome)
                .appendingPathComponent("swell")
                .appendingPathComponent("prompt")
        }
        return URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent(".config")
            .appendingPathComponent("swell")
            .appendingPathComponent("prompt")
    }
}
