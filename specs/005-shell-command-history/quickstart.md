# Quickstart: Shell Command History

## Prerequisites

- Ubuntu 22.04+ or equivalent Linux with Swift 6.0 toolchain installed
- Git checkout of the `swell` project on the `005-shell-command-history` branch

## Setup

```bash
cd /path/to/swell
swift build
```

## Validation Scenarios

### Scenario 1: Arrow key navigation

```bash
# Start the shell (non-interactive test via pipe)
echo -e "echo first\necho second\n" | .build/debug/swell
```

Manual test:
```bash
.build/debug/swell
# Type: echo hello [Enter]
# Type: echo world [Enter]
# Press Up arrow      → should show "echo world"
# Press Up arrow      → should show "echo hello"
# Press Down arrow    → should show "echo world"
# Press Down arrow    → should show empty prompt
# Press Enter         → nothing executed (empty line)
```

**Expected**: Arrow keys cycle through command history. Down past newest clears the line.

### Scenario 2: `history` builtin

```bash
.build/debug/swell
# Type: ls [Enter]
# Type: pwd [Enter]
# Type: echo done [Enter]
# Type: history [Enter]
```

**Expected output**:
```
 1  ls
 2  pwd
 3  echo done
```

### Scenario 3: Empty commands not recorded

```bash
.build/debug/swell
# Type: [Enter] (empty)
# Type: "  " [Enter] (whitespace only)
# Type: echo real [Enter]
# Type: history [Enter]
```

**Expected output**: Only `echo real` appears (entry 1).

### Scenario 4: Non-TTY fallback

```bash
echo "echo hello" | .build/debug/swell
```

**Expected**: The command executes successfully. Arrow key input is not relevant (piped input).

## Running Tests

```bash
swift test --filter CommandHistoryTests
swift test --filter HistoryIntegrationTests
swift test  # full suite
```

## Key Contracts

- [Input Contract](contracts/input-contract.md) — Line Editor API and terminal state contract
- [Data Model](data-model.md) — CommandHistory entity definition

## Related Specs

- [Feature Spec](spec.md) — full specification with user stories and requirements
