# Research: Fix Redirect Bug

## Decision: Implementation Strategy

**Decision**: Modify `executeSingle`, `executeExternal`, `executePipeline`, and `launchPipelineProcess` in `REPL.swift` to read `stdoutRedirect`/`stderrRedirect` from `ParsedCommand` and open file handles before process launch. For builtins, capture output string and write to file if redirect specified.

**Rationale**:
- The parser already correctly handles all four redirect operators (`>`, `>>`, `2>`, `2>>`) and stores them as `Redirection?` on each `ParsedCommand`.
- The `Redirection` struct already provides `openForOverwrite` and `openForAppend` static methods that return a properly configured `FileHandle`.
- Only the execution paths in `REPL.swift` need changes — the data is parsed correctly but never consumed.

**Alternatives considered**:
- Rewriting the parser to strip redirect args from `command.arguments`: Not needed — arguments already exclude redirect operators and filenames.
- Adding a new `PipelineExecutor` class: Dead code was already removed in `003-fix-pipe-bug`. The existing inline approach in `REPL.swift` is correct and simpler.

## Decision: Builtin Redirect Handling

**Decision**: For builtins (echo, cd, etc.), check `stdoutRedirect` in `executeSingle`. If present, write the returned output string to the file instead of returning it as `.success(output:)`. Write to the file and return `.success(output: "")`.

**Rationale**: Builtins return their output as a `String` via `CommandResult.success(output:)`. The REPL's `run()` loop then prints that string to stdout. For redirects, we intercept this — write to file, return empty string. This avoids forking an external process just for builtins.

**Alternatives considered**:
- Forking an external `echo` process: Inefficient and breaks builtin semantics.
- Modifying `Echo.execute` to accept a redirect parameter: Couples builtins to I/O concerns. Better to handle in `executeSingle` which is the orchestrator.

## Decision: Pipeline Redirect Strategy

**Decision**: In `launchPipelineProcess`, when processing the last command in a pipeline (index == total-1), check `command.stdoutRedirect` and `command.stderrRedirect`. If present, open the file and assign `process.standardOutput`/`process.standardError` directly, skipping the outPipe. In `collectPipelineOutput`, check if the last command had redirects — if so, return `.success(output: "")` since output went to file.

**Rationale**: This is consistent with bash behavior — `ls | grep foo > out.txt` should write grep's output to the file, not to the terminal. The last process in the pipeline writes directly to the file.

**Alternatives considered**:
- Writing outPipe contents to file after pipeline completion: Works but wastes memory for large output. Direct file assignment is more efficient and matches how shells work.

## Codebase Facts (from exploration)

- `ParsedCommand` has `stdoutRedirect: Redirection?` and `stderrRedirect: Redirection?` properties.
- `Redirection` enum (in `Execution/Redirection.swift`): has `openForOverwrite` and `openForAppend` static methods that return `FileHandle`.
- Parser strips redirect tokens from `arguments` — `command.arguments` does not contain `>` or filenames.
- `ParsedCommand.redirect` property may exist — need to check if it's separate from `stdoutRedirect`/`stderrRedirect`.
- Current test count: 57 tests (from `003-fix-pipe-bug`).
- Integration tests for redirect exist at `Tests/SwellIntegrationTests/RedirectionIntegrationTests.swift` but test via raw `Process`, not through the REPL.

## Decision: Error Handling for Unwritable Paths

**Decision**: If the redirect target file cannot be opened (unwritable path, disk full, etc.), return `.failure(error: "cannot open <path> for writing: <underlying error>", exitCode: 1)`.

**Rationale**: Matches bash behavior of printing an error and continuing. The error message goes to stderr via the existing REPL failure handling.

## Decision: No New Dependencies

**Decision**: No new Swift Package dependencies needed. Everything uses Foundation (`FileHandle`, `FileManager`, `Process`).

**Rationale**: The shell already uses Foundation for all I/O. Adding a dependency for file redirection would violate the constitution's "Minimal Dependencies" constraint.
