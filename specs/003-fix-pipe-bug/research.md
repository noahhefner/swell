# Research: Fix Pipe Bug

## Overview

Investigation into why `ls | grep AGENT` produces "Bad file descriptor" errors in the swell shell.

## Root Cause Analysis

### Bug 1: `closeUnusedPipeHandles` closes read ends before child processes spawn

**Location**: `REPL.swift:253-262` (original), called at `REPL.swift:240` before `process.run()` at line 243.

**Mechanism**: For a pipeline of N commands, N-1 `Pipe` objects are created. Each pipe has a read end and write end. The `closeUnusedPipeHandles` method was intended to close the pipe handles that the current process doesn't need, but the logic was wrong:

- For the first process (index=0): `pipeIndex != -1` evaluated to `true` for all pipes, so ALL read ends were closed — including `pipes[0].fileHandleForReading` which the second process needs for its stdin.
- For the second process (index=1): `pipeIndex != 1` evaluated to `true` for pipe 0, closing `pipes[0].fileHandleForWriting` while the first process was still writing to it.

Since `close()` was called BEFORE `process.run()`, the underlying file descriptors were closed before Foundation's `Process` could duplicate them into the child process. When the second process attempted to read from its stdin (the now-closed read end), it got EBADF ("Bad file descriptor").

**Confirmation**: The error message `failed to launch grep: The operation could not be completed. Bad file descriptor` matched this diagnosis — the process failed at launch time because its stdin file descriptor was invalid.

### Bug 2: `collectPipelineOutput` assigns stdout pipe post-launch

**Location**: `REPL.swift:278-279` (original).

**Mechanism**: During pipeline launch (`launchPipelineProcess`), stdout was only assigned to pipes for non-last processes (`index < total - 1`). The last process's stdout was left unset (went to terminal). Then in `collectPipelineOutput`, a new `Pipe()` was created and assigned to `lastProcess.standardOutput` AFTER the process had already been launched and potentially completed. This assignment has no effect on an already-running or completed process, so output from the last command was never captured.

### Additional Issues Found

- `closePipeWriters` was a separate method called after all processes launched, but `closeUnusedPipeHandles` had already incorrectly closed some of the same handles before launch.
- `PipelineExecutor` in `Execution/Pipeline.swift` is entirely dead code — it duplicates the same buggy logic but is never referenced by the REPL.

## Fix Design

### Strategy

The correct approach for pipe management with Foundation's `Process`:

1. **Create all pipes upfront** — N-1 inter-process pipes plus one output pipe for the last process's stdout.
2. **Configure all processes** — Assign stdin/stdout from appropriate pipe file handles BEFORE calling `run()`.
3. **Launch all processes** — Each `process.run()` duplicates the file descriptors into the child process.
4. **Close parent copies** — After all processes are launched, close all pipe read and write ends in the parent. This prevents fd leaks and ensures proper EOF signaling (when child processes close their copies, the read ends get EOF).
5. **Collect output** — Read from the last process's stdout pipe after it exits.

### Changes

- **Removed** `closeUnusedPipeHandles` — called too early, closed fds needed by children.
- **Removed** `closePipeWriters` — replaced by the post-launch close-all loop.
- **Modified** `launchPipelineProcess` — added `outPipe` parameter; for the last process, set `process.standardOutput = outPipe.fileHandleForWriting`.
- **Modified** `executePipeline` — creates `outPipe` at pipeline start; after all processes launch, closes all pipe handles (read and write) including `outPipe`'s write end.
- **Modified** `collectPipelineOutput` — accepts `outPipe` parameter; reads from `outPipe.fileHandleForReading` after `waitUntilExit()` instead of creating a new pipe post-launch.

## Verification

- All 53 existing tests pass (including PipeIntegrationTests and ExecutionIntegrationTests).
- `echo hello world | wc -w` correctly outputs `2`.
- `ls | grep swell` correctly filters output without errors.
- Three-stage pipelines (`echo "a b c" | tr ' ' '\n' | wc -l`) work correctly.

## Alternatives Considered

- **posix_spawn with manual pipe/dup2**: Could avoid Foundation's `Process` entirely, but would require significant refactoring and lose the benefits of Foundation's process management. The bugs were in the usage pattern, not in Foundation itself.
- **Moving closeUnusedPipeHandles after run()**: Could make the existing logic work by just reordering, but the `closeUnusedPipeHandles` method had incorrect index logic that would still cause issues. Replacing with a simple close-all-loop is cleaner and more readable.
