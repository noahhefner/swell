# Redirect Contract

## Interface

The redirect execution interface is internal to the `REPL` class, invoked via `executeSingle` (single commands) and `executePipeline`/`launchPipelineProcess` (pipeline commands) when the parser detects `>`, `>>`, `2>`, or `2>>` operators.

## Contract

### Input

- `ParsedCommand.stdoutRedirect: RedirectionSpec?` — stdout redirect specification (mode + target path)
- `ParsedCommand.stderrRedirect: RedirectionSpec?` — stderr redirect specification (mode + target path)
- If both are `nil`, no redirect is performed (default terminal output behavior)
- `Redirection.openForOverwrite(path)` and `Redirection.openForAppend(path)` — static methods that produce writable `FileHandle` instances

### Behavior

#### Single Commands

1. **Redirect Detection**: `executeSingle` inspects `command.stdoutRedirect` and `command.stderrRedirect` before calling `executeExternal`.
2. **File Handle Creation**:
   - If `stdoutRedirect.mode == .overwrite` → `Redirection.openForOverwrite(path)`
   - If `stdoutRedirect.mode == .append` → `Redirection.openForAppend(path)`
   - Same pattern for `stderrRedirect`
3. **Process Assignment**: File handles are passed as `stdoutDest`/`stderrDest` to `executeExternal`.
4. **Pipe Bypass**: When `stdoutDest` is non-nil, `executeExternal` skips creating an output `Pipe`. Similarly for `stderrDest`. The process writes directly to the file.

#### Builtin Commands (echo, cd, pwd, export)

1. **Builtin Execution**: Builtins execute normally and return `CommandResult.success(output:)` with a string.
2. **Redirect Handling**: After the builtin returns, `executeSingle` checks for redirects:
   - If `stdoutRedirect` exists, the output string is written to the file instead of being displayed on stdout.
   - The returned `CommandResult` has an empty output string (output was redirected to file).

#### Pipeline Commands

1. **Last Command Only**: Redirects apply only to the last command in the pipeline (consistent with bash behavior — e.g., `ls | grep foo > out.txt`).
2. **File Handle Creation**: Same pattern — inspect `command.stdoutRedirect`/`stderrRedirect` on the last command.
3. **Process Assignment**: In `launchPipelineProcess`, for the last command, assign the file handle to `process.standardOutput` (or `process.standardError`) instead of the output pipe.
4. **Output Collection**: When the last command has a stdout redirect, `collectPipelineOutput` skips reading from `outPipe` and returns `.success(output: "")`.

### Output

- `CommandResult.success(output: String)` — Command completed; output is either captured (no redirect) or empty (redirected to file)
- `CommandResult.failure(error: String, exitCode: Int32)` — Command failed; error message includes file open failure details or command execution failure

### Error Handling

- **Unwritable path**: When `Redirection.openForOverwrite`/`openForAppend` throws, return `CommandResult.failure(error: "cannot open <path> for writing: <reason>", exitCode: 1)`
- **Command execution failure**: Existing error handling remains unchanged
- **Non-existent parent directory**: Caught by `Redirection.openForOverwrite`/`openForAppend` throwing (FileManager operations fail)

### Resource Management

- File handles opened for redirect are assigned to `Process.standardOutput`/`standardError` and are closed by the system when the process completes
- If a file handle cannot be opened (error case), it is never assigned and is deallocated naturally
- No explicit close/cleanup needed — redirect file handles are consumed by the `Process` and released on process exit

## Test Coverage

The following test files cover the redirect contract:

- `Tests/SwellIntegrationTests/RedirectionIntegrationTests.swift` — Existing tests using raw `Process` (bypassing shell)
- New REPL-level redirect tests (to be added during implementation) — Test redirect through `REPL.execute(_:)`
