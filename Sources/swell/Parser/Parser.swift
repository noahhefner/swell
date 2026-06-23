import Foundation

public struct ParsedCommand: Sendable {
    public var name: String
    public var arguments: [String]
    public var stdoutRedirect: RedirectTarget?
    public var stderrRedirect: RedirectTarget?

    public init(name: String, arguments: [String] = [],
                stdoutRedirect: RedirectTarget? = nil,
                stderrRedirect: RedirectTarget? = nil) {
        self.name = name
        self.arguments = arguments
        self.stdoutRedirect = stdoutRedirect
        self.stderrRedirect = stderrRedirect
    }
}

public enum RedirectTarget: Sendable, Equatable {
    case overwrite(String)
    case append(String)
}

public struct ParsedPipeline: Sendable {
    public var commands: [ParsedCommand]

    public init(commands: [ParsedCommand]) {
        self.commands = commands
    }
}

public enum ParseError: Error, Sendable, Equatable {
    case emptyInput
    case unexpectedToken(String)
    case missingFilename
    case unmatchedQuote
}

private enum RedirectStream {
    case stdout, stdoutAppend, stderr, stderrAppend
}

private struct ParseState {
    var commands: [ParsedCommand] = []
    var currentName: String?
    var currentArgs: [String] = []
    var currentStdout: RedirectTarget?
    var currentStderr: RedirectTarget?
    var expectingFilename = false
    var filenameFor: RedirectStream?

    mutating func flushCommand() {
        if let name = currentName {
            let cmd = ParsedCommand(
                name: name,
                arguments: currentArgs,
                stdoutRedirect: currentStdout,
                stderrRedirect: currentStderr
            )
            commands.append(cmd)
        }
        currentName = nil
        currentArgs = []
        currentStdout = nil
        currentStderr = nil
    }
}

public struct Parser: Sendable {
    public init() {}

    public func parse(_ input: String) throws -> ParsedPipeline {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ParseError.emptyInput }

        let tokens = try tokenize(trimmed)
        guard !tokens.isEmpty else { throw ParseError.emptyInput }

        var state = ParseState()

        try processTokens(tokens, state: &state)
        state.flushCommand()

        guard !state.commands.isEmpty else { throw ParseError.emptyInput }
        return ParsedPipeline(commands: state.commands)
    }

    private func tokenize(_ input: String) throws -> [Token] {
        var tokens: [Token] = []
        var i = input.startIndex

        while i < input.endIndex {
            let char = input[i]
            if char.isWhitespace {
                i = input.index(after: i)
                continue
            }

            if char == "|" {
                tokens.append(Token(.pipe))
                i = input.index(after: i)
                continue
            }

            if char == ">" {
                let next = input.index(after: i)
                if next < input.endIndex, input[next] == ">" {
                    tokens.append(Token(.redirectAppend))
                    i = input.index(after: next)
                } else {
                    tokens.append(Token(.redirectOut))
                    i = next
                }
                continue
            }

            let handled = try handlePotentialRedirectOrQuote(input: input, index: &i, tokens: &tokens)
            if !handled {
                i = input.index(after: i)
            }
        }

        return tokens
    }

    private func handlePotentialRedirectOrQuote(
        input: String,
        index: inout String.Index,
        tokens: inout [Token]
    ) throws -> Bool {
        let char = input[index]

        if char == "2" {
            let next = input.index(after: index)
            if next < input.endIndex, input[next] == ">" {
                let after = input.index(after: next)
                if after < input.endIndex, input[after] == ">" {
                    tokens.append(Token(.redirectErrAppend))
                    index = input.index(after: after)
                } else {
                    tokens.append(Token(.redirectErr))
                    index = after
                }
                return true
            }
        }

        if char == "'" || char == "\"" {
            try parseQuotedString(input: input, quote: char, index: &index, tokens: &tokens)
            return true
        }

        if !char.isWhitespace && char != "|" && char != ">" {
            parseWord(input: input, index: &index, tokens: &tokens)
            return true
        }

        return false
    }

    private func parseQuotedString(
        input: String,
        quote: Character,
        index: inout String.Index,
        tokens: inout [Token]
    ) throws {
        index = input.index(after: index)
        var value = ""
        while index < input.endIndex, input[index] != quote {
            if quote == "\"" && input[index] == "\\" {
                index = input.index(after: index)
                if index < input.endIndex {
                    value.append(input[index])
                    index = input.index(after: index)
                }
                continue
            }
            value.append(input[index])
            index = input.index(after: index)
        }
        guard index < input.endIndex else { throw ParseError.unmatchedQuote }
        index = input.index(after: index)
        tokens.append(Token(.command(value)))
    }

    private func parseWord(
        input: String,
        index: inout String.Index,
        tokens: inout [Token]
    ) {
        var value = ""
        while index < input.endIndex {
            let char = input[index]
            if char.isWhitespace || char == "|" || char == ">" { break }
            if char == "2" {
                let next = input.index(after: index)
                if next < input.endIndex, input[next] == ">" { break }
            }
            value.append(char)
            index = input.index(after: index)
        }
        if !value.isEmpty {
            tokens.append(Token(.command(value)))
        }
    }

    private func processTokens(
        _ tokens: [Token],
        state: inout ParseState
    ) throws {
        for token in tokens {
            if state.expectingFilename {
                try handleExpectingFilename(
                    token,
                    filenameFor: &state.filenameFor,
                    expectingFilename: &state.expectingFilename,
                    currentStdout: &state.currentStdout,
                    currentStderr: &state.currentStderr
                )
                continue
            }

            switch token.kind {
            case .command(let value):
                if state.currentName == nil {
                    state.currentName = value
                } else {
                    state.currentArgs.append(value)
                }
            case .pipe:
                state.flushCommand()
            case .redirectOut:
                state.expectingFilename = true
                state.filenameFor = .stdout
                state.currentStdout = nil
            case .redirectAppend:
                state.expectingFilename = true
                state.filenameFor = .stdoutAppend
            case .redirectErr:
                state.expectingFilename = true
                state.filenameFor = .stderr
                state.currentStderr = nil
            case .redirectErrAppend:
                state.expectingFilename = true
                state.filenameFor = .stderrAppend
            case .filename(let path):
                assignFilename(path, state: &state)
            }
        }
    }

    private func handleExpectingFilename(
        _ token: Token,
        filenameFor: inout RedirectStream?,
        expectingFilename: inout Bool,
        currentStdout: inout RedirectTarget?,
        currentStderr: inout RedirectTarget?
    ) throws {
        let path: String
        switch token.kind {
        case .filename(let name), .command(let name):
            path = name
        default:
            throw ParseError.missingFilename
        }
        switch filenameFor {
        case .stdout:
            currentStdout = .overwrite(path)
        case .stdoutAppend:
            currentStdout = .append(path)
        case .stderr:
            currentStderr = .overwrite(path)
        case .stderrAppend:
            currentStderr = .append(path)
        case nil:
            break
        }
        expectingFilename = false
        filenameFor = nil
    }

    private func assignFilename(
        _ path: String,
        state: inout ParseState
    ) {
        if let currentStdout = state.currentStdout {
            switch currentStdout {
            case .overwrite:
                state.currentStdout = .overwrite(path)
            case .append:
                state.currentStdout = .append(path)
            }
        } else if let currentStderr = state.currentStderr {
            switch currentStderr {
            case .overwrite:
                state.currentStderr = .overwrite(path)
            case .append:
                state.currentStderr = .append(path)
            }
        } else {
            if state.currentName == nil { state.currentName = path } else { state.currentArgs.append(path) }
        }
    }
}
