# Implementation Plan: Terminal Color Support

**Branch**: `002-terminal-color-support` | **Date**: 2026-06-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-terminal-color-support/spec.md`

## Summary

Add ANSI color support to the swell shell that respects `$NO_COLOR`, `$CLICOLOR`, `$CLICOLOR_FORCE`, and `$TERM` environment variables. Color is applied to error messages (red on stderr), prompt escape sequences (`\[\e[<code>m\]` syntax), and auto-disables when output is not a TTY. Color-to-output-type mappings are hardcoded internally.

## Technical Context

**Language/Version**: Swift 6.0 (Swift 6 language mode, strict concurrency checking)

**Primary Dependencies**: Foundation (Process, Pipe, FileHandle), no external color libraries

**Storage**: N/A — all color state resolved dynamically from environment per-output

**Testing**: Swift Testing framework (`#expect`, `#require`) for unit tests; XCTest for integration

**Target Platform**: Linux (Ubuntu 22.04+, RHEL 9+, Debian 12+, Fedora 38+) on x86_64 and ARM64

**Project Type**: CLI shell tool (swell)

**Performance Goals**: Color resolution must add <1ms overhead per prompt/output render

**Constraints**: Must use only Linux-stdlib APIs; `isatty()` via Glibc; no Apple platform APIs

**Scale/Scope**: Single-process REPL; color state resolved per write operation

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Code Quality**: New color module will keep each function under 15 cyclomatic complexity. No force-unwraps without `precondition` guard. SwiftLint pass required before merge.

**Swift Features**: ColorState and ColorResolver will be value types (struct/enum). No classes introduced. `Codable` not needed (no persistence). `Sendable` conformance for concurrent signal handler access.

**Testing**: Unit tests for `ColorResolver.resolve()` covering all env var combinations (NO_COLOR, CLICOLOR, CLICOLOR_FORCE, TERM, TTY status). Integration tests verifying ANSI codes appear/do-not-appear in piped output. Existing 38 tests must continue passing.

**UX Consistency**: Color output respects `$NO_COLOR` (already partially implemented in REPL). Error colors go to stderr. Prompt color escapes follow `\[\e[...\]` bash-compatible syntax. `String(localized:)` not needed (no user-visible strings added).

*Gates satisfied — no Complexity Tracking entries needed.*

## Project Structure

### Documentation (this feature)

```text
specs/002-terminal-color-support/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output
```

### Source Code (repository root)

```text
Sources/swell/
├── Color/
│   ├── ColorState.swift         # Resolved color state (enabled/disabled)
│   ├── ColorConfig.swift        # Hardcoded ANSI code mappings per output type
│   └── ColorResolver.swift      # Reads env vars + TTY status → ColorState
├── Prompt/
│   └── PromptRenderer.swift     # Updated to support \e[...] color escapes
├── REPL.swift                   # Updated to use ColorResolver for errors/prompts
├── Swell.swift
├── SignalHandler.swift
├── Parser/
├── Execution/
├── Environment/
└── Builtins/

Tests/
├── SwellTests/
│   └── ColorTests.swift         # Unit tests for ColorResolver, ColorState
└── SwellIntegrationTests/
    └── ColorIntegrationTests.swift  # Integration tests for color output
```

**Structure Decision**: New `Sources/swell/Color/` directory for the color module. This isolates all color logic from the rest of the codebase and makes it easy to test. Minimal changes to existing files (REPL.swift, PromptRenderer.swift).

## Complexity Tracking

*No violations — all gates satisfied.*

## Phases

### Phase 0: Research

All technical unknowns are resolved to known Swift/Linux patterns. See `research.md`.

### Phase 1: Design & Contracts

- `data-model.md`: ColorState, ColorConfig, ColorResolver entities
- `contracts/`: Environment variable resolution order, ANSI code reference
- `quickstart.md`: Validation scenarios with env var combinations

### Phase 2: Tasks

Feature implementation tasks broken down into:
1. **Color module** — ColorState, ColorConfig, ColorResolver types
2. **PromptRenderer update** — Parse `\[\e[<code>m\]` and `\e[0m` escape sequences
3. **REPL wiring** — Apply color to error messages and prompt rendering
4. **Tests** — Unit + integration tests for all color paths
5. **Cleanup** — Remove dead `useColorOutput` stub from `REPL.swift`
