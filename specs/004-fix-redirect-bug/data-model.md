# Data Model: IO Redirection

## Overview

The redirect data model is split between parsing (tokenization and storage) and execution (file handle creation). The parser has no issues — all changes are in the execution layer.

## Core Types

### `Redirection` (in `Sources/swell/Execution/Redirection.swift`)

A stateless utility struct with static methods for opening file handles:

```swift
public struct Redirection: Sendable {
    public static func openForOverwrite(_ path: String) throws -> FileHandle
    public static func openForAppend(_ path: String) throws -> FileHandle
}
```

- **`openForOverwrite`**: Truncates existing file or creates new one, returns writable `FileHandle`
- **`openForAppend`**: Creates file if not exists, seeks to end, returns writable `FileHandle`
- Both methods throw on failure (unwritable path, disk full, etc.)

No changes needed to this type.

### `ParsedCommand` (in `Sources/swell/Parser/Parser.swift`)

Properties relevant to redirect:

```swift
public struct ParsedCommand: Sendable {
    public var name: String
    public var arguments: [String]             // Does NOT contain redirect operators or filenames
    public var stdoutRedirect: RedirectTarget?  // Populated by parser for > and >>
    public var stderrRedirect: RedirectTarget?  // Populated by parser for 2> and 2>>
}
```

The parsed redirect info is stored as a `RedirectTarget` enum (defined in `Parser.swift`):

```swift
public enum RedirectTarget: Sendable, Equatable {
    case overwrite(String)   // String = file path
    case append(String)      // String = file path
}
```

No changes needed — parsing is already correct.

## Data Flow

```
User input: "echo hello > out.txt"
    │
    ▼
Parser.parse(input) ──► ParsedCommand
    │                     ├─ name: "echo"
    │                     ├─ arguments: ["hello"]
    │                     ├─ stdoutRedirect: RedirectTarget.overwrite("out.txt")
    │                     └─ stderrRedirect: nil
    │
    ▼
REPL.execute(input)
    │
    ├─ executeSingle(command) ──► Opens file via Redirection.openForOverwrite("out.txt")
    │                              Passes FileHandle to executeExternal → process.standardOutput
    │
    └─ executePipeline ──► launchPipelineProcess: last cmd opens file directly
                            Skips outPipe when redirect present
```

## State Transitions

No persistent state — redirect file handles are created, assigned to `Process`, and closed automatically when the `Process` completes. No cleanup needed.
