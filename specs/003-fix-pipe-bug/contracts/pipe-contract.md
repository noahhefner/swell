# Pipe Contract

## Interface

The pipeline execution interface is internal to the `REPL` class and not exposed as a public API. It is invoked via the `execute(_:)` method which dispatches to `executePipeline(_:)` when the parser detects a `|` token.

## Contract

### Input

- `ParsedPipeline` containing 2+ `ParsedCommand` objects connected by `|` operators
- `ShellEnvironment` for PATH resolution and environment variable inheritance
- `FileHandle.standardInput` for the first command's stdin

### Behavior

1. **Pipe Creation**: Exactly N-1 inter-process pipes are created for an N-command pipeline, plus one output pipe for the last command's stdout capture.

2. **Process Configuration**:
   - First process: stdin = `FileHandle.standardInput`, stdout = `pipes[0].fileHandleForWriting`
   - Middle processes (1 to N-2): stdin = `pipes[index-1].fileHandleForReading`, stdout = `pipes[index].fileHandleForWriting`
   - Last process: stdin = `pipes[N-2].fileHandleForReading`, stdout = `outPipe.fileHandleForWriting`

3. **Process Launch**: All processes are launched via `process.run()`. If any process fails to launch, all previously-launched processes are terminated and the error is returned.

4. **Parent Cleanup**: After all processes are successfully launched, the parent process closes all pipe read and write ends (including the output pipe's write end). This is essential for:
   - Preventing file descriptor leaks
   - Ensuring EOF is properly signaled on read ends when child processes close their copies

5. **Output Collection**: The parent waits for the last process to exit, then reads all data from `outPipe.fileHandleForReading`. The captured output is returned as a `CommandResult`.

### Output

- `CommandResult.success(output: String)` — Last process exited with code 0; output captured from stdout
- `CommandResult.failure(error: String, exitCode: Int32)` — Last process exited non-zero; error message includes exit code
- `CommandResult.exit` — If a built-in `exit` command is encountered in the pipeline

### Error Handling

- Command not found: Returns `CommandResult.failure` with exit code 127
- Process launch failure: Returns `CommandResult.failure` with exit code 1 and the error description
- Built-in `exit` in pipeline: Immediately returns `CommandResult.exit` without launching remaining processes

### Resource Management

- All `Pipe` objects are locally scoped within `executePipeline` and deallocated when the method returns
- Pipe file handles are explicitly closed in the parent after child processes are launched
- If a pipeline process fails to launch, all previously-launched processes are terminated via `process.terminate()`
- The output pipe's write end is closed in the parent before reading to ensure EOF when the child exits

## Test Coverage

The following test files cover the pipeline contract:

- `Tests/SwellIntegrationTests/PipeIntegrationTests.swift` — Direct pipe construction tests
- `Tests/SwellIntegrationTests/ExecutionIntegrationTests.swift` — Shell-mediated pipeline tests
- `Tests/SwellTests/PipelineTests.swift` — Parser pipeline tokenization tests
