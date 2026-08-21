import Foundation

private let bin = findBinary("gsync")

// MARK: - GsyncScreen

final class GsyncScreen {
    private let terminal: Terminal
    private let runner: Runner

    init(terminal: Terminal, runner: Runner) {
        self.terminal = terminal
        self.runner   = runner
    }

    func run() {
        let items: [MenuItem] = [
            MenuItem("push",     hint: "push commits [range]")    { self.push() },
            MenuItem("pull",     hint: "pull by index ID")         { self.pull() },
            .separator,
            MenuItem("mark",     hint: "mark a commit")            { self.mark() },
            .separator,
            MenuItem("status",   hint: "show sync status")         { self.runner.run(binary: bin, arguments: ["status"]) },
            MenuItem("snapshot", hint: "snapshot [manifestId]")     { self.snapshot() },
            MenuItem("sync",     hint: "sync [snapshotId]")        { self.sync() },
            .separator,
            MenuItem("ignore",   hint: "manage ignore patterns")   { self.ignore() },
        ]
        let version = binaryVersion(bin)
        let menu = Menu(terminal: terminal, title: "gsync v\(version)", items: items)

        while menu.run() != nil {}
    }

    // MARK: - Command builders

    private func push() {
        let form = Form(
            terminal: terminal,
            title: "gsync push",
            fields: [
                FormField("range", placeholder: "e.g. HEAD~3..HEAD or leave empty", required: false),
            ]
        )
        guard let values = form.run() else { return }
        var args = ["push"]
        if !values[0].isEmpty { args.append(values[0]) }
        runner.run(binary: bin, arguments: args)
    }

    private func pull() {
        let form = Form(
            terminal: terminal,
            title: "gsync pull",
            fields: [
                FormField("index ID", placeholder: "leave empty for latest", required: false),
            ]
        )
        guard let values = form.run() else { return }
        var args = ["pull"]
        if !values[0].isEmpty { args.append(values[0]) }
        runner.run(binary: bin, arguments: args)
    }

    private func mark() {
        let form = Form(
            terminal: terminal,
            title: "gsync mark",
            fields: [
                FormField("commit hash or ref"),
            ]
        )
        guard let values = form.run() else { return }
        runner.run(binary: bin, arguments: ["mark", values[0]])
    }

    private func snapshot() {
        let form = Form(
            terminal: terminal,
            title: "gsync snapshot",
            fields: [
                FormField("manifest ID", placeholder: "leave empty for latest", required: false),
            ]
        )
        guard let values = form.run() else { return }
        var args = ["snapshot"]
        if !values[0].isEmpty { args.append(values[0]) }
        runner.run(binary: bin, arguments: args)
    }

    private func ignore() {
        let items: [MenuItem] = [
            MenuItem("show",   hint: "show current patterns") { self.runner.run(binary: bin, arguments: ["ignore"]) },
            MenuItem("add",    hint: "add modified files or pattern") { self.ignoreAdd() },
            MenuItem("remove", hint: "remove a pattern") { self.ignoreRemove() },
        ]
        let menu = Menu(terminal: terminal, title: "gsync ignore", items: items)

        while menu.run() != nil {}
    }

    private func ignoreAdd() {
        let form = Form(
            terminal: terminal,
            title: "gsync ignore add",
            fields: [
                FormField("pattern", placeholder: "leave empty to auto-detect modified files", required: false),
            ]
        )
        guard let values = form.run() else { return }
        var args = ["ignore", "add"]
        if !values[0].isEmpty { args.append(values[0]) }
        runner.run(binary: bin, arguments: args)
    }

    private func ignoreRemove() {
        let form = Form(
            terminal: terminal,
            title: "gsync ignore remove",
            fields: [
                FormField("pattern"),
            ]
        )
        guard let values = form.run() else { return }
        runner.run(binary: bin, arguments: ["ignore", "remove", values[0]])
    }

    private func sync() {
        let form = Form(
            terminal: terminal,
            title: "gsync sync",
            fields: [
                FormField("snapshot ID", placeholder: "leave empty for latest", required: false),
            ]
        )
        guard let values = form.run() else { return }
        var args = ["sync"]
        if !values[0].isEmpty { args.append(values[0]) }
        runner.run(binary: bin, arguments: args)
    }
}
