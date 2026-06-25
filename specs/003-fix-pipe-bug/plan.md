# Implementation Plan: Fix Pipe Bug

**Branch**: `` | **Date**: 2026-06-25 | **Spec**: specs/003-fix-pipe-bug/spec.md

**Input**: Feature specification from `specs/003-fix-pipe-bug/spec.md`

## Summary

Fix two critical bugs in the shell's pipeline execution that caused "Bad file descriptor" errors on any piped command:

1. **Premature pipe read-end closure**: `closeUnusedPipeHandles` was called before `process.run()`, closing the read end of pipes that subsequent processes needed for stdin. For the first process (index=0), the condition `pipeIndex(0) != -1` was always true, so `pipes[0].fileHandleForReading` was closed before the second process could inherit it.

2. **Post-launch stdout assignment**: `collectPipelineOutput` created a new `Pipe()` and assigned it to `lastProcess.standardOutput` AFTER the process had already been spawned and may have completed — making the assignment a no-op and losing all output.

## Technical Context

**Language/Version**: Swift 6.0 (via Swiftly)

**Primary Dependencies**: Foundation (Process, Pipe, FileHandle)

**Storage**: N/A

**Testing**: Swift Testing framework (`#expect`, `#require`) — 53 existing tests across SwellTests and SwellIntegrationTests

**Target Platform**: Linux (Ubuntu 22.04+, RHEL 9+, Debian 12+, Fedora 38+) on x86_64 and ARM64

**Project Type**: CLI (interactive shell)

**Performance Goals**: Unchanged by this bugfix — pipe throughput continues to match native pipe performance.

**Constraints**:
- All pipe file handles must remain valid until the child process inherits them at `process.run()` time
- The parent process must close its copies of all pipe file descriptors after all children are spawned
- No Apple platform frameworks

**Scale/Scope**: Single-user interactive shell. This is a bugfix for the existing pipeline execution code path in `REPL.swift`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Code Quality**: Architecture MUST avoid cyclomatic complexity >15 per function. The fix removes two methods (`closeUnusedPipeHandles`, `closePipeWriters`) and simplifies `collectPipelineOutput`, reducing overall complexity.

**Swift Features**: Proposed approach uses existing Foundation primitives (`Process`, `Pipe`, `FileHandle`) correctly — no new classes introduced.

**Testing**: Feature includes existing integration tests for pipes (PipeIntegrationTests) which already pass. Additional pipeline tests in ExecutionIntegrationTests verify the full pipeline path through the shell's REPL.

**UX Consistency**: No UX changes — this is a correctness fix that restores expected pipe behavior.

*If any gate is not satisfied, add a Complexity Tracking entry below.*

## Project Structure

### Documentation (this feature)

```text
specs/003-fix-pipe-bug/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── pipe-contract.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
Sources/swell/
├── Swell.swift            # @main entry point (unchanged)
├── REPL.swift             # Pipeline execution fix (modified)
├── Parser/
│   ├── Token.swift        # Token types (unchanged)
│   └── Parser.swift       # Input string → Pipeline AST (unchanged)
├── Execution/
│   ├── Pipeline.swift     # Dead code — unused (unchanged)
│   └── Redirection.swift  # File handle helpers (unchanged)
├── Builtins/
│   ├── CD.swift           # (unchanged)
│   ├── PWD.swift          # (unchanged)
│   ├── Exit.swift         # (unchanged)
│   ├── Export.swift       # (unchanged)
│   └── Echo.swift         # (unchanged)
├── Color/                 # (unchanged)
├── Prompt/                # (unchanged)
└── Environment/
    └── ShellEnvironment.swift  # (unchanged)

Tests/
├── SwellTests/
│   ├── PipelineTests.swift
│   ├── CommandTests.swift
│   └── BuiltinTests.swift
└── SwellIntegrationTests/
    ├── PipeIntegrationTests.swift
    ├── ExecutionIntegrationTests.swift
    └── RedirectionIntegrationTests.swift
```

**Structure Decision**: Standard Swift Package Manager layout with `Sources/swell/`. The fix is entirely within `REPL.swift` — no new files or modules are needed.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A — all gates satisfied | | |
