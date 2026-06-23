# Implementation Plan: Swift Linux Shell

**Branch**: `` | **Date**: 2026-06-23 | **Spec**: specs/001-swift-linux-shell/spec.md

**Input**: Feature specification from `specs/001-swift-linux-shell/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Build an interactive Linux shell (like bash or fish) in Swift that executes
external binaries, supports pipes (`|`), file redirections (`>`/`>>`/`2>`),
and customizable prompts. Toolchain managed by Swiftly. Targets any modern
Linux distribution (x86_64 + ARM64).

## Technical Context

**Language/Version**: Swift (latest stable via Swiftly)

**Primary Dependencies**:
- Foundation (POSIX process management, file I/O)
- Swift Argument Parser (shell's own `--help`/`--version`)
- No external C libs beyond libc/glibc (use `posix_spawn`, `pipe`, `dup2`,
  `sigaction` via Swift's `Darwin`/`Glibc` module or the `System` package)

**Storage**: N/A (no persistent storage shell itself; config file at
`~/.config/swell/prompt` is plain text)

**Testing**: Swift Testing framework (`#expect`, `#require`) + XCTest for
integration tests. Subprocess-based output validation for CLI snapshot
tests.

**Target Platform**: Linux (Ubuntu 22.04+, RHEL 9+, Debian 12+, Fedora
38+) on x86_64 and ARM64

**Project Type**: CLI (interactive shell)

**Performance Goals**: Command execution starts in <50ms (fork+exec
latency). Prompt display <10ms. Pipeline throughput matches native pipe
performance (>100MB/s between stages).

**Constraints**:
- No Combine, SwiftUI, UIKit (per constitution Portability rule)
- No Apple platform frameworks
- Must compile on Linux Swift via Swiftly
- Must respect `$NO_COLOR`, `$CLICOLOR`, `$CLICOLOR_FORCE`, `$PAGER`,
  `$EDITOR` (per constitution UX principle)
- Signal handling must follow POSIX (SIGINT → abort foreground command;
  SIGPIPE → silent termination)

**Scale/Scope**: Single-user interactive shell. Not a job-control shell
(no `&`, `fg`, `bg` in v1). Not a scripting language runtime.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Code Quality**: Architecture MUST avoid cyclomatic complexity >15 per
function. SwiftLint and SwiftFormat MUST be run before submission. No
force-unwraps without `precondition` guard.

**Swift Features**: Proposed approach MUST prefer value types, use
`async/await` over callbacks, use `Codable` for serialization, and not
introduce `class` without documented identity need.

**Testing**: Feature MUST include unit tests (all public functions),
integration tests (IPC, file-system, subprocess flows), and output/snapshot
tests for CLI output. Tests MUST be written before implementation.

**UX Consistency**: CLI changes MUST use consistent `--flag` style, provide
`--help`/`--version` output, send errors to stderr, respect `$NO_COLOR`
and `$PAGER`, and use `String(localized:)`.

*If any gate is not satisfied, add a Complexity Tracking entry below.*

## Project Structure

### Documentation (this feature)

```text
specs/001-swift-linux-shell/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── cli-contract.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
Sources/
└── swell/
    ├── Swell.swift            # @main entry point
    ├── REPL.swift             # Read-eval-print loop
    ├── Parser/
    │   ├── Token.swift        # Token types (command, pipe, redirect)
    │   └── Parser.swift       # Input string → Pipeline AST
    ├── Execution/
    │   ├── Pipeline.swift     # Pipeline execution (fork/exec, pipe plumbing)
    │   ├── Command.swift      # Single command execution
    │   └── Redirection.swift  # File descriptor plumbing
    ├── Builtins/
    │   ├── CD.swift
    │   ├── PWD.swift
    │   ├── Exit.swift
    │   ├── Export.swift
    │   └── Echo.swift
    ├── Prompt/
    │   ├── PromptConfig.swift # Config loading & parsing
    │   └── PromptRenderer.swift  # Escape sequence expansion
    └── Environment/
        └── ShellEnvironment.swift  # env var store + inheritance

Tests/
├── SwellTests/
│   ├── ParserTests.swift
│   ├── PipelineTests.swift
│   ├── BuiltinTests.swift
│   └── PromptRendererTests.swift
└── SwellIntegrationTests/
    ├── ExecutionIntegrationTests.swift
    ├── PipeIntegrationTests.swift
    └── RedirectionIntegrationTests.swift
```

**Structure Decision**: Standard Swift Package Manager layout with
`Sources/swell/` for library code and `Tests/` for tests. No nested
`src/` directory — SPM convention uses `Sources/` directly. Modules
are organized by responsibility (Parsing, Execution, Builtins, Prompt,
Environment) rather than by layer.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A — all gates satisfied | | |
