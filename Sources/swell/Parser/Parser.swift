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

public struct Parser: Sendable {
    public init() {}

    public func parse(_ input: String) throws -> ParsedPipeline {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ParseError.emptyInput }

        let tokens = try tokenize(trimmed)
        guard !tokens.isEmpty else { throw ParseError.emptyInput }

        var commands: [ParsedCommand] = []
        var currentName: String?
        var currentArgs: [String] = []
        var currentStdout: RedirectTarget?
        var currentStderr: RedirectTarget?
        var expectingFilename = false
        var filenameFor: RedirectStream?

        enum RedirectStream {
            case stdout, stdoutAppend, stderr, stderrAppend
        }

        func flushCommand() {
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

        for token in tokens {
            if expectingFilename {
                let path: String
                switch token.kind {
                case .filename(let p), .command(let p):
                    path = p
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
                continue
            }

            switch token.kind {
            case .command(let value):
                if currentName == nil {
                    currentName = value
                } else {
                    currentArgs.append(value)
                }
            case .pipe:
                flushCommand()
            case .redirectOut:
                expectingFilename = true
                filenameFor = .stdout
                currentStdout = nil
            case .redirectAppend:
                expectingFilename = true
                filenameFor = .stdoutAppend
            case .redirectErr:
                expectingFilename = true
                filenameFor = .stderr
                currentStderr = nil
            case .redirectErrAppend:
                expectingFilename = true
                filenameFor = .stderrAppend
            case .filename(let path):
                if currentStdout != nil {
                    let target: RedirectTarget
                    switch currentStdout! {
                    case .overwrite: target = .overwrite(path)
                    case .append: target = .append(path)
                    }
                    currentStdout = target
                } else if currentStderr != nil {
                    let target: RedirectTarget
                    switch currentStderr! {
                    case .overwrite: target = .overwrite(path)
                    case .append: target = .append(path)
                    }
                    currentStderr = target
                } else {
                    if currentName == nil { currentName = path }
                    else { currentArgs.append(path) }
                }
            }
        }
        flushCommand()

        guard !commands.isEmpty else { throw ParseError.emptyInput }
        return ParsedPipeline(commands: commands)
    }

    private func currentStdoutFromToken(_ kind: TokenKind, path: String) -> RedirectTarget {
        path.isEmpty ? .overwrite(path) : .overwrite(path)
    }

    private func currentStderrFromToken(_ kind: TokenKind, path: String) -> RedirectTarget {
        path.isEmpty ? .overwrite(path) : .overwrite(path)
    }

    private func tokenize(_ input: String) throws -> [Token] {
        var tokens: [Token] = []
        var i = input.startIndex

        while i < input.endIndex {
            if input[i].isWhitespace {
                i = input.index(after: i)
                continue
            }

            if input[i] == "|" {
                tokens.append(Token(.pipe))
                i = input.index(after: i)
                continue
            }

            if input[i] == ">" {
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

            if input[i] == "2" {
                let next = input.index(after: i)
                if next < input.endIndex, input[next] == ">" {
                    let after = input.index(after: next)
                    if after < input.endIndex, input[after] == ">" {
                        tokens.append(Token(.redirectErrAppend))
                        i = input.index(after: after)
                    } else {
                        tokens.append(Token(.redirectErr))
                        i = after
                    }
                    continue
                }
            }

            if input[i] == "'" || input[i] == "\"" {
                let quote = input[i]
                i = input.index(after: i)
                var value = ""
                while i < input.endIndex, input[i] != quote {
                    if quote == "\"" && input[i] == "\\" {
                        i = input.index(after: i)
                        if i < input.endIndex {
                            value.append(input[i])
                            i = input.index(after: i)
                        }
                        continue
                    }
                    value.append(input[i])
                    i = input.index(after: i)
                }
                guard i < input.endIndex else { throw ParseError.unmatchedQuote }
                i = input.index(after: i)
                tokens.append(Token(.command(value)))
            } else {
                var value = ""
                while i < input.endIndex, !input[i].isWhitespace && input[i] != "|" && input[i] != ">" {
                    if input[i] == "2" {
                        let next = input.index(after: i)
                        if next < input.endIndex, input[next] == ">" { break }
                    }
                    value.append(input[i])
                    i = input.index(after: i)
                }
                if !value.isEmpty {
                    tokens.append(Token(.command(value)))
                }
            }
        }

        return tokens
    }
}
