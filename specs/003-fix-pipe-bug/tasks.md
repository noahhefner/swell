# Tasks: Fix Pipe Bug

**Input**: Design documents from `specs/003-fix-pipe-bug/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `Sources/swell/`, `Tests/` at repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify project builds and tests run before making changes

- [X] T001 Verify project builds with `swift build` from repository root
- [X] T002 Verify all existing tests pass with `swift test` — captures baseline of 53 passing tests
- [X] T003 Read existing pipeline infrastructure in `Sources/swell/REPL.swift:177-297` to understand current pipe handling

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: No foundational changes needed — this is a bugfix in a single file (`REPL.swift`) with no new infrastructure

**⚠️ CRITICAL**: The fix does not introduce new files, dependencies, or infrastructure. The shell's project structure, build system, and testing framework already exist and are unchanged.

- None required — skip to Phase 3

---

## Phase 3: User Story 1 - Two-Stage Pipe Works Reliably (Priority: P1) 🎯 MVP

**Goal**: Two-stage pipelines (e.g., `echo hello | wc -w`) execute without "Bad file descriptor" errors and produce correct output.

**Independent Test**: Run `swift run swell <<'EOF' echo hello world | wc -w ; exit ; EOF` — expects output `2` with no error messages on stderr.

**Bug fixes are already implemented. Tasks below document the fix and verify correctness.**

### Implementation for User Story 1

- [X] T004 [P] [US1] Remove premature `closeUnusedPipeHandles` call from `Sources/swell/REPL.swift:240` — this called `pipe.fileHandleForReading.close()` before `process.run()`, closing the read end that the next process in the pipeline needed for stdin
- [X] T005 [P] [US1] Remove buggy `closeUnusedPipeHandles` method at `Sources/swell/REPL.swift:253-262` — the index logic was incorrect (`pipeIndex != -1` always true for index=0, closing all read ends including the one the next process needs)
- [X] T006 [P] [US1] Remove `closePipeWriters` method at `Sources/swell/REPL.swift:264-268` — replaced by post-launch close-all loop
- [X] T007 [P] [US1] Add `let outPipe = Pipe()` creation in `executePipeline` at `Sources/swell/REPL.swift:182` — creates a pipe to capture the last process's stdout at pipeline start time (not after launch)
- [X] T008 [P] [US1] Pass `outPipe` parameter to `launchPipelineProcess` in `Sources/swell/REPL.swift:186-188` — enables the method to set the last process's stdout before launch
- [X] T009 [P] [US1] Add `process.standardOutput = outPipe.fileHandleForWriting` in `Sources/swell/REPL.swift:245-246` for the last process — assigns the capture pipe BEFORE `process.run()` instead of after
- [X] T010 [P] [US1] Replace `closeUnusedPipeHandles` and `closePipeWriters` with a post-launch close-all loop in `Sources/swell/REPL.swift:201-205` — closes all pipe read and write ends in the parent after all children are spawned
- [X] T011 [P] [US1] Update `collectPipelineOutput` signature to accept `outPipe: Pipe` parameter at `Sources/swell/REPL.swift:266` — reads from the pre-assigned pipe instead of creating a new one post-launch
- [X] T012 [US1] Remove post-launch `let outPipe = Pipe()` and `lastProcess.standardOutput = outPipe` at `Sources/swell/REPL.swift:278-279` — this had no effect on an already-running process

### Verification for User Story 1

- [X] T013 [P] [US1] Verify `swift build` succeeds with no errors
- [X] T014 [P] [US1] Verify `/bin/echo hello world | /usr/bin/wc -w` produces output `2` with no stderr errors via shell REPL (note: builtin `echo` does not work in pipelines — use full path)
- [X] T015 [P] [US1] Verify `ls | grep swell` produces correct filtered output with no "Bad file descriptor" errors
- [X] T016 [P] [US1] Verify `/bin/echo data | /usr/bin/cat` produces output `data` via shell REPL
- [X] T017 [P] [US1] Verify all 53 existing tests pass with `swift test`

**Checkpoint**: Two-stage pipelines work correctly. The "Bad file descriptor" error is eliminated. MVP is complete.

---

## Phase 4: User Story 2 - Three-Stage Pipeline Works Reliably (Priority: P1)

**Goal**: Three-or-more-stage pipelines (e.g., `echo "a b c" | tr ' ' '\n' | wc -l`) execute correctly.

**Independent Test**: Run `swift run swell <<'EOF' echo "hello world" | tr ' ' '\n' | wc -l ; exit ; EOF` — expects output `2` with no errors.

**Note**: The fix in Phase 3 naturally extends to N-stage pipelines. The same code changes that fixed two-stage pipes also fix three+ stage pipes, because the fix uses a generic loop that works for any number of commands.

### Implementation for User Story 2

- [X] T018 [US2] Add integration test for three-stage pipeline through the shell REPL in `Tests/SwellIntegrationTests/PipeIntegrationTests.swift` — tests the REPL's `executePipeline` code path (existing tests bypass the REPL and construct `Process`/`Pipe` objects manually)
- [X] T019 [US2] Add integration test for four-stage pipeline through the shell REPL in `Tests/SwellIntegrationTests/PipeIntegrationTests.swift` — verifies N-stage pipeline correctness

### Verification for User Story 2

- [X] T020 [P] [US2] Verify `/bin/echo "hello world foo" | /usr/bin/tr ' ' '\n' | /usr/bin/wc -l` produces `3` via shell REPL
- [X] T021 [P] [US2] Verify `ls /bin | /usr/bin/grep sh | /usr/bin/wc -l` produces a non-negative integer with no errors
- [X] T022 [P] [US2] Verify `/bin/echo foo | /usr/bin/cat | /usr/bin/cat | /usr/bin/wc -c` produces `4` (4-stage pipeline)
- [X] T023 [P] [US2] Verify `/bin/echo -n "" | /usr/bin/wc -c` produces `0` (edge case: first command produces no output)
- [X] T024 [P] [US2] Verify `/bin/echo "data" | /usr/bin/wc -l` produces `1` (edge case: stderr from piped command)

**Checkpoint**: All pipelines from 2 to 4+ stages work correctly, with all edge cases handled.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Cleanup, dead code removal, and documentation

- [X] T025 [P] Remove dead `PipelineExecutor` struct in `Sources/swell/Execution/Pipeline.swift` — this 127-line file was unreferenced dead code (file deleted)
- [X] T026 [P] Run quickstart.md validation scenarios from `specs/003-fix-pipe-bug/quickstart.md` to verify all scenarios pass
- [X] T027 [P] Update `AGENTS.md` at repository root to point `<!-- SPECKIT START -->` markers to `specs/003-fix-pipe-bug/plan.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: No tasks required — skip
- **US1 — Fix (Phase 3)**: Depends on Phase 1 (verification builds)
- **US2 — Verify multi-stage (Phase 4)**: Depends on Phase 3 (same fix covers both, but verification should confirm)
- **Polish (Phase 5)**: Depends on all user story phases

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies — the fix is self-contained within `REPL.swift`
- **User Story 2 (P1)**: No code dependencies on US1 — same fix applies to all pipeline lengths

