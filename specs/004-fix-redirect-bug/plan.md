# Implementation Plan: Fix Redirect Bug

**Branch**: `004-fix-redirect-bug` | **Date**: 2026-06-25 | **Spec**: `specs/004-fix-redirect-bug/spec.md`

**Input**: Feature specification from `specs/004-fix-redirect-bug/spec.md`

## Summary

Fix IO redirect operators (`>`, `>>`, `2>`, `2>>`) that parse correctly but are ignored during execution. All four redirect types for stdout and stderr must work for both external commands and builtins, including in pipeline context.

## Technical Context

**Language/Version**: Swift (latest stable, as tracked by CI)

**Primary Dependencies**: Foundation only (Process, FileHandle, FileManager)

**Storage**: N/A (filesystem I/O via POSIX file handles)

**Testing**: Swift Testing framework (`#expect`, `#require`), integration test target (`SwellIntegrationTests`)

**Target Platform**: Linux (Ubuntu 22.04+, also macOS for development)

**Project Type**: CLI (interactive shell)

**Performance Goals**: N/A — redirect is a correctness fix, not a performance improvement

**Constraints**: No new dependencies; must not break existing 57 tests; must respect `$NO_COLOR` and other shell env vars; must work with Process subprocess spawning

**Scale/Scope**: Bugfix affecting 3 execution paths in REPL.swift (~311 lines). Scope limited to: `executeSingle` (line 102), `executeExternal` (line 126), `executePipeline` (line 177), `launchPipelineProcess` (line 216).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Code Quality**: Fix must maintain cyclomatic complexity ≤15 per function. The changes are additive — opening file handles and passing them through — no new branching complexity. SwiftLint and SwiftFormat must pass.

**Swift Features**: Use existing `Redirection.openForOverwrite`/`openForAppend` static methods (value types). No new `class` types needed. `FileHandle` is a Foundation class but is a system type, not project code. No `async/await` changes needed — `Process.run()`/`waitUntilExit()` is synchronous and correct for this shell.

**Testing**: Must include integration tests for all four redirect types (`>`, `>>`, `2>`, `2>>`) through the REPL. Existing `RedirectionIntegrationTests` test via raw `Process` only — need REPL-level tests. Tests must be written before implementation.

**UX Consistency**: Redirected output goes to files, not terminal. Error messages for unwritable paths go to stderr. Respects shell's existing error format: `error: <message>\n`.

*GATE PASSED — no violations.*

## Project Structure

### Documentation (this feature)

```text
specs/004-fix-redirect-bug/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
Sources/swell/
├── REPL.swift           # Main execution — primary target for changes
├── Execution/
│   └── Redirection.swift # Already has openForOverwrite/openForAppend — may need minor changes
├── Parser/
│   ├── Parser.swift      # Already correct — no changes needed
│   ├── ParsedCommand.swift # Already has stdoutRedirect/stderrRedirect — no changes needed
│   └── Token.swift        # Already handles redirect tokens — no changes needed

Tests/
├── SwellTests/           # Unit tests (may add)
└── SwellIntegrationTests/ # Integration tests (will add REPL-level redirect tests)
```

**Structure Decision**: Single project — no structural changes needed. Changes are confined to `REPL.swift` primarily, with potential minor changes to `Redirection.swift`.

## Complexity Tracking

N/A — Constitution Check passed with no violations.
