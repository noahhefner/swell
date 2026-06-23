import Foundation

public struct ColorConfig: Sendable {
    public let errorPrefix: String
    public let errorSuffix: String
    public let reset: String

    public static let `default` = ColorConfig(
        errorPrefix: "\u{1B}[31m",
        errorSuffix: "\u{1B}[0m",
        reset: "\u{1B}[0m"
    )

    public init(errorPrefix: String, errorSuffix: String, reset: String) {
        self.errorPrefix = errorPrefix
        self.errorSuffix = errorSuffix
        self.reset = reset
    }
}
