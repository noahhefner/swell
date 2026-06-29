# Data Model: Shell Command History

## Entities

### CommandHistory

An ordered collection of non-empty commands executed during the current shell session, with a navigation cursor for browsing.

**Fields**:
| Field       | Type       | Description |
|-------------|------------|-------------|
| `entries`   | `[String]` | Ordered list of commands, oldest first |
| `cursor`    | `Int?`     | Current navigation position (nil = "new input" mode, otherwise index into `entries`) |

**Validation Rules**:
- `entries` must not contain empty or whitespace-only strings
- `cursor` must be nil or in `entries.indices`
- `cursor` moves up (decreases) on Up arrow, down (increases) on Down arrow
- At oldest entry, Up arrow leaves cursor at oldest entry (no wrap)
- Past newest entry, Down arrow sets cursor to nil (new input mode)

**State Transitions**:
- `add(_:)` — appends a command to `entries`, resets `cursor` to nil
- `moveUp()` — moves cursor to previous entry (or stays at oldest)
- `moveDown()` — moves cursor to next entry (or clears to nil)
- `current()` — returns the command at cursor position, or empty string if cursor is nil

### LineEditor

Handles raw terminal input, detecting arrow key escape sequences and delegating navigation to `CommandHistory`.

**Fields**:
| Field         | Type       | Description |
|---------------|------------|-------------|
| `history`     | `CommandHistory` | The history for navigation |
| `historyMode` | `Bool`     | Whether currently browsing history (vs. editing fresh input) |

**Behavior**:
- Reads bytes from stdin in raw mode
- Detects arrow key sequences (`\x1B[A`, `\x1B[B`) and calls `history.moveUp()`/`moveDown()`
- Returns full line when Enter (`\n`) is pressed
- Non-TTY stdin falls back to `readLine()` without history support

### HistoryBuiltin

A builtin command that displays all history entries with sequential line numbers.

**Output format**:
```
 1  command1
 2  command2
 3  command3
```

- Line numbers are right-aligned with 4-character field width (padded with spaces)
- A two-space separator between number and command
- Commands are printed oldest first, newest last
- No output if history is empty
