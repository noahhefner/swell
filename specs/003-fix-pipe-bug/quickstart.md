# Quickstart: Fix Pipe Bug

## Prerequisites

- Linux (x86_64 or ARM64) with glibc 2.28+
- Swift 6.0 toolchain (via Swiftly)

## Build

```bash
cd /home/nhefner/Projects/swell
swift build
```

## Run

```bash
# Start the shell
swift run swell
```

## Validation Scenarios

### Scenario 1: Two-stage pipe

```bash
swift run swell <<'EOF'
echo hello world | wc -w
exit
EOF
```

**Expected output**: `2`

**What it validates**: Basic two-stage pipe works without "Bad file descriptor" errors.

### Scenario 2: Pipe with grep (the original failing case)

```bash
swift run swell <<'EOF'
ls | grep swell
exit
EOF
```

**Expected output**: Lines containing "swell" (e.g., `swell` if the binary is in the current directory). No error messages on stderr.

**What it validates**: The specific failing case from the bug report now works.

### Scenario 3: Three-stage pipe

```bash
swift run swell <<'EOF'
echo "hello world foo" | tr ' ' '\n' | wc -l
exit
EOF
```

**Expected output**: `3`

**What it validates**: Three-stage pipeline correctly passes data through all stages.

### Scenario 4: Four-stage pipe

```bash
swift run swell <<'EOF'
echo foo | cat | cat | wc -c
exit
EOF
```

**Expected output**: `4`

**What it validates**: Longer pipelines (4 stages) work correctly.

### Scenario 5: Pipe with no output

```bash
swift run swell <<'EOF'
echo -n "" | wc -c
exit
EOF
```

**Expected output**: `0`

**What it validates**: Edge case where first process produces no output.

## Run Tests

```bash
swift test
```

**Expected result**: All 53 tests pass.

## References

- [Spec](spec.md) — feature specification
- [Data Model](data-model.md) — entity definitions
- [Pipe Contract](contracts/pipe-contract.md) — pipeline execution contract
