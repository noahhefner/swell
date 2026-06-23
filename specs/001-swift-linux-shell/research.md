# Research: Swift Linux Shell

## Process Spawning on Linux Swift

- **Decision**: Use `Process` from Foundation (wraps `posix_spawn` on Linux)
- **Rationale**: Foundation's `Process` is available on Linux Swift, handles
  executable search via `PATH`, argument passing, environment inheritance,
  and signal propagation. Direct `posix_spawn` via `Glibc` module is
  possible but adds unnecessary complexity — Foundation provides a
  safe, documented API that is portable across Linux and macOS for
  development.
- **Alternatives considered**: Raw `posix_spawn` via `Glibc` module
  (more control, but significantly more boilerplate); `NSTask` (same
  as `Process`, Objective-C legacy name).

## Pipe Plumbing

- **Decision**: Use Foundation `Pipe` class + `FileHandle` for
  inter-process plumbing. Connect pipe file descriptors to child
  processes via `Process.standardOutput`/`.standardInput`.
- **Rationale**: `Pipe` wraps `pipe()` syscall + `FileHandle` provides
  async reading. For multi-stage pipelines, chain `Pipe`s sequentially:
  command A stdout → Pipe → command B stdin. This matches how bash
  implements pipelines internally.
- **Alternatives considered**: Manual `pipe()`/`dup2()` via `Glibc`
  (possible but less idiomatic in Swift).

## Line Input / REPL

- **Decision**: Use `readLine()` from Swift Standard Library for initial
  REPL loop. No external line-editing library in v1.
- **Rationale**: `readLine()` is sufficient for MVP. It supports basic
  line editing (backspace, arrow keys via terminal driver in cooked
  mode). For a more fish-like experience with syntax highlighting and
  autosuggestions, a library like `LineNoise` or `GNU Readline` wrapper
  can be added later.
- **Alternatives considered**: `LineNoise` Swift package (BSD-licensed,
  pure Swift line editor — good candidate for v2); `GNU Readline` via
  C interop (GPL-licensed, heavyweight).

## Prompt Configuration

- **Decision**: Config file at `$XDG_CONFIG_HOME/swell/prompt` (fallback
  `~/.config/swell/prompt`). Simple text file with escape sequences.
- **Rationale**: Follows XDG Base Directory spec. Plain text file is
  easy to edit without special tooling. No YAML/JSON parsing needed at
  startup.
- **Alternatives considered**: Environment variable `SWELL_PROMPT`
  (simpler but doesn't persist across sessions); JSON config file
  (more structure but over-engineered for a single string).

## Signal Handling

- **Decision**: Install SIGINT handler that sets a flag checked in the
  REPL loop. On SIGINT during command execution, kill the foreground
  process group.
- **Rationale**: Swift on Linux supports `signal()` and `sigaction()`
  via the `Glibc` module. A pure-Swift approach using Foundation's
  `Process` handles SIGINT forwarding automatically when the child
  is in the same process group.
- **Alternatives considered**: `DispatchSource` signal monitoring (not
  available on Linux in Swift); `sigaction` with C callback (works but
  requires `@convention(c)`).

## Swiftly Toolchain Integration

- **Decision**: Document required Swiftly commands in `quickstart.md`.
  Project pins minimum Swift version. CI uses `swiftly install` to
  fetch the required toolchain.
- **Rationale**: Swiftly is the user-requested toolchain manager. It
  can install, switch, and remove Swift toolchains on Linux with a
  single command. The project's `Package.swift` will specify
  `swift-tools-version:`.
- **Alternatives considered**: Manual Swift installation via
  `swift.org` tarballs (more complex); Docker images (`swift:*` —
  used for CI, not for developer toolchain management).

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                   REPL Loop                      │
│  print(prompt) → readLine() → parse() → exec()  │
└────────────────────┬────────────────────────────┘
                     │ Parsed Pipeline
                     ▼
┌─────────────────────────────────────────────────┐
│                  Parser                          │
│  Tokenize → build Command/Redirect/Pipe AST      │
└────────────────────┬────────────────────────────┘
                     │ Pipeline AST
                     ▼
┌─────────────────────────────────────────────────┐
│               Executor                           │
│  For each command: fork+exec, plumb fds          │
│  Handle pipes between stages                     │
│  Apply redirects (>, >>, 2>)                     │
└─────────────────────────────────────────────────┘
```
