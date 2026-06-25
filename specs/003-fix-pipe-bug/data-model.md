# Data Model: Fix Pipe Bug

## Overview

This bug fix does not introduce any new entities, data structures, or state machines. The existing data model from the shell's pipeline execution is unchanged. This document describes the existing data entities relevant to pipeline execution.

## Entities

### Pipeline

A pipeline is an ordered sequence of commands connected by `|` operators.

**Source**: `Parser.swift` — `ParsedPipeline` struct

**Fields**:
- `commands: [ParsedCommand]` — The ordered list of commands to execute

### Pipe

A unidirectional OS-level data channel connecting two processes. Created via Foundation's `Pipe()` constructor.

**Properties**:
- `fileHandleForReading: FileHandle` — The read end of the pipe
- `fileHandleForWriting: FileHandle` — The write end of the pipe

**Lifecycle**:
1. Created in `executePipeline` — one pipe per connection between commands (N-1 for N commands), plus one output pipe for the last command's stdout
2. File handles assigned to child processes before `process.run()`
3. Parent closes its copies after all children are launched
4. Children close their copies when the process exits (automatic via OS)

### Process

A subprocess managed by Foundation's `Process` class.

**Relevant Properties**:
- `standardInput: Any?` — Source of stdin (FileHandle or Pipe)
- `standardOutput: Any?` — Destination of stdout (FileHandle or Pipe)
- `terminationStatus: Int32` — Exit code after process completes

## State Transitions

### Pipeline Execution Flow

```
Parse Input → Create Pipes → Configure Processes → Run All Processes → Close Parent FD Copies → Wait for Last Process → Read Output
```

### File Descriptor Lifecycle

```
Pipe Created (both ends open)
  → Read end assigned to Process N+1 stdin
  → Write end assigned to Process N stdout
  → All processes run() — fds duplicated into children
  → Parent closes both read and write ends
  → Children finish — OS closes their copies
  → Read end returns EOF
```

## Validation Rules

- Pipe read ends must NOT be closed before the consumer process has been spawned
- Pipe write ends must NOT be closed before the producer process has been spawned
- The parent process must close its copies of all pipe file descriptors after all children are running to avoid fd leaks and ensure proper EOF signaling
- The last process's stdout must be assigned a capture pipe BEFORE `process.run()` is called
