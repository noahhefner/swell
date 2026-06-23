public enum TokenKind: Equatable, Sendable {
    case command(String)
    case pipe
    case redirectOut
    case redirectAppend
    case redirectErr
    case redirectErrAppend
    case filename(String)
}

public struct Token: Sendable {
    public let kind: TokenKind

    public init(_ kind: TokenKind) {
        self.kind = kind
    }
}
