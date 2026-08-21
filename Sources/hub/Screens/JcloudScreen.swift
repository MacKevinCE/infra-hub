import Foundation

private let bin = findBinary("jcloud")

// MARK: - JcloudScreen

final class JcloudScreen {
    private let terminal: Terminal
    private let runner: Runner

    init(terminal: Terminal, runner: Runner) {
        self.terminal = terminal
        self.runner   = runner
    }

    func run() {
        let items: [MenuItem] = [
            MenuItem("channel create",   hint: "create a new channel")  { self.runner.run(binary: bin, arguments: ["channel", "create"]) },
            MenuItem("channel set",      hint: "set active channel")    { self.channelSet() },
            MenuItem("channel show",     hint: "show current channel")  { self.runner.run(binary: bin, arguments: ["channel", "show"]) },
            MenuItem("channel clear",    hint: "clear channel")         { self.runner.run(binary: bin, arguments: ["channel", "clear"]) },
            .separator,
            MenuItem("channel slot-get", hint: "get a channel slot")    { self.channelSlotGet() },
            MenuItem("channel slot-set", hint: "set a channel slot")    { self.channelSlotSet() },
            .separator,
            MenuItem("publish",          hint: "publish tools")         { self.publish() },
            MenuItem("update",           hint: "update jcloud")         { self.runner.run(binary: bin, arguments: ["update"]) },
            .separator,
            MenuItem("doc create",       hint: "create a document")     { self.docCreate() },
            MenuItem("doc read",         hint: "read a document by ID") { self.docRead() },
            MenuItem("doc update",       hint: "update a document")     { self.docUpdate() },
            MenuItem("doc delete",       hint: "delete a document")     { self.docDelete() },
        ]
        let version = binaryVersion(bin)
        let menu = Menu(terminal: terminal, title: "jcloud v\(version)", items: items)

        while menu.run() != nil {}
    }

    // MARK: - Command builders

    private func docCreate() {
        let form = Form(
            terminal: terminal,
            title: "jcloud doc create",
            fields: [
                FormField("name"),
                FormField("content"),
            ]
        )
        guard let values = form.run() else { return }
        runner.run(binary: bin, arguments: ["doc", "create", values[0], values[1]])
    }

    private func docRead() {
        let form = Form(
            terminal: terminal,
            title: "jcloud doc read",
            fields: [
                FormField("document ID"),
            ]
        )
        guard let values = form.run() else { return }
        runner.run(binary: bin, arguments: ["doc", "read", values[0]])
    }

    private func docUpdate() {
        let form = Form(
            terminal: terminal,
            title: "jcloud doc update",
            fields: [
                FormField("document ID"),
                FormField("new content"),
            ]
        )
        guard let values = form.run() else { return }
        runner.run(binary: bin, arguments: ["doc", "update", values[0], values[1]])
    }

    private func docDelete() {
        let form = Form(
            terminal: terminal,
            title: "jcloud doc delete",
            fields: [
                FormField("document ID"),
            ]
        )
        guard let values = form.run() else { return }
        runner.run(binary: bin, arguments: ["doc", "delete", values[0]])
    }

    private func channelSet() {
        let form = Form(
            terminal: terminal,
            title: "jcloud channel set",
            fields: [
                FormField("channel ID"),
            ]
        )
        guard let values = form.run() else { return }
        runner.run(binary: bin, arguments: ["channel", "set", values[0]])
    }

    private func channelSlotGet() {
        let form = Form(
            terminal: terminal,
            title: "jcloud channel slot-get",
            fields: [
                FormField("slot name or number"),
            ]
        )
        guard let values = form.run() else { return }
        runner.run(binary: bin, arguments: ["channel", "slot-get", values[0]])
    }

    private func channelSlotSet() {
        let form = Form(
            terminal: terminal,
            title: "jcloud channel slot-set",
            fields: [
                FormField("slot name or number"),
                FormField("document ID"),
            ]
        )
        guard let values = form.run() else { return }
        runner.run(binary: bin, arguments: ["channel", "slot-set", values[0], values[1]])
    }

    private func publish() {
        let form = Form(
            terminal: terminal,
            title: "jcloud publish",
            fields: [
                FormField("tools (space-separated)", placeholder: "e.g. tool1 tool2 tool3"),
            ]
        )
        guard let values = form.run() else { return }
        let tools = values[0].split(separator: " ").map(String.init)
        runner.run(binary: bin, arguments: ["publish"] + tools)
    }
}
