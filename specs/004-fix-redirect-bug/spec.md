# Feature Specification: Fix Redirect Bug

**Feature Branch**: `004-fix-redirect-bug`

**Created**: 2026-06-25

**Status**: Draft

**Input**: User description: "Fix io redirects (> >> 2>) not working — output goes to terminal instead of files"

## User Scenarios & Testing

### User Story 1 - Stdout Redirect with `>` (Priority: P1)

As a user, I want to redirect the stdout of a command to a file using the `>` operator, so that I can save command output without manually copying from the terminal.

**Why this priority**: File redirection is a core shell feature that was broken — no redirect of any kind works, making the shell unable to save command output to files.

**Independent Test**: Can be tested by running `echo hello > /tmp/test.txt` and verifying the file is created with the expected content.

**Acceptance Scenarios**:

1. **Given** the shell is running, **When** the user types `echo hello world > /tmp/test.txt`, **Then** the file `/tmp/test.txt` is created containing `hello world\n`.
2. **Given** the shell is running, **When** the user types `ls > /tmp/ls-output.txt`, **Then** the file `/tmp/ls-output.txt` is created containing the output of the `ls` command.
3. **Given** a file already exists, **When** the user types `echo new content > /tmp/existing.txt`, **Then** the file is overwritten with the new content (old content is lost).
4. **Given** the target path is not writable (e.g., `/root/out.txt` when running as non-root), **When** the user attempts to redirect to it, **Then** an error message is displayed and the shell continues.

---

### User Story 2 - Stdout Append with `>>` (Priority: P1)

As a user, I want to append command output to an existing file using the `>>` operator, so that I can accumulate logs and results over multiple commands.

**Why this priority**: Append redirection is a common pattern for logging and data collection. Same priority as overwrite redirect since both are expected to work together.

**Independent Test**: Can be tested by running two commands with `>>` to the same file and verifying the file contains both outputs.

**Acceptance Scenarios**:

1. **Given** a file `/tmp/log.txt` already exists with content `line1\n`, **When** the user types `echo line2 >> /tmp/log.txt`, **Then** the file contains `line1\nline2\n`.
2. **Given** a file does not exist yet, **When** the user types `echo first >> /tmp/new.txt`, **Then** the file is created with content `first\n`.
3. **Given** the target path is not writable, **When** the user attempts to append to it, **Then** an error message is displayed.

---

### User Story 3 - Stderr Redirect with `2>` and `2>>` (Priority: P1)

As a user, I want to redirect stderr output to a file separately from stdout, so that I can capture error messages and diagnostic output for debugging.

**Why this priority**: Stderr redirection is essential for debugging and log analysis. Same priority as stdout redirects.

**Independent Test**: Can be tested by running a command that produces stderr output with `2>` redirect and verifying the error text appears in the file.

**Acceptance Scenarios**:

1. **Given** the shell is running, **When** the user types `ls /nonexistent 2> /tmp/err.txt`, **Then** the error message from `ls` is written to `/tmp/err.txt` instead of the terminal.
2. **Given** `/tmp/err.log` exists with content, **When** the user types `ls /nonexistent 2>> /tmp/err.log`, **Then** the error message is appended to the file.
3. **Given** stdout is also redirected, **When** the user types `echo output 2> /tmp/stderr.txt`, **Then** stdout goes to terminal and stderr goes to the file (or both can be separate).

---

### Edge Cases

- What happens when `>` redirect target is a directory instead of a file?
- What happens when redirecting to `/dev/null`?
- What happens when both `>` and `2>` are used in the same command?
- What happens when a redirect is used in a pipeline (e.g., `ls | grep foo > out.txt`)?
- What happens when the redirect file path contains spaces (quoted)?
- What happens when the file system is full?
- What happens with `>>` to a file that is a symbolic link?
- What happens when both stdout and stderr redirect to the same file?

## Requirements

### Functional Requirements

- **FR-001**: The `>` operator MUST redirect stdout of the command to the specified file, creating or overwriting the file.
- **FR-002**: The `>>` operator MUST redirect stdout of the command to the specified file, creating or appending to the file.
- **FR-003**: The `2>` operator MUST redirect stderr of the command to the specified file, creating or overwriting the file.
- **FR-004**: The `2>>` operator MUST redirect stderr of the command to the specified file, creating or appending to the file.
- **FR-005**: If the specified redirect path is not writable, the shell MUST display an error message in format `error: cannot open <path> for writing: <reason>\n` on stderr and continue.
- **FR-006**: If the specified redirect path does not exist and the parent directory is writable, the shell MUST create the file.
- **FR-007**: Redirects MUST work with both built-in commands (e.g., `echo`) and external commands (e.g., `ls`).
- **FR-008**: When both stdout and stderr redirects are specified in the same command, both MUST be respected.
- **FR-009**: Redirects MUST work in pipeline commands (e.g., `ls | grep foo > out.txt`), redirecting the output of the last command in the pipeline.
- **FR-010**: The shell's single-command execution path MUST read the `stdoutRedirect` and `stderrRedirect` fields from `ParsedCommand` and apply them.
- **FR-011**: The shell's pipeline execution path MUST read the `stdoutRedirect` and `stderrRedirect` fields from the last `ParsedCommand` in the pipeline and apply them.

### Key Entities

- **Redirect Target**: A specification of a file path and a mode (overwrite or append) that describes where a command's output should be directed. Stored as `stdoutRedirect` and `stderrRedirect` on each `ParsedCommand`.
- **Redirection Operator**: A syntactic element (`>`, `>>`, `2>`, `2>>`) that precedes a file path in the command line and determines the redirect mode.
- **Redirect File Handle**: An open file handle to the target file, created by opening the file in overwrite or append mode, that can be assigned to a process's `standardOutput` or `standardError`.

## Success Criteria

### Measurable Outcomes

- **SC-001**: `echo hello > /tmp/test.txt` creates a file containing `hello` — verified by reading the file.
- **SC-002**: `echo line1 > /tmp/test.txt ; echo line2 >> /tmp/test.txt` results in a file with both lines.
- **SC-003**: `ls /nonexistent 2> /tmp/err.txt` results in the error message being written to the file and not appearing on the terminal.
- **SC-004**: All existing tests continue to pass after the fix is applied.
- **SC-005**: A command with both stdout and stderr redirects (e.g., `cmd 2>err.txt >out.txt`) produces both files with correct content.
- **SC-006**: A pipeline with a redirect at the end (e.g., `ls | grep foo > out.txt`) correctly writes the filtered output to the file.

## Assumptions

- The redirect target file paths are relative to the shell's current working directory (not the binary's location).
- The file system supports standard POSIX file operations (create, write, append).
- The parser already correctly parses redirect operators and stores them in `ParsedCommand.stdoutRedirect` and `ParsedCommand.stderrRedirect` (type `RedirectTarget?`) — only the execution side needs fixing.
- The `Redirection` helper struct (`Redirection.swift`) already provides correct `FileHandle` creation for overwrite and append modes — it just needs to be called.
- When redirecting in a pipeline, the redirect applies to the last command in the pipeline (consistent with bash behavior).
