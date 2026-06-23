<!--
  Sync Impact Report
  ==================
  Version change: 1.0.0 → 1.1.0
  Modified principles:
    - I. Code Quality: removed "Xcode" reference from doc-comment guide
    - II. Swift Language Features: removed ObjC runtime, UIDocumentPickerDelegate,
      @Published/@State/@Binding references; generalised async guidance
    - III. Testing Standards: swapped XCTest+#require for Swift Testing framework;
      replaced Apple snapshot tests with CLI output/snapshot tests
    - IV. User Experience Consistency: fully rewritten for Linux shell (CLI
      conventions, output format, error protocol, $NO_COLOR, $PAGER, etc.)
  Added sections: Minimal Dependencies + Portability rules in Additional Constraints
  Removed sections: Apple OS targets, PrivacyInfo.xcprivacy (irrelevant on Linux)
  Templates requiring updates:
    - .specify/templates/plan-template.md ✅ updated (Constitution Check section aligned)
    - .specify/templates/spec-template.md ⚠ pending (no Apple-specific changes needed)
    - .specify/templates/tasks-template.md ⚠ pending (no Apple-specific changes needed)
    - .specify/templates/checklist-template.md ⚠ pending (no changes needed at this time)
  Follow-up TODOs: none
-->

# Swell Constitution

## Core Principles

### I. Code Quality (NON-NEGOTIABLE)

All production code MUST:
- Pass automated linting and static analysis before merge. SwiftLint rules
  MUST be enforced via CI gate and must match the project's `.swiftlint.yml`.
- Maintain a maximum cyclomatic complexity of 15 per function. Any
  exceedance MUST be justified in the PR description with a concrete
  simpler-alternative-rejected rationale.
- Be reviewed by at least one other contributor. Review MUST verify:
  correctness, test coverage, naming clarity, and absence of dead code.
- Never commit commented-out code, `print()`/`debugPrint()` statements,
  `fatalError()` without a documented invariant reason, or force-unwraps
  that are not preceded by an explicit `precondition` guard.
- Include doc comments on all `public` and `package` declarations using
  the standard Swift doc-comment format (`///`). Internal and private
  declarations SHOULD have inline comments when the intent is not obvious
  from the code.
- Be formatted according to the Swift Format configuration committed in the
  repository. Formatting MUST be checked in CI.

**Rationale**: Consistent code quality reduces maintenance burden, speeds
up onboarding, and prevents entire classes of defects before they reach
production.

### II. Swift Language Features

The project is written in Swift and MUST leverage the language's strengths:
- Use value types (`struct`, `enum`) as the default. Reference types
  (`class`) MUST be justified by an explicit need for identity, inheritance,
  or reference semantics.
- Use Swift's `Result` type, throwing functions, or `async throws` for
  error propagation. NSError pointer patterns are FORBIDDEN in new code.
- Use `Codable` for all serialization/deserialization. Manual
  `JSONSerialization` is FORBIDDEN unless Codable is provably insufficient
  (justification required in PR).
- Use `async/await` for all new asynchronous code. Callback-based and
  delegate-based concurrency MUST NOT be introduced unless integrating with
  a system library that requires it.
- Use Swift's opaque result types (`some` keyword) for implementation
  hiding. Existentials (`any`) SHOULD be used only when the type truly
  varies at runtime.
- Use `@main`, property wrappers, result builders, and other modern Swift
  features where idiomatic. Resist over-engineering with advanced generics
  or `@dynamicMemberLookup` unless the ergonomic win is clear and
  documented.
- Use Swift Package Manager for all dependency management. Never add
  dependencies without a review of their source code, license, and
  maintenance status.

**Rationale**: Adopting Swift's modern features uniformly makes the
codebase more predictable, safer (fewer nil crashes, no data races), and
more approachable for Swift developers.

### III. Testing Standards (NON-NEGOTIABLE)

All code MUST be tested. The test suite MUST be automated and run on every
PR via CI.
- **Test types**:
  - **Unit tests** (required): Every public function (and every significant
    private helper) MUST have at least one unit test. Use the Swift Testing
    framework (`#expect`, `#require` macros) or XCTest. Use test doubles
    (mocks/stubs) defined as protocols; avoid subclassing for testability.
  - **Integration tests** (required): Every user-facing flow, inter-process
    boundary, file-system interaction, and subprocess invocation MUST have
    an integration test. Integration tests MUST exercise real I/O paths.
  - **Output/snapshot tests** (required for CLI output): All user-visible
    output formats (stdout text, JSON, error messages, exit codes) MUST be
    covered by snapshot/assertion tests. Use `AssertJSON`, equality checks
    on captured output, or golden-file testing.
- **Discipline**:
  - Tests MUST be written **before** the implementation code (test-first).
    A PR that introduces untested code will be rejected.
  - Each test MUST be independent and hermetic. Tests MUST NOT depend on
    shared mutable state, test execution order, or global singletons.
  - Test names MUST describe the scenario and the expected outcome
    (e.g., `test_givenEmptyCart_whenCheckout_thenShowsEmptyError`).
  - Code coverage MUST be measured per target. The project-wide line
    coverage floor is 80%. Any decrease MUST be explained in the PR.
- **Performance & reliability**:
  - Tests MUST complete in under 5 seconds for the entire suite on a
    standard CI runner. Slow tests MUST be quarantined and fixed.
  - Flaky tests are treated as bugs. A flaky test MUST be disabled and a
    tracking issue filed within one business day.

