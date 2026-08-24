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
            MenuItem("channel", hint: "manage channel")  { self.channel() },
            .separator,
            MenuItem("backup",  hint: "export channel data") { self.backup() },
            MenuItem("restore", hint: "import channel data") { self.restore() },
            .separator,
            MenuItem("doc",     hint: "manage document") { self.doc() },
            .separator,
            .quit("Back")
        ]
        let version = binaryVersion(bin)
        let menu = Menu(terminal: terminal, title: "jcloud v\(version)", items: items)

        menu.run()
    }

    // MARK: - Command builders

    private func channel() {
        let items: [MenuItem] = [
            MenuItem("show",     hint: "show current channel")  { self.channelShow() },
            MenuItem("create",   hint: "create a new channel")  { self.channelCreate() },
            MenuItem("set",      hint: "set active channel")    { self.channelSet() },
            MenuItem("clear",    hint: "clear channel")         { self.channelClear() },
            .separator,
            MenuItem("slot-get", hint: "get a channel slot")    { self.channelSlotGet() },
            MenuItem("slot-set", hint: "set a channel slot")    { self.channelSlotSet() },
            .separator,
            .quit("Back")
        ]
        let menu = Menu(terminal: terminal, title: "jcloud channel", items: items)

        menu.run()
    }
    
    private func channelShow() {
        runner.run(binary: bin, arguments: ["channel", "show"])
    }
    
    private func channelCreate() {
        let configFile = "\(NSHomeDirectory())/.config/b2c-gsync/channel"
        if let existing = try? String(contentsOfFile: configFile, encoding: .utf8),
           !existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let id = existing.trimmingCharacters(in: .whitespacesAndNewlines)
            // Has existing channel — ask confirmation via menu
            let items: [MenuItem] = [
                MenuItem("Yes, replace it", hint: "create new channel") {
                    self.runner.run(binary: bin, arguments: ["channel", "create"])
                },
                .quit("No, keep current"),
            ]
            let menu = Menu(terminal: terminal, title: "Channel exists: \(id)", items: items)
            menu.run()
        } else {
            runner.run(binary: bin, arguments: ["channel", "create"])
        }
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
    
    private func channelClear() {
        let configFile = "\(NSHomeDirectory())/.config/b2c-gsync/channel"
        guard let existing = try? String(contentsOfFile: configFile, encoding: .utf8),
              !existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            runner.run(binary: bin, arguments: ["channel", "clear"])
            return
        }
        let id = existing.trimmingCharacters(in: .whitespacesAndNewlines)
        let items: [MenuItem] = [
            MenuItem("Yes, clear it") {
                self.runner.run(binary: bin, arguments: ["channel", "clear"])
            },
            .quit("No, keep current"),
        ]
        let menu = Menu(terminal: terminal, title: "Clear channel: \(id)?", items: items)
        menu.run()
    }

    private func channelSlotGet() {
        guard let slots = loadSlotNames() else {
            // Fallback to form if can't read channel
            let form = Form(
                terminal: terminal,
                title: "jcloud channel slot-get",
                fields: [FormField("slot name")]
            )
            guard let values = form.run() else { return }
            runner.run(binary: bin, arguments: ["channel", "slot-get", values[0]])
            return
        }

        guard !slots.isEmpty else {
            runner.run(binary: bin, arguments: ["channel", "show"])
            return
        }

        var items: [MenuItem] = slots.map { slot in
            MenuItem(slot.name, hint: slot.id) {
                self.runner.run(binary: bin, arguments: ["channel", "slot-get", slot.name])
            }
        }
        items.append(.separator)
        items.append(.quit("Back"))
		
        let menu = Menu(terminal: terminal, title: "jcloud channel slot-get", items: items)
        menu.run()
    }

    private func channelSlotSet() {
        let slots = loadSlotNames() ?? []

        if slots.isEmpty {
            // No slots yet — use form
            let form = Form(
                terminal: terminal,
                title: "jcloud channel slot-set",
                fields: [
                    FormField("slot name"),
                    FormField("document ID"),
                ]
            )
            guard let values = form.run() else { return }
            runner.run(binary: bin, arguments: ["channel", "slot-set", values[0], values[1]])
            return
        }

        // Show existing slots + option to create new
        var items: [MenuItem] = slots.map { slot in
            MenuItem(slot.name, hint: slot.id) {
                self.channelSlotSetID(slot: slot.name)
            }
        }
        items.append(.separator)
        items.append(MenuItem("+ new slot") { self.channelSlotSetID(slot: "__new__") })
        items.append(.separator)
        items.append(.quit("Back"))

        let menu = Menu(terminal: terminal, title: "jcloud channel slot-set — select slot", items: items)
        menu.run()
    }
	
    private func channelSlotSetID(slot: String) {
        var slotName = slot
        if slotName == "__new__" {
            let form = Form(
                terminal: terminal,
                title: "jcloud channel slot-set",
                fields: [FormField("slot name")]
            )
            guard let values = form.run() else { return }
            slotName = values[0]
        }

        let form = Form(
            terminal: terminal,
            title: "jcloud channel slot-set [\(slotName)]",
            fields: [FormField("document ID")]
        )
        guard let values = form.run() else { return }
        runner.run(binary: bin, arguments: ["channel", "slot-set", slotName, values[0]])
    }

    // MARK: - Helpers

    private struct SlotInfo {
        let name: String
        let id: String
    }

    private func loadSlotNames() -> [SlotInfo]? {
        let configFile = "\(NSHomeDirectory())/.config/b2c-gsync/channel"
        guard let channelId = try? String(contentsOfFile: configFile, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !channelId.isEmpty else { return nil }

        // Read channel document via jcloud
        let process = Process()
        process.executableURL = URL(fileURLWithPath: bin)
        process.arguments = ["doc", "read", channelId]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let slots = json["slots"] as? [String: Any] else { return nil }

        return slots.compactMap { key, value in
            guard let entry = value as? [String: Any],
                  let id = entry["id"] as? String else { return nil }
            return SlotInfo(name: key, id: String(id.prefix(12)) + "…")
        }.sorted { $0.name < $1.name }
    }


    private func backup() {
        let form = Form(
            terminal: terminal,
            title: "jcloud backup",
            fields: [
                FormField("output file", placeholder: "leave empty for stdout", required: false),
            ]
        )
        guard let values = form.run() else { return }
        var args = ["backup"]
        if !values[0].isEmpty { args.append(values[0]) }
        runner.run(binary: bin, arguments: args)
    }

    private func restore() {
        let form = Form(
            terminal: terminal,
            title: "jcloud restore",
            fields: [
                FormField("file path"),
            ]
        )
        guard let values = form.run() else { return }
        runner.run(binary: bin, arguments: ["restore", values[0]])
    }

    private func doc() {
        let items: [MenuItem] = [
            MenuItem("create",       hint: "create a document")     { self.docCreate() },
            MenuItem("read",         hint: "read a document by ID") { self.docRead() },
            MenuItem("update",       hint: "update a document")     { self.docUpdate() },
            MenuItem("delete",       hint: "delete a document")     { self.docDelete() },
            .separator,
            .quit("Back")
        ]
        let menu = Menu(terminal: terminal, title: "jcloud doc", items: items)

        menu.run()
    }
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
}
