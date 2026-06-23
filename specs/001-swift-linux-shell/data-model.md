# Data Model: Swift Linux Shell

## Entities

### Token
Represents a single lexical unit from the parsed input line.

| Field | Type | Description |
|-------|------|-------------|
| `kind` | `TokenKind` | `.command(String)`, `.pipe`, `.redirectOut`, `.redirectAppend`, `.redirectErr`, `.redirectErrAppend`, `.filename(String)` |
| `span` | `Range<String.Index>` | Source position in the original input |

### Command
A single executable unit within a pipeline.

| Field | Type | Description |
|-------|------|-------------|
| `name` | `String` | Executable name or path |
| `arguments` | `[String]` | Arguments after quote processing |
| `stdinSource` | `IO.Source` | Where stdin comes from (pipe, file, terminal) |
| `stdoutTarget` | `IO.Target` | Where stdout goes (pipe, file, overwrite, append, terminal) |
| `stderrTarget` | `IO.Target` | Where stderr goes (file, overwrite, append, terminal) |

**Validation rules**: `name` must not be empty. Arguments may be empty.
If `stdoutTarget` and `stderrTarget` point to the same file with
conflicting modes, the command is invalid.

### Pipeline
A sequence of commands connected by pipes.

| Field | Type | Description |
|-------|------|-------------|
| `commands` | `[Command]` | Commands in execution order |

**Invariant**: `commands` must contain at least one element.
**Constraint**: No more than 1024 stages (same as Linux `MAX_PIPE`).

### IO (enum)

```swift
enum IO {
    enum Source {
        case terminal      // Read from /dev/tty
        case pipe(FileHandle)  // Read from pipe read-end
        case file(String)      // Read from file
    }

    enum Target {
        case terminal           // Write to /dev/tty
        case pipe(FileHandle)   // Write to pipe write-end
        case overwrite(String)  // >  file (create/truncate)
        case append(String)     // >> file (create/append)
    }
}
```

### ShellEnvironment
Manages environment variable state for the shell session.

| Field | Type | Description |
|-------|------|-------------|
| `variables` | `[String: String]` | Current environment key-value pairs |
| `initialCWD` | `String` | Working directory at shell start |

**State transitions**:
- `export KEY=VALUE` → upsert key
- `export KEY` (no value) → set empty string
- `cd /path` → update `PWD` in variables

### PromptConfig
Defines the prompt template and the supported escape sequences.

| Field | Type | Description |
|-------|------|-------------|
| `template` | `String` | Raw template string from config file |
| `escapes` | `[Character: PromptEscape]` | Mapping of escape char to renderer |

**Supported escape sequences**:
| Sequence | Renders To |
|----------|------------|
| `\u` | Current username (`$USER` or `whoami`) |
| `\h` | Hostname (short) |
| `\w` | Current working directory |
| `\W` | Basename of current directory |
| `\t` | Current time (HH:MM:SS) |
| `\$` | `#` if UID 0 else `$` |
| `\\` | Literal backslash |
| `\n` | Newline |

## State Machine: Shell Session

```
                ┌──────────────┐
                │   START      │
                │ print prompt  │
                └──────┬───────┘
                       │ readLine()
                       ▼
                ┌──────────────┐
                │   READING    │
                │ input line   │
                └──────┬───────┘
                       │ line received
                       ▼
                ┌──────────────┐
                │   PARSING    │
                │ Tokenize →   │
                │ Build AST    │
                └──────┬───────┘
                  ┌────┴────┐
                  ▼         ▼
           ┌──────────┐  ┌──────────┐
           │ BUILTIN  │  │ EXTERNAL │
           │ execute  │  │ fork+exec│
           │ in-process│  │ pipe fds │
           └────┬─────┘  └────┬─────┘
                │              │
                ▼              ▼
           ┌────────────────────────┐
           │      COMPLETE          │
           │ collect exit code      │
           │ print next prompt      │
           └───────────┬────────────┘
                       │ loop until "exit"
                       ▼
                ┌──────────────┐
                │   EXIT       │
                │ return code 0│
                └──────────────┘
```

**Transitions**:
- START → READING: Shell outputs prompt and waits for input
- READING → PARSING: Input line received (non-empty)
- READING → READING: Empty or whitespace-only input → show next prompt
- PARSING → BUILTIN: Command name matches a registered built-in
- PARSING → EXTERNAL: Command name does not match a built-in (search PATH)
- BUILTIN/EXTERNAL → COMPLETE: Process exits or built-in returns
- COMPLETE → READING: Print next prompt
- COMPLETE → EXIT: `exit` built-in or EOF (Ctrl+D)
- Any → READING: SIGINT received (abort current command)
