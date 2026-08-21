import Foundation

private let bin = findBinary("seed")

// MARK: - SeedScreen

final class SeedScreen {
    private let terminal: Terminal
    private let runner: Runner

    init(terminal: Terminal, runner: Runner) {
        self.terminal = terminal
        self.runner   = runner
    }

    func run() {
        let items: [MenuItem] = [
            MenuItem("publish",   hint: "publish tools to channel") { self.publish() },
            MenuItem("update",    hint: "install updated tools")     { self.runner.run(binary: bin, arguments: ["update"]) },
            MenuItem("replicate", hint: "bootstrap script for new machine") { self.runner.run(binary: bin, arguments: ["replicate"]) },
            .separator,
            .quit("Back"),
        ]
        let version = binaryVersion(bin)
        let menu = Menu(terminal: terminal, title: "seed v\(version)", items: items)

        menu.run()
    }

    private func publish() {
        let form = Form(
            terminal: terminal,
            title: "seed publish",
            fields: [
                FormField("tools (space-separated)", placeholder: "e.g. b2c gsync jcloud hub seed"),
            ]
        )
        guard let values = form.run() else { return }
        let tools = values[0].split(separator: " ").map(String.init)
        runner.run(binary: bin, arguments: ["publish"] + tools)
    }
}
