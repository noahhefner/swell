# Quickstart: Swell Linux Shell

## Prerequisites

- Linux (x86_64 or ARM64) with glibc 2.28+
- Swiftly (toolchain manager) — install per
  [swiftlang.github.io/swiftly](https://swiftlang.github.io/swiftly/)

## Setup

```bash
# Install the required Swift toolchain
swiftly install latest
swiftly use latest

# Verify
swift --version
```

## Build

```bash
# Clone or navigate to project root
cd swell

# Build in release mode
swift build -c release

# The binary is at:
# .build/release/swell
```

## Run

```bash
# Start the shell
swift run -c release swell

# Or directly:
.build/release/swell
```

## Smoke Tests

### Test 1: Basic command execution

```bash
swift run -c release swell <<'EOF'
echo hello world
exit
EOF
```

**Expected output**: `hello world`

### Test 2: Command with arguments

```bash
swift run -c release swell <<'EOF'
wc -w <<< "one two three"
exit
EOF
```

**Expected output**: `3`

### Test 3: Piping

```bash
swift run -c release swell <<'EOF'
echo "hello world" | wc -w
exit
EOF
```

**Expected output**: `2`

### Test 4: File redirection with `>`

```bash
swift run -c release swell <<'EOF'
echo "test data" > /tmp/swell-test.txt
cat /tmp/swell-test.txt
exit
EOF
```

**Expected output**: `test data`

### Test 5: File redirection with `>>`

```bash
swift run -c release swell <<'EOF'
echo "line 1" > /tmp/swell-append.txt
echo "line 2" >> /tmp/swell-append.txt
cat /tmp/swell-append.txt
exit
EOF
```

**Expected output**:
```
line 1
line 2
```

### Test 6: Built-in commands

```bash
swift run -c release swell <<'EOF'
cd /tmp
pwd
export MYVAR=hello
exit
EOF
```

**Expected output**: `/tmp`

### Test 7: Custom prompt

Create `~/.config/swell/prompt` with content: `\u@\h:\w$ `

```bash
mkdir -p ~/.config/swell
echo '\u@\h:\w$ ' > ~/.config/swell/prompt
# Start shell and observe custom prompt
swift run -c release swell
```

### Test 8: `--help` and `--version`

```bash
.build/release/swell --help
.build/release/swell --version
```

## CI Integration

```yaml
# GitHub Actions snippet
jobs:
  test:
    runs-on: ubuntu-22.04
    steps:
      - uses: swift-actions/setup-swift@v2
        with:
          swift-version: "latest"
      - run: swift build
      - run: swift test
```

## Validation Checklist

- [ ] Binary compiles on Ubuntu 22.04 (x86_64)
- [ ] Binary compiles on ARM64 (via `swift:amazonlinux2` Docker)
- [ ] All smoke tests pass
- [ ] `--help` displays usage
- [ ] `--version` prints version
- [ ] `$NO_COLOR` disables color
- [ ] SIGINT (Ctrl+C) aborts foreground command and returns to prompt

## References

- [Spec](spec.md) — feature specification
- [Data Model](data-model.md) — entity definitions and state machine
- [CLI Contract](contracts/cli-contract.md) — command grammar and contracts
- [Constitution](../../.specify/memory/constitution.md) — project principles
