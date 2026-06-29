import Testing
import Foundation
@testable import swell

@Suite("History Builtin Integration Tests")
struct HistoryIntegrationTests {
    @Test("History builtin outputs numbered entries")
    func testHistoryOutput() {
        var history = CommandHistory()
        history.add("ls")
        history.add("pwd")
        history.add("echo done")
        let output = History.execute(history: history.entries)
        #expect(output.contains("   1  ls"))
        #expect(output.contains("   2  pwd"))
        #expect(output.contains("   3  echo done"))
    }

    @Test("History builtin returns empty output for empty history")
    func testEmptyHistory() {
        let history = CommandHistory()
        let output = History.execute(history: history.entries)
        #expect(output.isEmpty)
    }

    @Test("History builtin output format: numbers right-aligned with 4-char width")
    func testOutputFormat() {
        var history = CommandHistory()
        for i in 1...10 {
            history.add("cmd \(i)")
        }
        let output = History.execute(history: history.entries)
        let lines = output.split(separator: "\n")
        #expect(lines.count == 10)
        #expect(lines[0].hasPrefix("   1  cmd 1"))
        #expect(lines[9].hasPrefix("  10  cmd 10"))
    }
}
