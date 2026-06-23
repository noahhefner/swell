# Feature Specification: Swift Linux Shell

**Feature Branch**: `001-swift-linux-shell`

**Created**: 2026-06-23

**Status**: Draft

**Input**: User description: "Build a linux shell (like bash or fish) using the Swift programming language. The shell should support basic operations like executing binaries, piping output from one command to input of another command, and file append / replace with carrots. The shell should support customizable prompts."

## User Scenarios & Testing *(mandatory — see Constitution Principle III)*

### User Story 1 - Execute an External Binary (Priority: P1)

As a user, I want to type a command and have the shell find and execute the corresponding binary on my PATH, so that I can run programs from the shell.

**Why this priority**: Binary execution is the most fundamental operation of any shell — nothing else works without it.

**Independent Test**: Can be fully tested by invoking a known binary (e.g., `ls`, `echo`) and verifying the output appears on stdout.

**Acceptance Scenarios**:

1. **Given** the shell is running, **When** the user types `echo hello`, **Then** the shell outputs `hello` to stdout and returns a zero exit code.
2. **Given** the shell is running, **When** the user types `nonexistent_command`, **Then** the shell outputs an error message to stderr and returns a non-zero exit code.
3. **Given** the shell is running, **When** the user types a command with arguments (e.g., `ls -la /tmp`), **Then** the shell passes all arguments to the binary correctly.

---

### User Story 2 - Pipe Output Between Commands (Priority: P1)

As a user, I want to pipe stdout from one command into stdin of another command using the `|` operator, so that I can chain programs together without intermediate files.

**Why this priority**: Piping is a core shell capability required for composing command-line workflows. Same priority as binary execution since both are needed for a usable shell.

**Independent Test**: Can be tested by piping a known output into a known input consumer (e.g., `echo foo | wc -c`) and verifying the combined result.

**Acceptance Scenarios**:

1. **Given** the shell is running, **When** the user types `echo hello world | wc -w`, **Then** the shell outputs `2`.
2. **Given** the shell is running, **When** the user types `ls /tmp | grep temp`, **Then** only lines containing "temp" from the `ls` output are displayed.
3. **Given** the shell is running, **When** the user types a pipeline with more than two stages (e.g., `cat /etc/passwd | grep root | wc -l`), **Then** all stages execute in sequence with correct data flow.

---

### User Story 3 - File Redirection (Priority: P1)

As a user, I want to redirect command output to files using `>` (overwrite) and `>>` (append) operators, so that I can save command results without extra copy-paste steps.

**Why this priority**: File redirection is a basic shell feature that users expect from day one. Same priority as execution and piping.

**Independent Test**: Can be tested by running a command with `>` or `>>` and checking that the target file contains the expected content.

**Acceptance Scenarios**:

1. **Given** the shell is running, **When** the user types `echo data > /tmp/test.txt`, **Then** the file `/tmp/test.txt` is created (or overwritten) containing `data\n`.
2. **Given** a file `/tmp/log.txt` already exists with content, **When** the user types `echo more >> /tmp/log.txt`, **Then** the string `more` is appended to the file on a new line.
3. **Given** the shell is running, **When** the user types `echo hello > /tmp/out.txt | wc` (redirect with pipe), **Then** stdout goes to the file and the pipe receives no input (or re-dead behavior follows POSIX conventions).

---

### User Story 4 - Customizable Prompt (Priority: P2)

As a user, I want to customize the shell prompt (PS1 equivalent) to show useful information such as the current directory, user name, hostname, or a custom string, so that the shell adapts to my workflow preferences.

**Why this priority**: Prompt customization is important for usability but not essential for basic shell functionality.

**Independent Test**: Can be tested by configuring a prompt template and verifying the displayed prompt matches the expected rendered output.

**Acceptance Scenarios**:

1. **Given** the shell prompt is configured to show `\u@\h:\w$`, **When** the shell displays its prompt, **Then** the prompt shows the current user, hostname, and working directory (e.g., `alice@myhost:/home/alice$`).
2. **Given** the prompt is configured as a static string `myshell> `, **When** the shell displays its prompt, **Then** the prompt shows exactly `myshell> `.
3. **Given** the user changes the prompt configuration while the shell is running, **When** the shell refreshes the prompt (e.g., after the next command completes), **Then** the new prompt format is used.

---

### User Story 5 - Built-in Commands (Priority: P2)

As a user, I want to use built-in commands (`cd`, `pwd`, `exit`, `export`, `echo`) so that I can navigate the filesystem, set environment variables, and control the shell session without external binaries.

**Why this priority**: Built-ins are essential for day-to-day shell use but not strictly required for the MVP of executing external binaries with pipes and redirections.

**Independent Test**: Can be tested by invoking each built-in and verifying its effect (e.g., `cd /tmp` then `pwd` outputs `/tmp`).

