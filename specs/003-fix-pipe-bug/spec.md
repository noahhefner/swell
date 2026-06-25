# Feature Specification: Fix Pipe Bug

**Feature Branch**: `003-fix-pipe-bug`

**Created**: 2026-06-25

**Status**: Draft

**Input**: User description: "Fix pipe bug where 'ls | grep AGENT' gives Bad file descriptor error"

## User Scenarios & Testing

### User Story 1 - Two-Stage Pipe Works Reliably (Priority: P1)

As a user, I want to pipe stdout from one command into stdin of another command using the `|` operator, so that I can chain programs together without intermediate files.

**Why this priority**: Piping is a core shell capability that was broken — no pipeline of any length worked, making the shell unusable for standard Unix workflows.

**Independent Test**: Can be tested by piping a known output into a known input consumer (e.g., `echo foo | wc -c`) and verifying the combined result.

**Acceptance Scenarios**:

1. **Given** the shell is running, **When** the user types `echo hello world | wc -w`, **Then** the shell outputs `2` without any error.
2. **Given** the shell is running, **When** the user types `ls | grep swell`, **Then** only lines containing "swell" are displayed, without any "Bad file descriptor" error.
3. **Given** the shell is running, **When** the user types `echo data | cat`, **Then** the shell outputs `data`.

---

### User Story 2 - Three-Stage Pipeline Works Reliably (Priority: P1)

As a user, I want to chain three or more commands together using pipes, so that I can build complex command pipelines.

**Why this priority**: Multi-stage pipelines are a common shell pattern that must work end-to-end.

**Independent Test**: Can be tested with a three-stage pipeline (e.g., `echo "a b c" | tr ' ' '\n' | wc -l`) and verifying the output.

**Acceptance Scenarios**:

1. **Given** the shell is running, **When** the user types `echo "hello world" | tr ' ' '\n' | wc -l`, **Then** the shell outputs `2`.
2. **Given** the shell is running, **When** the user types `ls /tmp | grep tmp | wc -l`, **Then** the shell outputs a non-negative integer without errors.

---

### Edge Cases

- What happens when a pipeline's first command produces no output (e.g., `echo -n "" | wc -c`)?
- What happens when a command in the middle of a pipeline fails?
- What happens when piping between built-in and external commands?
- What happens with a single-command pipeline (no pipe operator)?
- What happens when the last command in a pipeline produces stderr output?

## Requirements

### Functional Requirements

- **FR-001**: When executing a pipeline, each process in the pipeline MUST receive its stdin from the previous process's stdout (except the first) and send its stdout to the next process's stdin (except the last).
- **FR-002**: Pipe file descriptors MUST remain valid and open for the lifetime of all processes in the pipeline — no pipe end may be closed before the corresponding process has been spawned.
- **FR-003**: The last process in a pipeline MUST have its stdout captured via a pipe assigned BEFORE the process is launched, not after.
- **FR-004**: All pipe file descriptors in the parent process MUST be closed after all child processes have been launched to prevent resource leaks and ensure proper EOF signaling.
- **FR-005**: The shell MUST return the captured output of the last command in the pipeline to the caller.
- **FR-006**: The shell MUST NOT crash or produce "Bad file descriptor" errors when executing pipelines of any length (2+ stages).
- **FR-007**: Pipeline test coverage MUST be added for the shell's actual pipeline execution code path, not just manually-constructed Pipe objects.

### Key Entities

- **Pipe**: An OS-level unidirectional data channel connecting two processes, with a read end and a write end.
- **Pipeline**: An ordered sequence of commands connected by `|` operators, with data flowing from the first command's stdout to the last command's stdin through intermediate pipes.

## Success Criteria

### Measurable Outcomes

- **SC-001**: `echo hello world | wc -w` produces output `2` with exit code 0.
- **SC-002**: `ls | grep swell` produces the correct filtered output with no error messages on stderr.
- **SC-003**: A three-stage pipeline `echo "a b c" | tr ' ' '\n' | wc -l` produces the correct count.
- **SC-004**: All existing tests continue to pass after the fix is applied.
- **SC-005**: No "Bad file descriptor" errors appear in any pipeline execution.
- **SC-006**: A pipeline of 4 stages executes correctly (e.g., `echo foo | cat | cat | wc -c`).

## Assumptions

- The `Process` class from Foundation handles file descriptor inheritance correctly at `run()` time — file handles assigned before `run()` are properly duplicated into the child process.
- Pipes created by `Pipe()` are bidirectional OS pipes that support simultaneous reading and writing by different processes.
- The existing parser correctly tokenizes pipe operators and produces valid `ParsedPipeline` structures.
- The shell's single-command execution path (`executeExternal`) is already correct and does not need changes.
