---

description: "Task list for fixing IO redirect bug in swell shell"

---

# Tasks: Fix Redirect Bug

**Input**: Design documents from `specs/004-fix-redirect-bug/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/, quickstart.md

**Tests**: Tests are **REQUIRED** per Constitution Principle III (Testing Standards). Write failing tests first, then implement.

**Organization**: Tasks are grouped by user story. All three user stories are P1 and share the same execution code paths — they are implemented together in one phase.

**Key types** (verified from source):
- `RedirectTarget` enum: `.overwrite(String)` and `.append(String)` — associated value is file path
- `ParsedCommand.stdoutRedirect: RedirectTarget?` and `stderrRedirect: RedirectTarget?`
- `Redirection.openForOverwrite(path)` / `Redirection.openForAppend(path)` — returns `FileHandle`

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Sources/swell/** — Production code (single project layout)
- **Tests/SwellIntegrationTests/** — Integration tests (REPL-level)
- **Tests/SwellTests/** — Unit tests

---

## Phase 1: Setup

**Purpose**: Baseline verification — existing tests must pass before making changes

**⚠️ CRITICAL**: Confirm current state before any changes

- [x] T001 Run `swift test` to confirm all 57 existing tests pass as baseline

**Checkpoint**: Baseline confirmed — 57 tests pass

---

## Phase 2: Foundational — Write Failing Tests First (TDD)

**Purpose**: Integration tests for all redirect types, written before implementation per Constitution §III. These tests call `REPL.execute(_:)` directly and will initially fail.

**⚠️ CRITICAL**: All tests in this phase MUST fail when run before implementation

### Tests for Redirect (all user stories)

- [x] T002 [P] [US1] Write test `testStdoutOverwriteRedirect` — `echo hello > /tmp/test.txt` creates file with content — in `Tests/SwellIntegrationTests/RedirectionIntegrationTests.swift`
- [x] T003 [P] [US2] Write test `testStdoutAppendRedirect` — echo line1 then line2 to same file via `>>` — in `Tests/SwellIntegrationTests/RedirectionIntegrationTests.swift`
- [x] T004 [P] [US3] Write test `testStderrOverwriteRedirect` — `ls /nonexistent 2> /tmp/err.txt` captures stderr — in `Tests/SwellIntegrationTests/RedirectionIntegrationTests.swift`
- [x] T005 [P] [US3] Write test `testStderrAppendRedirect` — stderr append via `2>>` — in `Tests/SwellIntegrationTests/RedirectionIntegrationTests.swift`
- [x] T006 [US3] Write test `testBothStdoutAndStderrRedirect` — both `>` and `2>` in same command — in `Tests/SwellIntegrationTests/RedirectionIntegrationTests.swift`
- [x] T007 [US1] Write test `testPipelineWithRedirect` — `ls | grep foo > out.txt` — in `Tests/SwellIntegrationTests/RedirectionIntegrationTests.swift`
- [x] T008 [US1] Write test `testRedirectUnwritablePath` — redirect to unwritable path returns error — in `Tests/SwellIntegrationTests/RedirectionIntegrationTests.swift`
- [x] T009 [US1] Write test `testExternalCommandStdoutRedirect` — `/bin/echo hello > /tmp/out.txt` for external cmd path — in `Tests/SwellIntegrationTests/RedirectionIntegrationTests.swift`
- [x] T010 [P] [US1] Write test `testStdoutRedirectCreatesNewFile` — redirect to non-existent path creates the file (FR-006) — in `Tests/SwellIntegrationTests/RedirectionIntegrationTests.swift`

**Checkpoint**: `swift test` shows 9+ failing tests (confirming TDD readiness)

---

## Phase 3: User Stories 1+2+3 — All Redirect Types (Priority: P1)

**Goal**: Fix execution to respect stdout and stderr redirects for all four operator types (`>`, `>>`, `2>`, `2>>`), for builtins, external commands, and pipelines

**Independent Test**: T002-T010 pass (REPL-level integration tests)

### Implementation

- [x] T011 [US1] In `Sources/swell/REPL.swift`, modify `executeSingle` to read `command.stdoutRedirect` and `command.stderrRedirect` — open file handles via `Redirection.openForOverwrite`/`openForAppend` and pass as `stdoutDest`/`stderrDest` to `executeExternal`
- [x] T012 [US1] In `Sources/swell/REPL.swift`, modify `executeExternal` to skip creating output `Pipe` when `stdoutDest` is non-nil (and similarly for `stderrDest`) — the process writes directly to the file handle
- [x] T013 [US1] In `Sources/swell/REPL.swift`, modify `executeSingle` to handle builtin stdout redirect: after builtin returns `.success(output:)`, if `stdoutRedirect` exists, write output string to file and return `.success(output: "")`
- [x] T014 [US3] In `Sources/swell/REPL.swift`, modify `executeSingle` to also pass `stderrDest` to `executeExternal` when `stderrRedirect` is set (handles both `.overwrite` and `.append` modes)
- [x] T015 [US1] In `Sources/swell/REPL.swift`, modify `launchPipelineProcess` to check last command's `stdoutRedirect`/`stderrRedirect`: if set, open file handle and assign to `process.standardOutput`/`standardError` instead of the output pipe
- [x] T016 [US1] In `Sources/swell/REPL.swift`, modify `collectPipelineOutput` to skip reading from `outPipe` when last command had a stdout redirect — return `.success(output: "")`

**Checkpoint**: `swift test` passes all tests (57 existing + 9+ new redirect tests)

---

## Phase 4: Edge Cases & Polish

**Purpose**: Handle edge cases from spec, clean up, and verify

- [x] T017 [US1] Handle error case in `executeSingle`: if `Redirection.openForOverwrite`/`openForAppend` throws, return `.failure(error:, exitCode: 1)` with descriptive message — in `Sources/swell/REPL.swift`
- [x] T018 Write edge-case tests for redirect to directory, `/dev/null`, and other special paths — in `Tests/SwellIntegrationTests/RedirectionIntegrationTests.swift`
- [x] T019 Run `swift test` to confirm all tests pass (57 original + all new redirect tests)
- [x] T020 Run `swift format` and `swiftlint` to ensure clean formatting and zero lint warnings
- [x] T021 Verify all scenarios in `specs/004-fix-redirect-bug/quickstart.md` pass end-to-end

**Checkpoint**: All tests pass, lint clean, quickstart scenarios verified

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — baseline test pass
- **Foundational (Phase 2)**: Depends on Phase 1 — write failing tests BEFORE implementation
- **Implementation (Phase 3)**: Depends on Phase 2 — tests exist to validate against
- **Polish (Phase 4)**: Depends on Phase 3 — implementation must be complete

### Within Phase 3 (Implementation)

- T011 (executeSingle: open files) must precede T012 (executeExternal: use them)
- T011 must precede T013 (builtin redirect) — both modify executeSingle
- T014 (stderr in executeSingle) depends on T011
- T015 (pipeline redirect) and T016 (collectPipelineOutput) depend on T011/T012 pattern

### Parallel Opportunities

- T002-T010 (all tests in Phase 2) can be written in parallel — they are in the same file but independent test cases
- T017 (error handling) can be done in parallel with T015/T016
- T018 (edge case tests) can be done in parallel with T017
- T019, T020, T021 (verification) must be sequential and final

---

## Parallel Example: Phase 2 (Tests)

```bash
# All integration test tasks can be written in parallel:
Task: "Write testStdoutOverwriteRedirect in Tests/SwellIntegrationTests/RedirectionIntegrationTests.swift"
Task: "Write testStdoutAppendRedirect in Tests/SwellIntegrationTests/RedirectionIntegrationTests.swift"
Task: "Write testStderrOverwriteRedirect in Tests/SwellIntegrationTests/RedirectionIntegrationTests.swift"
Task: "Write testStderrAppendRedirect in Tests/SwellIntegrationTests/RedirectionIntegrationTests.swift"
```

## Parallel Example: Phase 3 (Implementation)

```bash
# T011 and T012 must be sequential (T011 → T012), but T015/T016 (pipeline) can be done in parallel:
Task: "T011+T012: Modify executeSingle and executeExternal in Sources/swell/REPL.swift"
Task: "T015+T016: Modify launchPipelineProcess and collectPipelineOutput in Sources/swell/REPL.swift"
```

---

## Implementation Strategy

### MVP Scope (Tasks T011-T013 only)

1. Phase 1: Verify baseline
2. Phase 2: Write tests
3. Phase 3, Tasks T011-T013: Stdout overwrite for builtins and external commands (the most common use case)
4. STOP and VALIDATE: `echo hello > /tmp/test.txt` works, all tests pass
5. If ready, proceed with remaining tasks

### Full Implementation

1. Phase 1: Baseline confirmation
2. Phase 2: All 9 redirect tests written and failing
3. Phase 3 (T011-T014): Stdout + stderr for single commands (covers `>`, `>>`, `2>`, `2>>`)
4. Phase 3 (T015-T016): Pipeline redirect support
5. Phase 4: Edge cases, cleanup, verification
6. Each step is independently testable via the Phase 2 tests

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story (US1=stdout overwrite, US2=stdout append, US3=stderr)
- All three user stories are P1 and share execution code paths
- Tests use `REPL.execute(_:)` which is `internal` — `@testable import swell` provides access
- `RedirectTarget` is an enum with associated values: `.overwrite(path)` / `.append(path)`
- The `Redirection` struct in `Sources/swell/Execution/Redirection.swift` provides `openForOverwrite` and `openForAppend`
- parser arguments already exclude redirect operators and filenames — no parser changes needed
