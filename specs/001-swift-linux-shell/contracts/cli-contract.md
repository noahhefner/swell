# CLI Contract: Swift Linux Shell (swell)

## Shell Invocation

```
swell [--version] [--help] [--rcfile <path>]
```

The shell binary (`swell`) takes no positional arguments. It starts an
interactive REPL session.

### Flags

| Flag | Description |
|------|-------------|
| `--version` | Print version and exit |
| `--help` | Print usage and exit |
| `--rcfile <path>` | Use an alternate config file for prompt |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Successful exit (user typed `exit` or EOF) |
| 1 | Shell error (config parse failure, etc.) |

## User Input Grammar

```
input      ::= command ( '|' command )*
command    ::= program ( argument )* ( redirection )*
redirection ::= '>' filename
              | '>>' filename
              | '2>' filename
              | '2>>' filename
program    ::= word
argument   ::= word
word       ::= unquoted | "'" sq-string "'" | '"' dq-string '"'
unquoted   ::= ( not-pipe-not-redirect-not-space )+
sq-string  ::= ( any-char-except-single-quote )+
dq-string  ::= ( any-char-except-double-quote-backslash )*
```

### Quoting Rules

- Single quotes: preserve literal value of every character inside
- Double quotes: preserve literal value except for `$`, `\`, `"` and `\``
- Backslash inside double quotes: escape next character
- Outside quotes: pipe `|`, redirect `>`/`>>`/`2>` are operators;
  spaces are argument separators; everything else is literal

## Redirection Contract

| Syntax | Behaviour |
|--------|-----------|
| `> file` | Open `file` for writing (O_WRONLY\|O_CREAT\|O_TRUNC, mode 0644). Stdout → file fd. |
| `>> file` | Open `file` for appending (O_WRONLY\|O_CREAT\|O_APPEND, mode 0644). Stdout → file fd. |
| `2> file` | Same as `>` but dup stderr instead of stdout. |
| `2>> file` | Same as `>>` but dup stderr instead of stdout. |

**Error semantics**: If the file cannot be opened (permission, invalid
path, read-only filesystem), the shell MUST print an error to stderr
and abort the pipeline. Exit code 1.

## Pipe Contract

Each `|` connects the stdout of the left command to the stdin of the
right command. The pipe is created with `pipe()` syscall before
forking. The write-end is assigned to the left child's stdout; the
read-end is assigned to the right child's stdin.

**Error semantics**: If `pipe()` fails (EMFILE, ENFILE), the shell
MUST print an error and abort. Exit code 1.

## Prompt Contract

- Default prompt file: `$XDG_CONFIG_HOME/swell/prompt` (fallback:
  `~/.config/swell/prompt`)
- If the file does not exist, fall back to `swell $ `
- See `data-model.md` escape table for supported `\` sequences
- The rendered prompt is printed to stderr so that piping stdout of
  commands is not polluted

## Signal Contract

| Signal | Behaviour |
|--------|-----------|
| SIGINT (Ctrl+C) | Abort foreground command process group. Return to prompt. |
| SIGPIPE | Ignored by the shell process (child processes inherit default handler). |
| SIGTERM | Forward to foreground child. If no child, exit. |
| SIGQUIT (Ctrl+\) | Ignored in v1 (default behaviour). |
