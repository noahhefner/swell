# Implementation Plan: Shell Command History

**Branch**: `005-shell-command-history` | **Date**: 2026-06-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/005-shell-command-history/spec.md`

## Summary

Add up/down arrow history navigation and a `history` builtin command to the swell shell. The REPL's input reading (`readLine()`) will be replaced with a custom line editor that detects ANSI escape sequences for arrow keys and navigates an in-memory command history list.

## Technical Context

**Language/Version**: Swift 6.0

**Primary Dependencies**: Foundation (stdlib only — termios via POSIX C interop, no new packages)

**Storage**: In-memory (`[String]` array with navigation cursor)

**Testing**: Swift Testing framework (`#expect`/`#require`)

**Target Platform**: Linux (Ubuntu 22.04+, RHEL 9+) — must compile on Linux Swift

**Project Type**: CLI shell (interactive REPL)

**Performance Goals**: History navigation must feel instant (<50ms perceived latency). No measurable overhead on normal execution path.

**Constraints**: Must not add any new Swift Package dependencies. Must restore terminal state on crash/SIGINT/SIGTERM. Must handle non-TTY stdin gracefully (fall back to plain `readLine()`).

**Scale/Scope**: Session-scoped in-memory history. 1000s of entries per session.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Code Quality**: Architecture MUST avoid cyclomatic complexity >15 per function. SwiftLint and SwiftFormat MUST be run before submission. No force-unwraps without `precondition` guard. The custom line editor will be a self-contained module with clear single-responsibility boundaries.

**Swift Features**: Proposed approach MUST prefer value types — `CommandHistory` will be a `struct` with mutating methods. No `class` needed (terminal state can be managed via a wrapper struct with defer-based cleanup). No `Codable` needed (no persistence). No `async/await` needed (synchronous terminal I/O).

**Testing**: Feature MUST include unit tests (CommandHistory logic, escape sequence parsing) and integration tests (history navigation via simulated input, `history` builtin output format). Tests MUST be written before implementation.

**UX Consistency**: The `history` builtin MUST output simple aligned text with line numbers (no color needed, consistent with other builtins). Errors MUST go to stderr. The shell MUST respect `$NO_COLOR` in prompt display during navigation.

*No gate violations anticipated. Complexity Tracking left empty.*

## Project Structure

### Documentation (this feature)

```text
specs/005-shell-command-history/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
Sources/swell/
├── REPL.swift              # Modified: replace readLine() with LineEditor
├── LineEditor/             # NEW: terminal input handling module
│   ├── LineEditor.swift    #        raw-mode input reader with history nav
│   └── CommandHistory.swift #       in-memory history storage + navigation
├── Builtins/
│   ├── History.swift       # NEW: history builtin command
│   ├── CD.swift
│   ├── Echo.swift
│   ├── Exit.swift
│   ├── Export.swift
│   └── PWD.swift
├── Parser/
│   ├── Parser.swift
│   └── Token.swift
├── Prompt/
│   ├── PromptRenderer.swift
│   └── PromptConfig.swift
├── Environment/
│   └── ShellEnvironment.swift
├── Execution/
│   └── Redirection.swift
├── Color/
│   ├── ColorConfig.swift
│   ├── ColorResolver.swift
│   └── ColorState.swift
├── SignalHandler.swift
└── Swell.swift

Tests/
├── SwellTests/
│   ├── CommandHistoryTests.swift   # NEW: unit tests for history logic
│   └── ...
└── SwellIntegrationTests/
    ├── HistoryIntegrationTests.swift  # NEW: integration tests
    └── ...
```

The REPL owns the `CommandHistory` instance and passes `entries` to `History.execute()` as a parameter.

**Structure Decision**: Single-project layout matching existing structure. New files placed in a `LineEditor/` subdirectory under `Sources/swell/` to keep terminal I/O separate from the REPL orchestrator.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
