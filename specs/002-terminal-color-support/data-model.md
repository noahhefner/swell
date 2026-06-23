# Data Model: Terminal Color Support

## ColorState

Represents whether color output is enabled for a given output operation.

| Field | Type | Description |
|-------|------|-------------|
| isEnabled | Bool | Whether ANSI color codes should be emitted |

**Validation**: Stateless struct; re-resolved per output operation.

## ColorConfig

Hardcoded mapping of output types to ANSI color codes.

| Output Type | ANSI Code | Color | Purpose |
|-------------|-----------|-------|---------|
| error | `\e[31m` | Red | Error messages on stderr |
| errorReset | `\e[0m` | Reset | Reset after error message |
| promptReset | `\e[0m` | Reset | Reset after prompt color segment |

**Validation**: Mappings are compile-time constants, not user-configurable.

## ColorResolver

Reads environment variables and terminal state to produce a `ColorState`.

| Input | Source | Type | Behavior |
|-------|--------|------|----------|
| NO_COLOR | Environment variable | String? | If set (any value) → disable color |
| CLICOLOR | Environment variable | String? | If "0" → disable color |
| CLICOLOR_FORCE | Environment variable | String? | If "1" → force color even if not TTY |
| TERM | Environment variable | String? | If "dumb"/"xterm-mono"/"vt100" → disable (auto mode only) |
| stdoutIsTTY | `isatty(STDOUT_FILENO)` | Bool | If false → disable (unless CLICOLOR_FORCE) |
| stderrIsTTY | `isatty(STDERR_FILENO)` | Bool | If false → disable (unless CLICOLOR_FORCE) |

### Resolution Algorithm

```
if NO_COLOR is set → disabled
else if CLICOLOR == "0" → disabled
else if CLICOLOR_FORCE == "1" → enabled (bypass TTY/TERM check)
else if TERM is "dumb" | "xterm-mono" | "vt100" → disabled
else if stdout is not TTY AND stderr is not TTY → disabled
else → enabled
```

**Rationale**: NO_COLOR is absolute override. CLICOLOR=0 is explicit opt-out. CLICOLOR_FORCE=1 bypasses auto-detection. TERM checks catch known monochrome terminals. TTY check prevents color in pipes/files unless forced.
