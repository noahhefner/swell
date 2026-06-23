import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public struct ColorResolver: Sendable {
    public let colorConfig: ColorConfig
    public let env: [String: String]

    public init(colorConfig: ColorConfig = .default,
                env: [String: String] = ProcessInfo.processInfo.environment) {
        self.colorConfig = colorConfig
        self.env = env
    }

    public func resolve(stdoutIsTTY: Bool? = nil,
                        stderrIsTTY: Bool? = nil) -> ColorState {
        let noColor = env["NO_COLOR"] != nil
        let clicolor = env["CLICOLOR"]
        let clicolorForce = env["CLICOLOR_FORCE"]
        let term = env["TERM"]?.lowercased()

        if noColor { return .disabled }
        if clicolor == "0" { return .disabled }
        if clicolorForce == "1" { return .enabled }

        if let t = term {
            let monoTerms = ["dumb", "xterm-mono", "vt100"]
            if monoTerms.contains(t) { return .disabled }
        }

        let outTTY = stdoutIsTTY ?? (isatty(STDOUT_FILENO) != 0)
        let errTTY = stderrIsTTY ?? (isatty(STDERR_FILENO) != 0)
        if !outTTY && !errTTY { return .disabled }

        return .enabled
    }
}
