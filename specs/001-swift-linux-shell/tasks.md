---

description: "Task list for Swift Linux Shell feature implementation"

---

# Tasks: Swift Linux Shell

**Input**: Design documents from `specs/001-swift-linux-shell/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: The examples below include test tasks. Tests are **REQUIRED** per Constitution Principle III (Testing Standards). Every feature MUST include unit, integration, and — for CLI output — snapshot tests.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `Sources/`, `Tests/` at repository root
- Paths below use the SPM layout from plan.md

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create Swift Package Manager project structure with `Sources/swell/` and `Tests/` directories
- [ ] T002 Create `Package.swift` with swift-tools-version 6.0, executable target `swell`, and dependency on `swift-argument-parser`
- [ ] T003 [P] Create `.swiftlint.yml` with rules matching project conventions (no force-unwrap, cyclomatic complexity max 15)
- [ ] T004 [P] Create `.gitignore` for Swift projects (`.build/`, `*.swp`, `Package.resolved`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 [P] Implement Token types enum in `Sources/swell/Parser/Token.swift` (command, pipe, redirectOut, redirectAppend, redirectErr, redirectErrAppend, filename)
- [ ] T006 Implement Parser that converts input string to Pipeline AST in `Sources/swell/Parser/Parser.swift`
- [ ] T007 [P] Implement ShellEnvironment with `variables: [String: String]`, `initialCWD`, and PATH lookup in `Sources/swell/Environment/ShellEnvironment.swift`
- [ ] T008 Implement REPL skeleton (readLine loop, dispatch to executor) in `Sources/swell/REPL.swift`
- [ ] T009 [P] Implement signal handling (SIGINT → abort foreground command, SIGPIPE → silent exit) in `Sources/swell/SignalHandler.swift`
- [ ] T010 Implement `@main` entry point with `Swift Argument Parser` (`--help`, `--version`, `--rcfile`) in `Sources/swell/Swell.swift`

**Checkpoint**: Foundation ready — tokenizer, parser, environment store, REPL loop, and signal handling all functional

---

## Phase 3: User Story 1 — Execute an External Binary (Priority: P1) 🎯 MVP

**Goal**: User types a command and the shell finds and executes the corresponding binary on PATH, displaying stdout and exit code

**Independent Test**: Invoke `echo hello` → verify `hello` on stdout. Invoke `nonexistent` → verify error on stderr and non-zero exit.

### Tests for User Story 1 (REQUIRED — see Constitution Principle III) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T011 [P] [US1] Write unit test for Command execution (PATH lookup, argument passing, exit code) in `Tests/SwellTests/CommandTests.swift`
- [ ] T012 [P] [US1] Write integration test for binary execution (known binary, missing binary, binary with args) in `Tests/SwellIntegrationTests/ExecutionIntegrationTests.swift`

### Implementation for User Story 1

- [ ] T013 [P] [US1] Implement Command execution using `Foundation.Process` in `Sources/swell/Execution/Command.swift`
- [ ] T014 [US1] Wire REPL to parse input, dispatch command, capture stdout/stderr, print output in `Sources/swell/REPL.swift`
- [ ] T015 [US1] Handle PATH search failure and non-zero exit codes in `Sources/swell/Execution/Command.swift`

**Checkpoint**: At this point, the shell can execute external binaries with arguments

---

## Phase 4: User Story 2 — Pipe Output Between Commands (Priority: P1)

**Goal**: User pipes stdout of one command to stdin of another using `|`, enabling composition of command-line workflows

**Independent Test**: Pipe `echo hello world | wc -w` → verify output `2`. Chain 3+ stages and verify data flow.

### Tests for User Story 2 (REQUIRED — see Constitution Principle III) ⚠️

- [ ] T016 [P] [US2] Write unit test for Pipeline building from parsed commands in `Tests/SwellTests/PipelineTests.swift`
- [ ] T017 [P] [US2] Write integration test for pipe scenarios (2-stage, 3-stage, empty output pipe) in `Tests/SwellIntegrationTests/PipeIntegrationTests.swift`

### Implementation for User Story 2

- [ ] T018 [P] [US2] Implement Pipeline execution that forks each stage and plumbs pipes via `Foundation.Pipe` in `Sources/swell/Execution/Pipeline.swift`
- [ ] T019 [US2] Wire pipe operator parsing and pipeline execution into REPL dispatch in `Sources/swell/REPL.swift`

**Checkpoint**: At this point, the shell supports multi-stage pipelines

---

## Phase 5: User Story 3 — File Redirection (Priority: P1)

**Goal**: User redirects command output to files using `>` (overwrite) and `>>` (append), and stderr using `2>` and `2>>`

**Independent Test**: Run `echo data > /tmp/test.txt` → verify file contains `data`. Run `>>` → verify append. Combine pipe + redirect.

### Tests for User Story 3 (REQUIRED — see Constitution Principle III) ⚠️

- [ ] T020 [P] [US3] Write unit test for redirection file descriptor plumbing in `Tests/SwellTests/RedirectionTests.swift`
- [ ] T021 [P] [US3] Write integration test for redirection scenarios (overwrite, append, stderr redirect, unwritable file) in `Tests/SwellIntegrationTests/RedirectionIntegrationTests.swift`

### Implementation for User Story 3

- [ ] T022 [P] [US3] Implement Redirection logic that opens files and dups file descriptors in `Sources/swell/Execution/Redirection.swift`
- [ ] T023 [US3] Wire redirect operators (`>`, `>>`, `2>`, `2>>`) into parser tokens and execution in `Sources/swell/REPL.swift`

**Checkpoint**: At this point, the shell supports file redirection chained with pipes

---

## Phase 6: User Story 5 — Built-in Commands (Priority: P2)

**Goal**: User runs `cd`, `pwd`, `exit`, `export`, `echo` as built-in commands without spawning external processes

**Independent Test**: `cd /tmp` then `pwd` → verify `/tmp`. `export X=1` → subsequent command sees `X`. `exit` → shell terminates.

### Tests for User Story 5 (REQUIRED — see Constitution Principle III) ⚠️

- [ ] T024 [P] [US5] Write unit tests for all built-in commands in `Tests/SwellTests/BuiltinTests.swift`
- [ ] T025 [P] [US5] Write integration test for builtin interactions (cd then pwd, export then child env) in `Tests/SwellIntegrationTests/BuiltinIntegrationTests.swift`

### Implementation for User Story 5

- [ ] T026 [P] [US5] Implement `cd` built-in in `Sources/swell/Builtins/CD.swift`
- [ ] T027 [P] [US5] Implement `pwd` built-in in `Sources/swell/Builtins/PWD.swift`
- [ ] T028 [P] [US5] Implement `exit` built-in in `Sources/swell/Builtins/Exit.swift`
- [ ] T029 [P] [US5] Implement `export` built-in in `Sources/swell/Builtins/Export.swift`
- [ ] T030 [P] [US5] Implement `echo` built-in in `Sources/swell/Builtins/Echo.swift`
- [ ] T031 [US5] Wire built-in command dispatch into REPL (check builtins before PATH search) in `Sources/swell/REPL.swift`
- [ ] T032 [US5] Integrate builtins with ShellEnvironment (cd updates PWD, export adds variables) in `Sources/swell/Builtins/CD.swift` and `Sources/swell/Builtins/Export.swift`

**Checkpoint**: At this point, the shell supports all five built-in commands

---

## Phase 7: User Story 4 — Customizable Prompt (Priority: P2)

**Goal**: User customizes the shell prompt via `~/.config/swell/prompt` with escape sequences for username, hostname, directory, time

**Independent Test**: Configure prompt as `\u@\h:\w$ ` → verify prompt displays correctly. Change prompt → restart shell → verify new prompt.

### Tests for User Story 4 (REQUIRED — see Constitution Principle III) ⚠️

- [ ] T033 [P] [US4] Write unit test for prompt renderer escape sequence expansion in `Tests/SwellTests/PromptRendererTests.swift`
- [ ] T034 [P] [US4] Write integration test for prompt config loading and rendering in `Tests/SwellIntegrationTests/PromptIntegrationTests.swift`

### Implementation for User Story 4

- [ ] T035 [P] [US4] Implement PromptConfig loading from `$XDG_CONFIG_HOME/swell/prompt` (fallback `~/.config/swell/prompt`) in `Sources/swell/Prompt/PromptConfig.swift`
- [ ] T036 [US4] Implement PromptRenderer with escape sequences (`\u`, `\h`, `\w`, `\W`, `\t`, `\$`, `\\`, `\n`) in `Sources/swell/Prompt/PromptRenderer.swift`
- [ ] T037 [US4] Wire prompt rendering into REPL loop (print prompt before each readLine) in `Sources/swell/REPL.swift`

**Checkpoint**: At this point, the shell supports fully customizable prompts

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T038 [P] Add `$NO_COLOR`, `$CLICOLOR`, `$CLICOLOR_FORCE` environment variable support in `Sources/swell/REPL.swift`
- [ ] T039 Add documentation comments (`///`) to all public types and functions across `Sources/swell/`
- [ ] T040 [P] Run `swiftlint` and `swift format` across the entire codebase, fix all violations
- [ ] T041 [P] Run quickstart.md validation scenarios to verify end-to-end correctness

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - US1 (Phase 3) must complete before US2-5 can use its command execution
  - US2 (Phase 4) must complete before US3 can use pipeline execution
  - US3 (Phase 5) can start after US2 but uses independent redirection logic
  - US5 (Phase 6) depends on US1 for REPL dispatch and ShellEnvironment
  - US4 (Phase 7) depends only on Foundational — can proceed in parallel with US1-3
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies on other stories — start after Foundational
- **User Story 2 (P1)**: Depends on US1 (needs command execution for pipe stages)
- **User Story 3 (P1)**: Depends on US2 (needs pipeline execution for redirects)
- **User Story 5 (P2)**: Depends on US1 (needs REPL dispatch and ShellEnvironment)
- **User Story 4 (P2)**: No dependencies on other stories — can start after Foundational

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Models/tokens before execution logic
- Core implementation before integration wiring
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- US1 and US4 can start in parallel after Foundational
- All tests for a user story marked [P] can run in parallel
- Built-in implementations (T026-T030) can all run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "T011 Write unit test for Command execution in Tests/SwellTests/CommandTests.swift"
Task: "T012 Write integration test for binary execution in Tests/SwellIntegrationTests/ExecutionIntegrationTests.swift"

# Implementation:
Task: "T013 Implement Command execution using Foundation.Process in Sources/swell/Execution/Command.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1 (binary execution)
4. **STOP and VALIDATE**: Type `echo hello` in the shell, verify it works
5. Ship/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 (binary exec) → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 (pipes) → Test independently → Deploy/Demo
4. Add User Story 3 (redirection) → Test independently → Deploy/Demo
5. Add User Story 5 (builtins) → Test independently → Deploy/Demo
6. Add User Story 4 (prompt) → Test independently → Deploy/Demo

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (binary execution)
   - Developer B: User Story 4 (prompt — no dependency on US1-3)
3. After US1 completes:
   - Developer A: User Story 2 (pipes)
   - Developer B: User Story 5 (builtins — depends on US1's REPL)
4. After US2 completes:
   - Developer A: User Story 3 (redirection)
5. All stories integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
