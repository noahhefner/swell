# Feature Specification: Shell Command History

**Feature Branch**: `005-shell-command-history`

**Created**: 2026-06-29

**Status**: Draft

**Input**: User description: "I want to implement a history for this shell program. The use should be able to use up and down arrows to select previous commands. A builtin 'history' command should be added to show all previous commands."

## User Scenarios & Testing

### User Story 1 - Arrow Key Navigation Through History (Priority: P1)

As a user, I want to press the up and down arrow keys to recall and cycle through previously entered commands, so that I can re-execute or edit commands without retyping them.

**Why this priority**: Arrow key history navigation is the most visible and frequently used shell feature — users expect it from any interactive shell. Without it, every command must be retyped in full.

**Independent Test**: Can be fully tested by launching the shell, running two distinct commands, pressing up twice to see the first command, and verifying the prompt shows the expected text.

**Acceptance Scenarios**:

1. **Given** the shell is running, **When** the user types `echo hello`, presses Enter, then presses the Up arrow key, **Then** the input line shows `echo hello`.
2. **Given** the user has entered three commands (`ls`, `pwd`, `echo hi`), **When** the user presses Up three times, **Then** the input line shows `ls` (the oldest of the three).
3. **Given** the user is browsing history with Up arrow and is on the second-to-last command, **When** the user presses Down arrow, **Then** the input line shows the most recent command.
4. **Given** the user pressed Up once and is viewing a historical command, **When** the user presses Down past the newest command, **Then** the input line is cleared (showing an empty prompt ready for new input).
5. **Given** no commands have been entered yet in the session, **When** the user presses Up arrow, **Then** nothing happens (input line remains empty).
6. **Given** the user has navigated to a historical command using arrows, **When** the user edits the command text and presses Enter, **Then** the modified command is executed and added to history as a new entry (not modifying the original).

---

### User Story 2 - `history` Builtin Command (Priority: P1)

As a user, I want to run a `history` command to see a numbered list of all commands executed in the current session, so that I can review what I've done and refer to earlier commands.

**Why this priority**: The `history` command is the standard way to view command history in shells and complements arrow key navigation.

**Independent Test**: Can be tested by running `echo a`, `echo b`, then `history` and verifying the output contains both commands with line numbers.

**Acceptance Scenarios**:

1. **Given** the user has executed `ls`, `pwd`, and `echo done` in that order, **When** the user types `history`, **Then** the output shows:
   ```
     1  ls
     2  pwd
     3  echo done
   ```
2. **Given** no commands have been executed yet, **When** the user types `history`, **Then** the output is empty (no entries shown).
3. **Given** the user has executed 100+ commands, **When** the user types `history`, **Then** all commands are displayed with their corresponding line numbers.

---

### User Story 3 - History Includes All Command Types (Priority: P2)

As a user, I want all commands — both builtins and external programs — to be recorded in history, so that I have a complete record of my shell session.

**Why this priority**: Incomplete history undermines trust in the feature and is unexpected for users.

**Independent Test**: Run a mix of builtin and external commands, then run `history` and verify all are listed.

**Acceptance Scenarios**:

1. **Given** the user ran a builtin (`cd /tmp`) and an external command (`ls -la`), **When** the user types `history`, **Then** both commands are listed.
2. **Given** the user ran an empty command (just pressed Enter), **When** the user types `history`, **Then** the empty command is NOT recorded.
3. **Given** the `history` command itself is executed, **When** the user runs `history`, **Then** the `history` command is NOT recorded in its own output (to avoid self-referencing).

---

### Edge Cases

- What happens when the user presses Up while at the oldest entry in history? (Should stay at oldest entry.)
- What happens when the terminal does not support arrow key escape sequences?
- What happens with very long commands in history (wrapping)?
- What happens when history exceeds available memory?
- What happens when the user presses arrow keys during command editing?
- What happens if the user types part of a command and presses Up/Down? (Current state: pressing Up replaces the input buffer entirely with the history entry; partial input is lost.)
- What happens when stdin is not a TTY (e.g., input is piped)?

## Requirements

### Functional Requirements

- **FR-001**: The shell MUST record every non-empty command entered by the user during the session in an in-memory history list.
- **FR-002**: The Up arrow key MUST cause the previous command in history to appear at the input prompt, replacing the current input.
- **FR-003**: The Down arrow key MUST cause the next command in history to appear at the input prompt, replacing the current input.
- **FR-004**: When at the newest entry in history and Down is pressed, the input line MUST clear to an empty state.
- **FR-005**: When at the oldest entry in history and Up is pressed, the input line MUST remain at the oldest entry.
- **FR-006**: A `history` builtin command MUST be available that displays all recorded commands, each prefixed by a sequential line number and a space.
- **FR-007**: The `history` command output MUST show the oldest command first and the newest last.
- **FR-008**: The `history` command itself MUST NOT be added to the history list.
- **FR-009**: Empty commands (blank input or whitespace-only) MUST NOT be added to the history list.
- **FR-010**: When a historical command is recalled and modified before execution, the modified version (not the original) MUST be added as a new history entry.
- **FR-011**: History MUST be preserved for the duration of the shell session only (in-memory, no file persistence in this iteration).
- **FR-012**: The shell MUST detect arrow key presses and respond with history navigation. If the terminal or input method does not support arrow key input, the shell MUST continue to function normally without history navigation.

### Key Entities

- **CommandHistory**: An ordered collection of all non-empty commands executed during the current shell session, along with a navigation cursor for browsing.
- **HistoryCursor**: A position indicator within the CommandHistory that moves up (older) and down (newer) in response to arrow key presses, allowing the user to recall and edit historical commands.
- **Line Editor**: The input reading component that replaces `readLine()` and handles raw terminal input, including escape sequence detection for arrow keys, text editing, and history navigation.

## Success Criteria

### Measurable Outcomes

- **SC-001**: After executing any three distinct commands, pressing Up three times causes the first command to appear at the prompt — verified by automated input simulation.
- **SC-002**: Running `history` after five commands produces a numbered list of exactly five entries — verified by capturing the command output.
- **SC-003**: Pressing Up then Down returns the user to the empty prompt state — verified by inspecting the prompt content.
- **SC-004**: The `history` command itself never appears in the output of `history` — verified by comparing the count of executed commands to the count of displayed entries.
- **SC-005**: Arrow key navigation does not interfere with external program execution or pipeline commands.
- **SC-006**: All existing tests continue to pass after the feature is added.

## Assumptions

- The terminal supports detecting arrow key presses (standard behavior for modern terminal emulators).
- History is session-only; file-based history persistence is out of scope for this iteration.
- History entries are plain strings; no metadata (timestamps, exit codes) is stored in this iteration.
