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
                switch template[next] {
                case "[":
                    i = template.index(after: next)
                case "]":
                    i = template.index(after: next)
                case "e":
                    guard colorState.isEnabled else {
                        let start = i
                        if let end = template[i...].firstIndex(of: "m") {
                            i = template.index(after: end)
                        } else {
                            i = template.index(after: next)
                        }
                        continue
                    }
                    result.append("\u{1B}")
                    i = template.index(after: next)
                case "u":
                    result.append(ProcessInfo.processInfo.environment["USER"] ?? "unknown")
                    i = template.index(after: next)
                case "h":
                    result.append(hostname())
                    i = template.index(after: next)
                case "w":
                    result.append(env.currentDirectory)
                    i = template.index(after: next)
                case "W":
                    result.append(URL(fileURLWithPath: env.currentDirectory).lastPathComponent)
                    i = template.index(after: next)
                case "t":
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm:ss"
                    result.append(formatter.string(from: Date()))
                    i = template.index(after: next)
                case "$":
                    let uid = ProcessInfo.processInfo.environment["UID"] ?? ""
                    result.append(uid == "0" ? "#" : "$")
                    i = template.index(after: next)
                case "n":
                    result.append("\n")
                    i = template.index(after: next)
                case "\\":
                    result.append("\\")
                    i = template.index(after: next)
                default:
                    result.append(template[i])
                    result.append(template[next])
                    i = template.index(after: next)
                }
            } else {
                result.append(template[i])
                i = template.index(after: i)
            }
        }
        return result
    }

    private func hostname() -> String {
        var name = [CChar](repeating: 0, count: 256)
        if gethostname(&name, name.count) == 0 {
            return name.withUnsafeBufferPointer { buf in
                String(validatingCString: buf.baseAddress!)?
                    .components(separatedBy: ".").first ?? "unknown"
            }
        }
        return "unknown"
    }
}
