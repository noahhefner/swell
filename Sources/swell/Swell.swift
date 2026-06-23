import ArgumentParser

@main
struct Swell: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swell",
        abstract: "A Linux shell written in Swift.",
        version: "0.1.0"
    )

    @Option(name: .long, help: "Use an alternate prompt config file.")
    var rcfile: String?

    mutating func run() throws {
        let repl = REPL()
        repl.run()
    }
}
