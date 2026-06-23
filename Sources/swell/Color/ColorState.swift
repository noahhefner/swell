import Foundation

public struct ColorState: Sendable {
    public let isEnabled: Bool

    public init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    public static let enabled = ColorState(isEnabled: true)
    public static let disabled = ColorState(isEnabled: false)

    public func apply<S: StringProtocol>(_ string: S) -> String {
        isEnabled ? String(string) : stripAnsi(String(string))
    }

    private func stripAnsi(_ s: String) -> String {
        s.replacingOccurrences(of: "\u{1B}[^a-zA-Z]*[a-zA-Z]", with: "", options: .regularExpression)
    }
}

extension ColorState: CustomStringConvertible {
    public var description: String {
        isEnabled ? "color enabled" : "color disabled"
    }
}