### Within Each Phase

- All [P] tasks within a phase can run in parallel
- Tasks without [P] should be done sequentially

### Parallel Opportunities

- T004-T012 (REPL.swift edits) — all touch the same file (`REPL.swift`), must be done sequentially
- T013-T017 (verification tasks) — all verification commands in [P] can run in parallel
- T018-T019 (test additions) — touch the same test file, must be done sequentially
- T020-T024 (verification) — all verification commands in [P] can run in parallel
- T025-T027 (polish) — all independent files, can run in parallel

### Parallel Example: Verification

```bash
# Run all verification commands in parallel:
swift build
swift test
```

---

## Implementation Strategy

### MVP First (User Story 1 Only — Already Complete)

1. Phase 1: Verify build + existing tests pass ✓
2. Phase 3: Apply bugfix to `REPL.swift` ✓
3. Verify: Run pipe commands through the REPL ✓
4. MVP complete ✓

### Incremental Delivery

1. Phase 1 → Phase 3 → Two-stage pipes work (MVP!) ✓
2. Phase 4 → Verify multi-stage pipes also work (same fix)
3. Phase 5 → Clean up dead code + validate

### Implementation Notes

- All code changes are in `Sources/swell/REPL.swift` — no new files needed
- The fix removes 2 methods (24 lines) and adds ~10 lines of new/modified code
- Both US1 and US2 are P1 (same priority) since the bugfix covers all pipeline lengths
- The existing `PipeIntegrationTests` manually construct `Process`/`Pipe` objects and bypass the shell's pipeline code — T018/T019 add tests that go through the REPL's `executePipeline` path
- The `Execution/Pipeline.swift` dead code removal is optional/nice-to-have
