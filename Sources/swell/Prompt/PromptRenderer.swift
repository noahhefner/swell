import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public struct PromptRenderer: Sendable {
    private var config: PromptConfig

    public init(config: PromptConfig = PromptConfig.load()) {
        self.config = config
    }

    public mutating func reload() {
        config = PromptConfig.load()
    }

    public func render(env: ShellEnvironment, colorState: ColorState = .disabled) -> String {
        let template = config.template
        guard !template.isEmpty else { return "$ " }

        var result = ""
        var i = template.startIndex

        while i < template.endIndex {
            if template[i] == "\\" {
                let next = template.index(after: i)
                guard next < template.endIndex else {
                    result.append(template[i])
                    break
                }
                let ctx = RenderContext(
                    template: template, index: i, next: next,
                    env: env, colorState: colorState
                )
                let advanced = renderEscape(template[next], context: ctx)
                result.append(advanced.value)
                i = advanced.newIndex
            } else {
                result.append(template[i])
                i = template.index(after: i)
            }
        }
        return result
    }

    private struct RenderContext {
        let template: String
        let index: String.Index
        let next: String.Index
        let env: ShellEnvironment
        let colorState: ColorState
    }

    private func renderEscape(
        _ char: Character,
        context: RenderContext
    ) -> (value: String, newIndex: String.Index) {
        let afterNext = context.template.index(after: context.next)
        switch char {
        case "e":
            let rendered = renderAnsiEscape(
                template: context.template, index: context.index,
                next: context.next, colorState: context.colorState
            )
            return rendered
        case "u":
            let user = ProcessInfo.processInfo.environment["USER"] ?? "unknown"
            return (user, afterNext)
        case "h":
            return (hostname(), afterNext)
        case "w":
            return (context.env.currentDirectory, afterNext)
        case "W":
            let last = URL(fileURLWithPath: context.env.currentDirectory).lastPathComponent
            return (last, afterNext)
        case "t":
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return (formatter.string(from: Date()), afterNext)
        case "$":
            let uid = ProcessInfo.processInfo.environment["UID"] ?? ""
            return (uid == "0" ? "#" : "$", afterNext)
        default:
            return renderDefaultEscape(char: char, context: context, afterNext: afterNext)
        }
    }

    private func renderDefaultEscape(
        char: Character,
        context: RenderContext,
        afterNext: String.Index
    ) -> (value: String, newIndex: String.Index) {
        if char == "n" { return ("\n", afterNext) }
        if char == "\\" { return ("\\", afterNext) }
        if char == "[" { return ("", afterNext) }
        if char == "]" { return ("", afterNext) }
        return (String(context.template[context.index]) + String(char), afterNext)
    }

    private func renderAnsiEscape(
        template: String,
        index: String.Index,
        next: String.Index,
        colorState: ColorState
    ) -> (value: String, newIndex: String.Index) {
        guard colorState.isEnabled else {
            if let end = template[index...].firstIndex(of: "m") {
                return ("", template.index(after: end))
            }
            return ("", template.index(after: next))
        }
        return ("\u{1B}", template.index(after: next))
    }

    private func hostname() -> String {
        var name = [CChar](repeating: 0, count: 256)
        if gethostname(&name, name.count) == 0 {
            return name.withUnsafeBufferPointer { buf in
                guard let base = buf.baseAddress else { return "unknown" }
                return String(validatingCString: base)?
                    .components(separatedBy: ".").first ?? "unknown"
            }
        }
        return "unknown"
    }
}
