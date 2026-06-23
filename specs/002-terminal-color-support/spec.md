# Feature Specification: Terminal Color Support

**Feature Branch**: `002-terminal-color-support`

**Created**: 2026-06-23

**Status**: Draft

**Input**: User description: "Update the codebase to respect and use color output to the terminal based on environment settings."

## User Scenarios & Testing

### User Story 1 - Respect NO_COLOR Convention

As a user who prefers plain terminal output, I want the shell to respect the `$NO_COLOR` environment variable so that all output remains monochrome regardless of terminal capability.

**Why this priority**: The NO_COLOR convention is an industry standard — every CLI tool should honor it.

**Acceptance Scenarios**:

1. **Given** the shell is running with `NO_COLOR` set in the environment, **When** the shell displays any output (prompt, errors, command results), **Then** no ANSI color escape sequences appear in that output.
2. **Given** the shell is running without `NO_COLOR` set, **When** the shell displays output, **Then** ANSI color escape sequences MAY be used.

---

### User Story 2 - CLICOLOR and CLICOLOR_FORCE Support

As a user, I want to enable or disable color output explicitly using `$CLICOLOR` and `$CLICOLOR_FORCE`, so that I can override automatic color detection.

**Why this priority**: These variables are the BSD convention for color control, widely supported by command-line tools.

**Acceptance Scenarios**:

1. **Given** `CLICOLOR=0` is set, **When** the shell displays output, **Then** no color escape sequences appear.
2. **Given** `CLICOLOR_FORCE=1` is set (even when output is not a TTY), **When** the shell displays output, **Then** color escape sequences ARE used.
3. **Given** neither `NO_COLOR`, `CLICOLOR`, nor `CLICOLOR_FORCE` is set, **When** the shell displays output to a terminal, **Then** color is used if the terminal supports it (per `$TERM`).
4. **Given** neither `NO_COLOR` nor `CLICOLOR_FORCE` is set, **When** the shell's stdout or stderr is piped to another process or file, **Then** color escape sequences are suppressed (plain text only).

---

### User Story 3 - Colorized Prompt Escape Sequences

As a user, I want to include color codes in my prompt template using escape sequences, so that my prompt stands out visually from command output.

**Why this priority**: Colorful prompts help users visually distinguish input from output and signal different shell states.

**Acceptance Scenarios**:

1. **Given** the prompt is configured with `\[\e[31m\]\w\[\e[0m\]$ `, **When** the shell renders the prompt, **Then** the working directory appears in red and the rest of the prompt is default color.
2. **Given** color is disabled (via `NO_COLOR`), **When** the prompt contains color escape sequences, **Then** the prompt is rendered without any color codes.
3. **Given** the prompt template contains no color escapes, **When** the shell renders the prompt, **Then** the output is plain text.

---

### User Story 4 - Colorized Error Messages

As a user, I want error messages displayed in a distinct color (e.g., red/bold on stderr), so that I can quickly identify problems in command output.

**Why this priority**: Colorized errors improve usability by making warnings and failures visually distinct.

**Acceptance Scenarios**:

1. **Given** the shell is running with color enabled, **When** a command fails and an error message is written to stderr, **Then** the error message is prefixed or wrapped with ANSI color codes (e.g., red text).
2. **Given** the shell is running with color disabled, **When** a command fails, **Then** the error message is plain text with no color codes.
3. **Given** the shell is running with color enabled, **When** a command succeeds and produces stdout output, **Then** stdout output is NOT colorized (only metadata/prompts/errors use color).

---

### Edge Cases

- What happens when `$TERM` is set to `dumb` or `xterm-mono` — does the shell suppress color?
- What happens when both `NO_COLOR` and `CLICOLOR_FORCE` are set? (NO_COLOR should win)
- How does the shell handle escape sequences in prompts when the terminal is a pipe or redirected file?
- What happens with color codes in the middle of command output (e.g., when running `ls --color`)?
- How does the shell ensure color reset (`\e[0m` or `\e[m`) is properly applied after colorized segments?
- What happens when stdout is piped but stderr remains connected to the terminal?

