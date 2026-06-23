# swell

**swell** is a Linux shell written in Swift. It provides interactive command-line execution with pipes, redirection, customizable prompts, and terminal color support — inspired by [Will-Tyler/swell](https://github.com/Will-Tyler/swell).

## Features

- Execute external binaries with argument parsing (respects `PATH`)
- Pipe (`|`) stdout between commands
- File redirection: overwrite (`>`) and append (`>>`)
- Stderr redirection (`2>`, `2>>`)
- Built-in commands: `cd`, `pwd`, `exit`, `export`, `echo`
- Customizable prompt with escape sequences (`\w`, `\u`, `\h`, `\t`)
- Terminal color support respecting `$NO_COLOR`, `$CLICOLOR`, `$CLICOLOR_FORCE`, and `$TERM`
- Colored error messages on stderr
- SIGINT (Ctrl+C) handling
- `--help` flag with usage information

## Running

1. Install [Swift](https://www.swift.org/install/).
2. Run `swift run swell`.

For development builds with color support: `swift run swell --color=auto`

## Configuration

Prompt templates are configured via `~/.swellprompt`. Default: `\w$ `
Escape sequences: `\w` (working directory), `\u` (user), `\h` (hostname), `\t` (time).

Color output is controlled by standard environment variables:
`$NO_COLOR` disables all color; `$CLICOLOR=0` disables auto-color;
`$CLICOLOR_FORCE=1` forces color even when output is piped.

## Project Structure

```
Sources/swell/
├── Builtins/       # Built-in command implementations (cd, pwd, exit, export, echo)
├── Color/          # ANSI color resolution and output helpers
├── Environment/    # Environment variable management
├── Execution/      # Process spawning, pipes, and redirection
├── Parser/         # Command-line lexer and parser
├── Prompt/         # Prompt rendering and template processing
├── REPL.swift      # Read-eval-print loop
├── SignalHandler.swift  # Signal handling (SIGINT, SIGCHLD)
└── Swell.swift     # Entry point and CLI argument parsing
```