**Acceptance Scenarios**:

1. **Given** the shell is running, **When** the user types `cd /tmp`, **Then** the shell's current working directory changes to `/tmp`.
2. **Given** the shell is running, **When** the user types `pwd`, **Then** the shell outputs the current working directory.
3. **Given** the shell is running, **When** the user types `export MY_VAR=hello`, **Then** subsequent commands see `MY_VAR` in their environment.
4. **Given** the shell is running, **When** the user types `exit`, **Then** the shell terminates with exit code 0.
5. **Given** the shell is running, **When** the user types `echo hello world`, **Then** the shell outputs `hello world` (using the built-in `echo`, not `/bin/echo`).

---

### Edge Cases

- What happens when a command line exceeds system argument length limits?
- How does the shell handle a pipeline where an intermediate command fails?
- How does the shell handle `>` redirection when the target file is not writable?
- What happens when the user pipes into a file redirection (e.g., `echo data | cat > file`)?
- How does the shell handle empty input or whitespace-only input?
- How does the shell handle SIGINT (Ctrl+C) during a long-running command?
- What happens with quoted arguments containing spaces, `|`, `>`, or `>>` characters?
- How does the shell handle redirection to `/dev/null`?
- What happens when the user runs a command that produces no output through a pipe?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The shell MUST parse user input into a command and arguments, respecting single and double quotes.
- **FR-002**: The shell MUST locate and execute external binaries by searching `PATH` environment variable.
- **FR-003**: The shell MUST pipe the stdout of one process to the stdin of the next when `|` separates commands.
- **FR-004**: The shell MUST support `>` to redirect stdout to a file (create or overwrite).
- **FR-005**: The shell MUST support `>>` to redirect stdout to a file (append).
- **FR-006**: The shell MUST support `2>` and `2>>` for stderr redirection.
- **FR-007**: The shell MUST display a customizable prompt before each command input.
- **FR-008**: The shell MUST provide a configuration mechanism for prompt format (e.g., config file or environment variable).
- **FR-009**: The prompt format MUST support escape sequences for: current directory (`\w`), username (`\u`), hostname (`\h`), time (`\t`), and literal text.
- **FR-010**: The shell MUST implement the following built-in commands: `cd`, `pwd`, `exit`, `export`, `echo`.
- **FR-011**: The shell MUST return a non-zero exit code when a command fails.
- **FR-012**: The shell MUST handle SIGINT (Ctrl+C) by aborting the currently running foreground command and returning to the prompt.
- **FR-013**: The shell MUST forward all environment variables to child processes.
- **FR-014**: The shell MUST support `--help` flag that displays usage information.
- **FR-015**: The shell MUST respect `$NO_COLOR` environment variable to disable colorized output.

### Key Entities *(include if feature involves data)*

- **Command**: A parsed representation of user input consisting of a program name, arguments, and optional redirections/pipes.
- **Pipeline**: A sequence of commands connected by `|` operators, where each command's stdout feeds the next command's stdin.
- **Redirection**: A file output target with an operator type (`>` for overwrite, `>>` for append) and a file path.
- **Environment**: A set of key-value pairs inherited from the parent process and mutable via `export` built-in.
- **PromptConfig**: A configuration object defining the prompt format template and available escape sequences.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can type any valid command found on `PATH` and see its output in under 500ms on a modern Linux system.
- **SC-002**: A three-stage pipeline (e.g., `a | b | c`) produces identical output to the equivalent bash pipeline for at least 10 common Unix utilities.
- **SC-003**: A user can customize their prompt via a configuration file and see the change reflected on the next shell restart.
- **SC-004**: The shell starts, accepts input, and gracefully exits without crashes during a 30-minute interactive session running a mix of built-in and external commands.
- **SC-005**: A user can chain `>` and `>>` redirections with pipes and achieve the same file output as bash for at least 5 common patterns.
- **SC-006**: The shell compiles and runs without modification on both Ubuntu 22.04 and the latest `swift:amazonlinux2` Docker image.

## Assumptions

- The shell is a single-binary executable distributed via Swift Package Manager.
- The shell does not include its own scripting language — it executes external binaries and supports command chaining via pipes and redirections, similar to bash's non-scripting interactive mode.
- The prompt configuration is stored in a dotfile in the user's home directory (`~/.swellprompt` or similar).
- The user has standard Unix utilities (`ls`, `cat`, `grep`, `wc`, etc.) available on their `PATH`.
- The shell targets a UTF-8 terminal environment.
- Job control (background processes with `&`, `fg`, `bg`, `jobs`) is out of scope for the initial release.
- Tab completion, history search, and inline help are out of scope for the initial release.
- The shell does not need to be POSIX-compliant but should follow POSIX conventions where reasonable for user expectations.