## Requirements

### Functional Requirements

- **FR-001**: The shell MUST check `$NO_COLOR` environment variable and disable all color output when set (regardless of value).
- **FR-002**: The shell MUST respect `$CLICOLOR` — when set to `0`, disable color; when unset, use automatic detection.
- **FR-003**: The shell MUST respect `$CLICOLOR_FORCE` — when set to `1`, force color output even when output is not a TTY (unless `NO_COLOR` overrides).
- **FR-004**: The shell MUST use `$TERM` to determine terminal color capability (e.g., `dumb`, `xterm-mono`, `vt100` should disable color when auto-detecting).
- **FR-005**: The shell MUST support ANSI color escape sequences in prompt templates using the `\[\e[<code>m\]` and `\[\e[0m\]` (reset) syntax.
- **FR-006**: The shell MUST render error messages on stderr in red (ANSI `\e[31m`) when color is enabled.
- **FR-007**: The shell MUST reset color after each colorized segment to avoid leaking color into subsequent output.
- **FR-008**: The shell MUST NOT add color codes to stdout output from executed commands (only to shell-generated metadata).
- **FR-009**: The shell MUST check whether stdout and stderr are connected to a TTY and suppress color escape sequences when either is not a terminal, unless `CLICOLOR_FORCE=1` overrides.

### Key Entities

- **ColorState**: An enum or struct that captures the current color resolution (enabled/disabled) based on all input rules and is reusable across all output sites.
- **ColorConfig**: An internal mapping of ANSI color codes per output type (e.g., error = red) with hardcoded defaults.
- **ColorResolver**: A component that reads the environment variables and terminal capability to produce a `ColorState` for each output operation.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Setting `NO_COLOR=1` before launching the shell results in zero ANSI escape sequences across all output during a 5-minute interactive session.
- **SC-002**: Setting `CLICOLOR_FORCE=1` enables color output when stdout is piped to a file (verified by inspecting the file for escape sequences).
- **SC-003**: A prompt template containing `\[\e[31m\]\w\[\e[0m\]$ ` renders the working directory in red when color is enabled, and as plain text when color is disabled.
- **SC-004**: Error messages from the shell (command not found, parse errors, etc.) appear in red on stderr when color is enabled.
- **SC-005**: All existing tests continue to pass after color support is added (color should be testable by inspecting output strings for escape sequences).
- **SC-006**: Piping the shell's prompt output (e.g., `echo hello | cat`) does not produce ANSI escape sequences in the piped output when color is auto-detected.

## Clarifications

### Session 2026-06-23

- Q: Should ColorConfig (color-to-output-type mappings) be user-configurable or hardcoded? → A: Hardcoded internally. No user-facing configuration surface for individual color mappings.
- Q: Should the shell auto-disable color when stdout/stderr is not a TTY? → A: Yes, auto-disable color when output is not connected to a terminal, unless `CLICOLOR_FORCE=1` overrides this.

## Assumptions

- The environment variables `$NO_COLOR`, `$CLICOLOR`, `$CLICOLOR_FORCE`, and `$TERM` follow their documented conventions as described at https://no-color.org and BSD manuals.
- The shell does not need to support 24-bit true color or extended 256-color palettes in the initial release.
- Color support is limited to common 3/4-bit ANSI color codes (30-37 foreground, 40-47 background, 1 bold, 0 reset).
- The `\[\e[...\]` syntax follows the bash convention where `\[` and `\]` denote non-printing sequences (used for prompt length calculation — not applicable to a non-readline shell, but retained for compatibility with existing prompt configurations).
- The user's terminal emulator supports standard ANSI escape sequences unless `$TERM` indicates otherwise.
- Color-to-output-type mappings (e.g., error = red) are hardcoded internally and not user-configurable.
- TTY detection uses `isatty()` on the relevant file descriptors to determine whether output is connected to a terminal.
