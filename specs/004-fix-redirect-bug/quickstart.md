# Quickstart: Fix Redirect Bug

## Prerequisites

- Swift toolchain installed (matching project's CI)
- Repository cloned and dependencies resolved

## Setup

```bash
cd /home/nhefner/Projects/swell
swift build
```

## Validation Scenarios

### 1. Stdout Overwrite (`>`)

```bash
# Build and run a single command
echo 'echo hello world > /tmp/test-redirect.txt' | swift run swell
# Verify:
cat /tmp/test-redirect.txt
# Expected: "hello world"
```

### 2. Stdout Append (`>>`)

```bash
echo 'echo line1 > /tmp/append-test.txt' | swift run swell
echo 'echo line2 >> /tmp/append-test.txt' | swift run swell
cat /tmp/append-test.txt
# Expected: "line1\nline2\n"
```

### 3. Stderr Redirect (`2>`)

```bash
echo 'ls /nonexistent/path 2> /tmp/stderr-test.txt' | swift run swell
cat /tmp/stderr-test.txt
# Expected: error message from ls (non-empty)
```

### 4. Both Stdout and Stderr

```bash
echo 'ls /tmp 2> /tmp/both-err.txt > /tmp/both-out.txt' | swift run swell
cat /tmp/both-out.txt   # Should contain /tmp directory listing
cat /tmp/both-err.txt   # Should be empty (or contain errors if any)
```

### 5. Pipeline with Redirect

```bash
echo 'ls /tmp | grep "test" > /tmp/pipe-test.txt' | swift run swell
cat /tmp/pipe-test.txt
# Expected: filtered output from ls | grep
```

### 6. Error: Unwritable Path

```bash
echo 'echo test > /root/protected.txt' | swift run swell 2>&1
# Expected: error message (not a crash)
```

### 7. Error: Directory as Target

```bash
echo 'echo test > /tmp' | swift run swell 2>&1
# Expected: error message (cannot write to directory)
```

## Running Tests

```bash
# Run full test suite
swift test

# Run only redirect integration tests (after adding them)
swift test --filter RedirectIntegrationTests
```

## Expected Outcomes

- All seven validation scenarios produce correct output
- `swift test` passes all 57+ existing tests (plus new redirect tests)
- No new compiler warnings or lint violations
