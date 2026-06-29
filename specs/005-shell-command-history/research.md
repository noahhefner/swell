# Research: Shell Command History

## Raw Terminal Input on Linux Swift

**Decision**: Use POSIX `termios` via Swift's `Darwin`/`Glibc` module (auto-mapped as `import Glibc` on Linux) to switch stdin between canonical and raw mode.

**Rationale**: The existing `readLine()` function operates in canonical mode (line-buffered with echo), which does not expose individual keystrokes. To detect arrow keys, stdin must be switched to raw mode where every byte is available immediately. POSIX termios is the standard API for this and is available on all Linux platforms without additional dependencies.

**Implementation approach**:
- Save current terminal attributes with `tcgetattr(STDIN_FILENO)`
- Disable `ECHO`, `ICANON`, `ISIG`, `IXON`, `IEXTEN`, `VMIN=1`, `VTIME=0`
- Restore original attributes on exit (using `defer` block for cleanup)
- Use `FileHandle.standardInput.readabilityHandler` or blocking `read()` for input

**Alternatives considered**:
- `DispatchSource` on stdin file descriptor — adds complexity; synchronous read loop is simpler for a REPL
- Third-party library (e.g., `SwiftLine`) — violates "no new dependencies" constraint
- ncurses/termcap — heavyweight for just arrow key detection

## Arrow Key Escape Sequence Detection

**Decision**: Parse ANSI escape sequences manually from raw input bytes.

**Rationale**: Arrow keys send a 3-byte sequence: `ESC [ A` (Up), `ESC [ B` (Down), `ESC [ C` (Right), `ESC [ D` (Left). The line editor reads one byte at a time and, when it sees `\x1B` (ESC), checks for a following `[` and then a directional character.

**Escape sequences**:
| Key   | Sequence      |
|-------|---------------|
| Up    | `\x1B[A`      |
| Down  | `\x1B[B`      |
| Right | `\x1B[C`      |
| Left  | `\x1B[D`      |
| Enter | `\n` (0x0A)   |

**Alternatives considered**:
- Read entire escape sequence with a buffer — fine; the 3-byte pattern is simple and unambiguous
- Use `read()` syscall directly for byte-at-a-time input — simplest and most reliable

## Terminal State Restoration

**Decision**: Use `defer` blocks and signal handlers to restore terminal attributes on exit, crash, SIGINT, and SIGTERM.

**Rationale**: If the program exits without restoring raw mode, the user's terminal becomes unusable. Restoring via `defer` covers normal exit paths. For signals, the existing `DispatchSource` signal handlers in `SignalHandler.swift` should be extended to call the restore function before terminating.

**Alternatives considered**:
- `atexit()` handler — works but doesn't cover SIGKILL/SIGSEGV
- Signal handlers in existing infrastructure — preferred since the project already has `DispatchSource`-based signal handling

## Non-TTY Fallback

**Decision**: Check `isatty(STDIN_FILENO)` before entering raw mode. If stdin is not a TTY (e.g., piped input), fall back to `readLine()` with no history support.

**Rationale**: Raw mode only works on TTYs. `readLine()` is fine for non-interactive use and avoids complexity.
