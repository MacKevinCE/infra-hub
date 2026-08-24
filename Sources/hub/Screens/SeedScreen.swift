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
        let allTools = ["b2c", "gsync", "hub", "jcloud", "seed"]
        var checkItems: [ChecklistItem] = []

        for tool in allTools {
            let path = findBinary(tool)
            let ver = binaryVersion(path)
            checkItems.append(ChecklistItem(tool, hint: "v\(ver)", selected: true))
        }

        let checklist = Checklist(
            terminal: terminal,
            title: "seed publish — select tools",
            items: checkItems
        )
        guard let selected = checklist.run(), !selected.isEmpty else { return }
        runner.run(binary: bin, arguments: ["publish"] + selected)
    }
}
