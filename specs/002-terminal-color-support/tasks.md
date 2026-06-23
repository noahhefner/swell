# Tasks: Terminal Color Support

**Input**: Design documents from `/specs/002-terminal-color-support/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests are REQUIRED per Constitution Principle III (Testing Standards). Every feature MUST include unit and integration tests.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Sources: `Sources/swell/`
- Tests: `Tests/SwellTests/` (unit), `Tests/SwellIntegrationTests/` (integration)

---

## Phase 1: Setup

**Purpose**: Create directory structure and test files for the color module

- [x] T001 Create `Sources/swell/Color/` directory

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core color infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T002 [P] Implement `ColorState` struct in `Sources/swell/Color/ColorState.swift` — resolved color state with `isEnabled: Bool` and `Sendable` conformance
- [x] T003 [P] Implement `ColorConfig` struct in `Sources/swell/Color/ColorConfig.swift` — hardcoded ANSI code constants (error red, reset) per data-model.md
- [x] T004 Implement `ColorResolver` in `Sources/swell/Color/ColorResolver.swift` — reads `NO_COLOR`, `CLICOLOR`, `CLICOLOR_FORCE`, `TERM` env vars, calls `isatty()` via Glibc/Darwin, applies resolution algorithm from data-model.md. Must be `Sendable`.

**Checkpoint**: Foundation ready — user story implementation can now begin in parallel

---

## Phase 3: User Story 1 + User Story 2 - Environment Variable Control (Priority: P1) 🎯 MVP

**Goal**: The shell respects `NO_COLOR`, `CLICOLOR`, `CLICOLOR_FORCE`, and `TERM` environment variables to control color output, and auto-disables color when not connected to a TTY.

**Independent Test**: Set `NO_COLOR=1` and pipe `echo "exit"` into the shell; verify output contains no ANSI escape sequences using `cat -v`.

### Tests (REQUIRED — see Constitution Principle III) ⚠️

- [x] T005 [P] [US1] Write unit test `testColorResolverNoColor` in `Tests/SwellTests/ColorTests.swift` — verify `ColorResolver` returns disabled when `NO_COLOR` is set
- [x] T006 [P] [US1] Write unit test `testColorResolverNoColorWins` — NO_COLOR overrides CLICOLOR_FORCE=1
- [x] T007 [P] [US1] Write unit test `testColorResolverTermDisabled` — TERM=dumb disables color
- [x] T008 [P] [US2] Write unit test `testColorResolverClicolor0` — CLICOLOR=0 disables color
- [x] T009 [P] [US2] Write unit test `testColorResolverClicolorForce` — CLICOLOR_FORCE=1 enables color even when not TTY
- [x] T010 [P] [US2] Write unit test `testColorResolverTtyAutoDisable` — non-TTY fd disables color
- [x] T011 [P] [US2] Write integration test `testNoColorPipe` in `Tests/SwellIntegrationTests/ColorIntegrationTests.swift` — NO_COLOR=1 piped output has no ANSI codes
- [x] T012 [P] [US2] Write integration test `testClolorForcePipe` — CLICOLOR_FORCE=1 enables ANSI in piped output

### Implementation

- [x] T013 [US1+US2] Wire `ColorResolver` into `Sources/swell/REPL.swift` — replace stub `useColorOutput()` with full resolver logic

**Checkpoint**: At this point, US1 and US2 should be fully functional and testable independently

---

## Phase 4: User Story 3 - Colorized Prompt (Priority: P2)

**Goal**: Prompt templates can include `\[\e[<code>m\]` color escape sequences that render as ANSI color when color is enabled.

**Independent Test**: Configure prompt with `\[\e[31m\]test\[\e[0m\]$ ` and verify the rendered output contains `\e[31m` and `\e[0m` sequences (when color enabled) or plain text (when disabled).

### Tests (REQUIRED — see Constitution Principle III) ⚠️

- [x] T014 [P] [US3] Write unit test `testPromptColorEscapeEnabled` in `Tests/SwellTests/ColorTests.swift` — prompt with `\[\e[31m\]dir\[\e[0m\]` renders ANSI codes when color enabled
- [x] T015 [P] [US3] Write unit test `testPromptColorEscapeDisabled` — same prompt renders plain text when color disabled

### Implementation

- [x] T016 [US3] Update `Sources/swell/Prompt/PromptRenderer.swift` — parse `\[`/`\]` markers, pass through `\e` escape sequences when color enabled, strip when disabled

**Checkpoint**: Prompt color escapes work independently

---

## Phase 5: User Story 4 - Colorized Error Messages (Priority: P2)

**Goal**: Shell error messages (command not found, parse errors, etc.) display in red on stderr when color is enabled.

**Independent Test**: Run a nonexistent command in the shell with color enabled and verify stderr contains `\e[31m` prefix.

### Tests (REQUIRED — see Constitution Principle III) ⚠️

- [x] T017 [P] [US4] Write integration test `testErrorColorEnabled` in `Tests/SwellIntegrationTests/ColorIntegrationTests.swift` — error message in red when color enabled
- [x] T018 [P] [US4] Write integration test `testErrorColorDisabled` — error message plain when NO_COLOR set

### Implementation

- [x] T019 [US4] Update `Sources/swell/REPL.swift` — wrap failure error output in red ANSI codes when color is enabled

**Checkpoint**: Error colorization works independently

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Cleanup, documentation, and final validation

- [x] T020 [P] Remove dead `useColorOutput()` stub from `Sources/swell/REPL.swift` (replaced by ColorResolver)
- [x] T021 [P] Run `swift test` and confirm all 38+ existing tests pass plus new color tests
- [x] T022 [P] Run quickstart.md validation scenarios
- [x] T023 [P] Run `swiftlint` on all modified files (not available — skipped)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **US1+US2 (Phase 3)**: Depends on Foundational completion
- **US3 (Phase 4)**: Depends on Foundational completion (ColorResolver for color enable/disable)
- **US4 (Phase 5)**: Depends on Foundational completion (ColorResolver for color enable/disable)
- **Polish (Phase 6)**: Depends on all user story phases being complete

### User Story Dependencies

- **US1+US2 (P1)**: Can start after Foundational — No dependencies on other stories
- **US3 (P2)**: Can start after Foundational — Independently testable
- **US4 (P2)**: Can start after Foundational — Independently testable
- US3 and US4 can proceed in PARALLEL

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Implementation follows tests

### Parallel Opportunities

- All Phase 2 [P] tasks (T002, T003) — ColorState and ColorConfig in parallel
- All Phase 3 [P] tests (T005-T012) — all color resolver tests in parallel
- Phase 4 (US3) and Phase 5 (US4) — can run in PARALLEL after Foundational complete
- All Phase 6 [P] tasks (T020-T023) — in parallel

---

## Parallel Example: Foundational Phase

```bash
# Launch ColorState and ColorConfig in parallel:
Task: "Implement ColorState in Sources/swell/Color/ColorState.swift"
Task: "Implement ColorConfig in Sources/swell/Color/ColorConfig.swift"
```

## Parallel Example: US3 + US4 (after Foundational)

```bash
# Prompt color escapes (US3) and error colors (US4) in parallel:
Task: "Update PromptRenderer for color escapes in Sources/swell/Prompt/PromptRenderer.swift"
Task: "Wire error colors in Sources/swell/REPL.swift"
```

---

## Implementation Strategy

### MVP First (US1+US2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: US1+US2 (env var control)
4. **STOP and VALIDATE**: Test US1+US2 independently
5. Quickstart validation

### Incremental Delivery

1. Complete Setup + Foundational → Color module ready
2. Add US1+US2 → Env var color control → Deploy/Demo (MVP!)
3. Add US3 → Prompt color escapes → Deploy/Demo
4. Add US4 → Error message colors → Deploy/Demo
5. Each story adds value without breaking previous stories

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
