# Input Contract: Line Editor

## Purpose

Defines the interface between the REPL and the Line Editor component for reading user input with history navigation support.

## API

### `LineEditor.readCommand() -> String`

Reads a single command line from the user.

**Behavior**:
- If stdin is a TTY: enters raw mode, reads bytes one at a time, detecting arrow key escape sequences for history navigation, and returns the line when Enter is pressed
- If stdin is not a TTY: delegates to `readLine()` (standard library), returning the line or empty string on EOF

**Arrow key handling**:
- Up arrow (`\x1B[A`): loads previous history entry onto the input line
- Down arrow (`\x1B[B`): loads next history entry, or clears line at end of history

**Return value**: The complete command string (without trailing newline), or empty string on EOF.

### `CommandHistory`

```swift
struct CommandHistory {
    /// All commands entered this session, newest appended
    var entries: [String]

    /// Cursor index into entries, or nil for "new input" mode
    var cursor: Int?

    /// Append a command to history and reset cursor
    mutating func add(_ command: String)

    /// Move cursor one step toward older entries. Returns the command at the new position, or empty string if no older entry exists.
    mutating func moveUp() -> String

    /// Move cursor one step toward newer entries. Returns the command at the new position, or empty string if past the newest entry.
    mutating func moveDown() -> String

    /// The command currently pointed to by the cursor, or empty string if cursor is nil
    func current() -> String
}
```

## Terminal State Contract

The Line Editor MUST:
1. Save current terminal attributes on entry to raw mode
2. Restore original terminal attributes when `readCommand()` returns (via `defer`)
3. Restore terminal attributes on SIGINT and SIGTERM (via existing signal handler infrastructure)
4. Check `isatty(STDIN_FILENO)` before entering raw mode

## Escape Sequence Format

| Input | Action |
|-------|--------|
| `\x1B[A` | `history.moveUp()` — display previous command |
| `\x1B[B` | `history.moveDown()` — display next command |
| `\r` | Ignored (carriage return) |
| `\n` | Return current input buffer |
| Printable ASCII | Append to input buffer |
| `\x7F` (DEL) | Backspace — remove last character from input buffer |

## Error Handling

- If `tcgetattr`/`tcsetattr` fails: fall back to `readLine()` mode
- If `read()` fails: print error to stderr and return empty string
- All errors are non-fatal; the REPL continues running
