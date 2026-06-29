# Tasks: Shell Command History

**Input**: Design documents from `specs/005-shell-command-history/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/input-contract.md

**Tests**: Tests are **REQUIRED** per Constitution Principle III (Testing Standards). Every feature MUST include unit and integration tests.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `Sources/swell/`, `Tests/` at repository root

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create directory structure and test scaffolding

- [x] T001 Create `LineEditor/` directory under `Sources/swell/LineEditor/`
- [x] T002 [P] Create test file stubs for unit tests at `Tests/SwellTests/CommandHistoryTests.swift` and integration tests at `Tests/SwellIntegrationTests/HistoryIntegrationTests.swift`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: CommandHistory data model shared by all user stories

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 [P] Implement `CommandHistory` struct in `Sources/swell/LineEditor/CommandHistory.swift` with `entries` array, optional `cursor`, and methods `add(_:)`, `moveUp()`, `moveDown()`, `current()` ✓

**Checkpoint**: Foundation ready - CommandHistory available for both US1 (LineEditor) and US2 (History builtin)

---

## Phase 3: User Story 1 - Arrow Key Navigation Through History (Priority: P1) 🎯 MVP

**Goal**: Users can press Up/Down arrows to browse through previous commands

**Independent Test**: Launch shell, run `echo a` then `echo b`, press Up (shows `echo b`), press Up again (shows `echo a`), press Down (shows `echo b`), press Down (empty prompt)

### Tests for User Story 1 (REQUIRED — see Constitution Principle III) ⚠️

- [x] T004 [P] [US1] Write unit tests for `CommandHistory` navigation logic (moveUp, moveDown, boundaries) in `Tests/SwellTests/CommandHistoryTests.swift`
- [x] T005 [P] [US1] Write unit tests for escape sequence detection in `Tests/SwellTests/CommandHistoryTests.swift`
- [x] T005b [P] [US1] Write unit test verifying that editing a recalled command and pressing Enter records the modified text as a new entry in `Tests/SwellTests/CommandHistoryTests.swift`
- [x] T005c [P] [US1] Write unit test verifying that pressing Up during active input replaces the input buffer with the history entry in `Tests/SwellTests/CommandHistoryTests.swift`

### Implementation for User Story 1

- [x] T006 [US1] Implement `LineEditor` struct in `Sources/swell/LineEditor/LineEditor.swift` with `readCommand()` method using POSIX termios raw mode
- [x] T007 [US1] Integrate `LineEditor` into REPL: replace `readLine()` in `Sources/swell/REPL.swift` with `LineEditor.readCommand()` and record non-empty commands in `CommandHistory`
- [x] T008 [US1] Add terminal state restoration on SIGINT/SIGTERM in signal handlers in `Sources/swell/SignalHandler.swift`

**Checkpoint**: Arrow key history navigation works in the shell

---

## Phase 4: User Story 2 - `history` Builtin Command (Priority: P1)

**Goal**: Users can run `history` to see a numbered list of all commands in the session

**Independent Test**: Run `echo a`, `echo b`, then `history` and verify output lists both commands with line numbers

### Tests for User Story 2 (REQUIRED — see Constitution Principle III) ⚠️

- [x] T009 [P] [US2] Write integration tests for `history` builtin output format and empty-history edge case in `Tests/SwellIntegrationTests/HistoryIntegrationTests.swift`

### Implementation for User Story 2

- [x] T010 [US2] Implement `History` builtin struct in `Sources/swell/Builtins/History.swift` with a static `execute(history: [String]) -> CommandResult` method that prints numbered entries
- [x] T011 [US2] Register `history` in the `executeBuiltin` switch in `Sources/swell/REPL.swift` and wire it to the shared `CommandHistory` instance

**Checkpoint**: `history` command lists all previous commands

---

## Phase 5: User Story 3 - History Includes All Command Types (Priority: P2)

**Goal**: All commands (builtins and external) are recorded; empty commands and `history` itself are excluded

**Independent Test**: Run `cd /tmp`, `ls`, an empty line, then `history` — verify both `cd /tmp` and `ls` appear but empty line does not, and `history` itself is absent

### Implementation for User Story 3

- [x] T012 [US3] Add empty/whitespace-only command filtering before recording in `Sources/swell/REPL.swift`
- [x] T013 [US3] Exclude the `history` command from being recorded in `Sources/swell/REPL.swift` (added after the filtered command is recorded, or skipped before recording)

**Checkpoint**: All command types properly recorded; empty and self-referencing entries excluded

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final verification and hardening

- [x] T014 [P] Run SwiftLint and fix any warnings across new files (SwiftLint not available, all builds clean)
- [x] T015 Run full test suite with `swift test` to verify no regressions (87 tests pass)
- [x] T016 Run `quickstart.md` validation scenarios manually to confirm end-to-end behavior (see below)
- [x] T017 Remove the `LineEditor` directory placeholder test files if not needed, or fill remaining test coverage gaps

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Foundational (CommandHistory) — no dependency on other stories
- **US2 (Phase 4)**: Depends on Foundational (CommandHistory) — independent of US1
- **US3 (Phase 5)**: Depends on both US1 (REPL integration for recording) and US2 (history builtin)
- **Polish (Phase 6)**: Depends on all user stories

### User Story Dependencies

- **US1 (P1)**: Can start after Foundational — no dependencies on other stories
- **US2 (P1)**: Can start after Foundational — no dependencies on other stories (operates on CommandHistory, which is shared)
- **US3 (P2)**: Depends on US1 (for the recording mechanism in REPL) and US2 (for the history builtin that displays results)

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Implementation tasks are sequential within each story

### Parallel Opportunities

- T001, T002: Can run in parallel (create directories + file stubs)
- T003, T004, T005: T004/T005 depend on T003, so sequential within the phase
- T006, T007, T008: Sequential within US1
- T009 can start once T003 is done (independent of US1)
- T010 can start once T003 is done (independent of US1)
- T012, T013: Sequential refinement of REPL

To maximize parallelism:
1. Complete Phase 1 + Phase 2
2. Assign US1 (Phase 3) and US2 (Phase 4) to different developers — they share CommandHistory but don't conflict on files
3. US3 (Phase 5) starts after both US1 and US2 are merged

---

## Parallel Example: User Story 1

```bash
# Tests first:
Task: "Write CommandHistory unit tests in Tests/SwellTests/CommandHistoryTests.swift"
Task: "Write escape sequence unit tests in Tests/SwellTests/CommandHistoryTests.swift"

# Implementation:
Task: "Implement LineEditor in Sources/swell/LineEditor/LineEditor.swift"
Task: "Integrate LineEditor into REPL in Sources/swell/REPL.swift"
Task: "Add terminal state restoration in Sources/swell/SignalHandler.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CommandHistory)
3. Complete Phase 3: User Story 1 (Arrow Key Navigation)
4. **STOP and VALIDATE**: Arrow keys cycle through history
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → CommandHistory data model ready
2. Add US1 (Arrow key nav) → Test independently → Deploy/Demo (MVP!)
3. Add US2 (History builtin) → Test independently → Deploy/Demo
4. Add US3 (All command types) → Test independently → Deploy/Demo

### Parallel Team Strategy

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: US1 (Phase 3)
   - Developer B: US2 (Phase 4)
3. After both merge: Developer C: US3 (Phase 5)
4. Team: Polish (Phase 6)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
