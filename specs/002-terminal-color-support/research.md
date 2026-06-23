# Research: Terminal Color Support

## Environment Variable Resolution Order

### Decision
Use a strict priority chain: `NO_COLOR` > `CLICOLOR` > `CLICOLOR_FORCE` > `TERM` > TTY detection > default (color on).

### Rationale
The `NO_COLOR` convention (https://no-color.org) explicitly states it must override all other color controls. `CLICOLOR=0` is an explicit opt-out from BSD conventions. `CLICOLOR_FORCE=1` overrides TTY detection for users who want color in pipes. `TERM=dumb` or `xterm-mono` indicates terminal cannot display color. TTY detection matches standard Unix behavior (ls, grep disable color when piped).

### Alternatives Considered
- **Always color unless NO_COLOR**: Would ignore CLICOLOR/CLICOLOR_FORCE conventions used by other tools.
- **CLICOLOR_FORCE wins over NO_COLOR**: Violates the no-color.org spec.

## ANSI Escape Code Selection

### Decision
Use 3/4-bit ANSI SGR codes (30-37 foreground, 40-47 background, 1 bold, 0 reset). Format: `\e[<code>m`.

### Rationale
Universally supported by all terminal emulators. Sufficient for distinguishing error (red), warnings (yellow), prompts (cyan/default). No need for 256-color or true color for a shell.

### Alternatives Considered
- **24-bit true color (\e[38;2;R;G;Bm)**: Overkill for shell metadata. Not universally supported (e.g., some old terminals, CI environments).

## TTY Detection

### Decision
Use `isatty()` from Glibc (via `Darwin`/`Glibc` module) on file descriptors `STDOUT_FILENO` and `STDERR_FILENO`.

### Rationale
POSIX standard, zero dependencies, sub-microsecond cost. Matches how every other CLI tool checks terminal status.

### Alternatives Considered
- **`ProcessInfo.processInfo.environment["TERM"]` alone**: Does not capture pipe/redirect cases (TERM is set even when piped).
- **`FileHandle.isTTY`**: Not available on Linux Swift; Apple-only API.

## Prompt Color Escape Syntax

### Decision
Support `\[\e[<code>m\]` for color start and `\[\e[0m\]` for reset. The `\[` and `\]` markers are parsed but treated as no-ops (they signal non-printing characters for readline width calculation — not applicable to this shell, but retained for bash prompt compatibility).

### Rationale
Maximum compatibility with existing bash PS1 configurations. Users can copy their `.bashrc` prompt templates directly.

### Alternatives Considered
- **Raw `\e[31m` without markers**: Simpler to parse, but incompatible with bash prompt configs users already have.
- **Custom syntax like `%{red%}`**: Would require users to learn a new prompt format.
