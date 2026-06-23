# Contracts: Terminal Color Support

## Environment Variable Resolution Contract

### Priority Order (highest to lowest)

1. **NO_COLOR** — If set (regardless of value), ALL color output is disabled. See https://no-color.org.
2. **CLICOLOR** — If set to `0`, color is disabled. If set to `1`, color is enabled (auto mode). Unset = auto mode.
3. **CLICOLOR_FORCE** — If set to `1`, color is enabled even when output is not a TTY. Ignored if NO_COLOR is set.
4. **TERM** — Used only in auto mode (no explicit override). Values `dumb`, `xterm-mono`, `vt100` disable color.
5. **TTY status** — Used only in auto mode. `isatty()` check on stdout and stderr. If neither fd is a TTY, color is disabled.

### Precedence Table

| NO_COLOR | CLICOLOR | CLICOLOR_FORCE | TERM | TTY | Result |
|----------|----------|----------------|------|-----|--------|
| set | any | any | any | any | DISABLED |
| unset | 0 | any | any | any | DISABLED |
| unset | unset/1 | 1 | any | any | ENABLED |
| unset | unset/1 | unset | dumb | any | DISABLED |
| unset | unset/1 | unset | xterm | yes | ENABLED |
| unset | unset/1 | unset | xterm | no | DISABLED |

## ANSI Code Contract

### Constants

| Name | Sequence | Purpose |
|------|----------|---------|
| ColorReset | `\e[0m` | Reset all attributes |
| RedForeground | `\e[31m` | Error messages |
| Bold | `\e[1m` | Emphasis (future use) |

### Prompt Escape Syntax

- Color start: `\[\e[<code>m\]` — e.g., `\[\e[31m\]` for red
- Color reset: `\[\e[0m\]` — or `\[\e[m\]`
- `\[` and `\]` markers are parsed but treated as no-ops (width calculation not applicable)

## TTY Detection Contract

- Use `isatty(STDOUT_FILENO)` for stdout check (file descriptor 1)
- Use `isatty(STDERR_FILENO)` for stderr check (file descriptor 2)
- Platform imports: `Darwin` on macOS, `Glibc` on Linux