**Rationale**: Rigorous testing is the only verifiable way to guarantee
correctness, prevent regressions, and enable confident refactoring. Without
it, Swift's strong type system catches type errors but not logic errors.

### IV. User Experience Consistency

Every user-facing component MUST adhere to a shared experience contract:
- **CLI conventions**: All commands MUST follow a consistent flag style
  (`--long-flag` with `-short` aliases), provide `--help` output, and
  respect the `--version` flag. Use a library like `Swift Argument Parser`
  for consistent command definition. Subcommands MUST follow the POSIX
  convention (`program subcommand --flag`).
- **Output format**: All commands MUST support both human-readable output
  (colorised terminal text with alignment) and machine-readable output
  (`--json` flag where applicable). Human output MUST use stderr for
  diagnostics and stdout for primary results only.
- **Error protocol**: Error messages MUST follow the convention:
  `error: <message>` on stderr, with a non-zero exit code. Unexpected
  errors MUST include a trace identifier or suggestion for filing a bug.
- **SHELL integration**: The shell MUST respect `$NO_COLOR`, `$CLICOLOR`,
  `$CLICOLOR_FORCE`, `$PAGER`, `$EDITOR`, and other standard environment
  variables. Every subprocess invocation MUST pass through relevant
  environment and signal handling (SIGINT, SIGPIPE).
- **Progress & feedback**: Operations longer than 200ms SHOULD show a
  spinner or progress indicator on stderr. Long-running operations MUST
  handle SIGINT gracefully (clean up temp files, restore terminal state).
- **Internationalization**: All user-visible strings MUST use
  `String(localized:)` or the equivalent. Hard-coded English strings in
  output formatting are FORBIDDEN. Right-to-left terminal output MUST be
  considered for formatted tables.
- **Accessibility for terminal**: Output MUST be parseable by screen
  readers (ORCA). Avoid ANSI sequences that confuse AT tools; prefer
  semantic markup where possible. Tabular output MUST use consistent
  delimiters so tools like `awk` and `cut` can consume it.
- **Consistency reviews**: Every feature with user-visible output MUST be
  reviewed by at least one other person for consistency before merge. Use
  checklists from the project's `.specify` templates.

**Rationale**: A consistent CLI experience reduces user confusion, enables
scripting and composition, respects terminal accessibility, and makes the
shell predictable across environments.

## Additional Constraints

- **Swift version**: The project targets the latest stable Swift release
  within one minor version. Swift Evolution proposals adopted MUST be
  tracked in `docs/adopted-evolution.md`.
- **Target platforms**: Linux (Ubuntu 22.04+, RHEL 9+, or the latest
  `swift:amazonlinux2` Docker image). CI MUST run on both x86_64 and
  ARM64. macOS builds are permitted for development but MUST not be the
  sole CI target.
- **Minimal dependencies**: Every Swift Package dependency MUST be vendored
  or pinned to a specific commit. Use `.package(url:from:)` for initial
  integration, then pin via `Package.resolved`. Review licenses for
  compatibility. Prefer depending only on `swift-argument-parser` and
  Foundation; avoid FoundationKit/dispatch where simple POSIX APIs suffice.
- **Portability**: All code MUST compile on Linux Swift. Use `#if os(macOS)`
  guards for any Apple-only APIs and document the guard rationale. The
  project MUST NOT depend on Combine, SwiftUI, UIKit, or any Apple
  platform framework.

## Development Workflow

1. **Feature branches**: All work MUST be done on a branch named
   `###-feature-name`. Branches MUST be short-lived (<3 days ideal).
2. **PRs**: Every PR MUST link to a spec (`.specify/specs/###-feature/`)
   and reference the corresponding user story. PR body MUST include:
   - Summary of changes
   - Test plan (what was tested and how)
   - Checklist of constitution principles verified
3. **CI gates**: Every PR MUST pass:
   - SwiftLint (zero warnings)
   - Swift Format validation
   - Full test suite (no failures)
   - Code coverage report (≥80%)
4. **Code review**: Each PR requires at least one approval. The reviewer
   MUST verify constitution compliance, test quality, and naming. Nitpicks
   are encouraged but MUST be marked as such with "nit:" prefix.
5. **Merge strategy**: Rebase-merge preferred. Squash-merge allowed for
   small fixes. Never merge with failing CI.

## Governance

- This constitution supersedes all informal practices. Any deviation from a
  MUST rule requires a documented exception in the PR body and a tracking
  issue to resolve the deviation.
- Amendments to this constitution MUST be proposed as a PR to
  `.specify/memory/constitution.md`. The PR MUST include:
  - The specific change and its rationale
  - A version bump (see below)
  - A migration plan if existing code is affected
- **Versioning policy**: MAJOR for principle removals/redefinitions; MINOR
  for new principles or materially expanded guidance; PATCH for
  clarifications, typo fixes, non-semantic refinements.
- **Compliance review**: Every quarter, the team MUST audit the codebase
  for compliance with this constitution. Non-compliant areas MUST be
  documented and scheduled for remediation.
- Use `AGENTS.md` for runtime development guidance and conventions that
  supplement but do not override this constitution.

**Version**: 1.1.0 | **Ratified**: 2026-06-23 | **Last Amended**: 2026-06-23
