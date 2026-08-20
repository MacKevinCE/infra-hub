import Foundation

private let bin = "/usr/local/bin/jcloud"

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
            MenuItem("channel create",   hint: "create a new channel"),
            MenuItem("channel set",      hint: "set active channel"),
            MenuItem("channel show",     hint: "show current channel"),
            MenuItem("channel clear",    hint: "clear channel"),
            .separator,
            MenuItem("channel slot-get", hint: "get a channel slot"),
            MenuItem("channel slot-set", hint: "set a channel slot"),
            .separator,
            MenuItem("publish",          hint: "publish tools"),
            MenuItem("update",           hint: "update jcloud"),
            .separator,
            MenuItem("doc create",       hint: "create a document"),
            MenuItem("doc read",         hint: "read a document by ID"),
            MenuItem("doc update",       hint: "update a document"),
            MenuItem("doc delete",       hint: "delete a document"),
        ]
        let version = binaryVersion(bin)
        let menu = Menu(terminal: terminal, title: "jcloud v\(version)", items: items)

        while true {
            guard let choice = menu.run() else { return }

            switch choice {
            case 0:  runner.run(binary: bin, arguments: ["channel", "create"])
            case 1:  channelSet()
            case 2:  runner.run(binary: bin, arguments: ["channel", "show"])
            case 3:  runner.run(binary: bin, arguments: ["channel", "clear"])
            case 5:  channelSlotGet()
            case 6:  channelSlotSet()
            case 8: publish()
            case 9: runner.run(binary: bin, arguments: ["update"])
            case 11: docCreate()
            case 12: docRead()
            case 13: docUpdate()
            case 14: docDelete()
            default: break
            }
        }
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
        // Split on whitespace to get individual tool names
        let tools = values[0].split(separator: " ").map(String.init)
        runner.run(binary: bin, arguments: ["publish"] + tools)
    }
}
