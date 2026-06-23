# Quickstart: Terminal Color Support

## Prerequisites

- Swift 6.0 toolchain (via Swiftly)
- `swift build` succeeds at HEAD
- All existing tests pass: `swift test`

## Setup

```bash
cd /home/nhefner/Projects/swell
swift build
```

## Validation Scenarios

### Scenario 1: Color disabled via NO_COLOR

```bash
NO_COLOR=1 .build/debug/swell --version
# Expected: "0.1.0" — no ANSI codes
```

```bash
echo "exit" | NO_COLOR=1 .build/debug/swell 2>&1 | cat -v
# Expected: No ^[[ (ESC) sequences in output
```

### Scenario 2: CLICOLOR_FORCE enables color in pipes

```bash
echo "exit" | CLICOLOR_FORCE=1 .build/debug/swell 2>&1 | cat -v
# Expected: May contain ^[[ sequences (ANSI codes visible via cat -v)
```

### Scenario 3: Color auto-disabled when piped

```bash
echo "exit" | .build/debug/swell 2>&1 | cat -v
# Expected: No ^[[ sequences (auto-detected pipe, no CLICOLOR_FORCE)
```

### Scenario 4: Error messages in red (interactive TTY)

```bash
.buikd/debug/swell -c "nonexistent_command"
# Expected: Error message appears in red on stderr (visual check)
```

### Scenario 5: Prompt color escapes render correctly

1. Create prompt config: `echo '\[\e[31m\]\w\[\e[0m\]$ ' > ~/.config/swell/prompt`
2. Run: `.build/debug/swell`
3. Expected: Current directory appears in red

### Scenario 6: All existing tests still pass

```bash
swift test
# Expected: 38 tests pass, 0 failures
```

## Running Tests

```bash
# Unit tests
swift test --filter ColorTests

# Integration tests
swift test --filter ColorIntegrationTests

# All tests
swift test
```
