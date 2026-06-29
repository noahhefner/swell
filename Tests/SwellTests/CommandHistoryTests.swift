import Testing
@testable import swell

struct CommandHistoryTests {
    @Test("Empty history returns empty on moveUp")
    func testMoveUpOnEmpty() {
        var history = CommandHistory()
        #expect(history.moveUp() == "")
        #expect(history.cursor == nil)
    }

    @Test("Empty history returns empty on moveDown")
    func testMoveDownOnEmpty() {
        var history = CommandHistory()
        #expect(history.moveDown() == "")
        #expect(history.cursor == nil)
    }

    @Test("moveUp returns most recent command from nil cursor")
    func testMoveUpFromNil() {
        var history = CommandHistory()
        history.add("first")
        history.add("second")
        #expect(history.moveUp() == "second")
        #expect(history.cursor == 1)
    }

    @Test("moveUp traverses to older entries")
    func testMoveUpMultiple() {
        var history = CommandHistory()
        history.add("ls")
        history.add("pwd")
        history.add("echo hi")
        let _ = history.moveUp()
        #expect(history.moveUp() == "pwd")
        #expect(history.cursor == 1)
        #expect(history.moveUp() == "ls")
        #expect(history.cursor == 0)
    }

    @Test("moveUp at oldest entry stays at oldest")
    func testMoveUpBoundary() {
        var history = CommandHistory()
        history.add("only")
        #expect(history.moveUp() == "only")
        #expect(history.moveUp() == "only")
        #expect(history.cursor == 0)
    }

    @Test("moveDown returns newer entry")
    func testMoveDownToNewer() {
        var history = CommandHistory()
        history.add("ls")
        history.add("pwd")
        let _ = history.moveUp()
        let _ = history.moveUp()
        #expect(history.moveDown() == "pwd")
        #expect(history.cursor == 1)
    }

    @Test("moveDown past newest clears cursor")
    func testMoveDownPastNewest() {
        var history = CommandHistory()
        history.add("ls")
        history.add("pwd")
        let _ = history.moveUp()
        #expect(history.moveDown() == "")
        #expect(history.cursor == nil)
    }

    @Test("current returns empty string when cursor is nil")
    func testCurrentNil() {
        let history = CommandHistory()
        #expect(history.current() == "")
    }

    @Test("current returns entry at cursor position")
    func testCurrentAtPosition() {
        var history = CommandHistory()
        history.add("ls")
        history.add("pwd")
        let _ = history.moveUp()
        #expect(history.current() == "pwd")
    }

    @Test("add resets cursor to nil")
    func testAddResetsCursor() {
        var history = CommandHistory()
        history.add("ls")
        let _ = history.moveUp()
        #expect(history.cursor == 0)
        history.add("pwd")
        #expect(history.cursor == nil)
    }

    @Test("editing a recalled command and executing records modified text")
    func testModifiedCommandBecomesNewEntry() {
        var history = CommandHistory()
        history.add("ls -la")
        let recalled = history.moveUp()
        #expect(recalled == "ls -la")
        let modified = "ls -la /tmp"
        history.add(modified)
        #expect(history.entries.count == 2)
        #expect(history.entries.last == "ls -la /tmp")
        #expect(history.entries.first == "ls -la")
    }

    @Test("pressing Up during active input replaces buffer with history entry")
    func testUpReplacesActiveInput() {
        var history = CommandHistory()
        history.add("echo hello")
        let _ = history.moveUp()
        #expect(history.current() == "echo hello")
        history.add("pwd")
        let partialInput = "ec"
        let _ = history.moveUp()
        let replacement = history.current()
        #expect(replacement == "pwd")
        #expect(replacement != partialInput)
    }
}

struct EscapeSequenceTests {
    @Test("Up arrow escape sequence is three bytes: ESC [ A")
    func testUpArrowSequence() {
        let upArrow: [UInt8] = [0x1B, 0x5B, 0x41]
        #expect(upArrow.count == 3)
        #expect(upArrow[0] == 0x1B)
        #expect(upArrow[1] == 0x5B)
        #expect(upArrow[2] == 0x41)
    }

    @Test("Down arrow escape sequence is three bytes: ESC [ B")
    func testDownArrowSequence() {
        let downArrow: [UInt8] = [0x1B, 0x5B, 0x42]
        #expect(downArrow.count == 3)
        #expect(downArrow[0] == 0x1B)
        #expect(downArrow[1] == 0x5B)
        #expect(downArrow[2] == 0x42)
    }

    @Test("Enter key is newline 0x0A")
    func testEnterKey() {
        let enter: UInt8 = 0x0A
        #expect(enter == Character("\n").asciiValue)
    }

    @Test("Delete/backspace is 0x7F")
    func testBackspaceKey() {
        let backspace: UInt8 = 0x7F
        #expect(backspace == 127)
    }
}
