import Foundation

public struct CommandHistory {
    public var entries: [String] = []
    public var cursor: Int?

    public init() {}

    public mutating func add(_ command: String) {
        entries.append(command)
        cursor = nil
    }

    @discardableResult
    public mutating func moveUp() -> String {
        guard !entries.isEmpty else { return "" }
        let newIndex: Int
        if let current = cursor {
            newIndex = max(current - 1, 0)
        } else {
            newIndex = entries.count - 1
        }
        cursor = newIndex
        return entries[newIndex]
    }

    @discardableResult
    public mutating func moveDown() -> String {
        guard !entries.isEmpty, let current = cursor else { return "" }
        let newIndex = current + 1
        if newIndex >= entries.count {
            cursor = nil
            return ""
        }
        cursor = newIndex
        return entries[newIndex]
    }

    public func current() -> String {
        guard let cursor else { return "" }
        return entries[cursor]
    }
}
