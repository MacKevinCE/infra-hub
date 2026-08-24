import Foundation

private let bin = findBinary("b2c")

// MARK: - B2CScreen

final class B2CScreen {
    private let terminal: Terminal
    private let runner: Runner

    init(terminal: Terminal, runner: Runner) {
        self.terminal = terminal
        self.runner   = runner
    }

    func run() {
        let items: [MenuItem] = [
            MenuItem("upload",   hint: "upload file or directory")  { self.upload() },
            MenuItem("download", hint: "download by index ID")      { self.download() },
            .separator,
            MenuItem("list",     hint: "show upload history")        { self.list() },
            MenuItem("info",     hint: "view index metadata")       { self.info() },
            MenuItem("delete",   hint: "delete index + all chunks") { self.delete() },
            .separator,
            .quit("Back")
        ]
        let version = binaryVersion(bin)
        let menu = Menu(terminal: terminal, title: "b2c v\(version)", items: items)

        menu.run()
    }

    // MARK: - Command builders

    private func upload() {
        let form = Form(
            terminal: terminal,
            title: "b2c upload",
            fields: [
                FormField("file or directory", placeholder: "leave empty for current dir", required: false),
                FormField("chunk size (-k KB)", placeholder: "e.g. 512", required: false),
            ]
        )
        guard let values = form.run() else { return }
        let path = values[0].isEmpty ? "." : values[0]

        // Estimate chunks and confirm if large
        let chunkKB = Int(values[1]) ?? 900
        let size = pathSize(path)
        let parts = estimateChunks(bytes: size, chunkKB: chunkKB)

        if parts > 10 {
            let sizeMB = String(format: "%.1f", Double(size) / 1_048_576)
            let items: [MenuItem] = [
                MenuItem("Yes, upload", hint: "\(sizeMB) MB, ~\(parts) parts") {
                    var args = ["upload", path]
                    if !values[1].isEmpty { args += ["-k", values[1]] }
                    self.runner.run(binary: bin, arguments: args)
                },
                .quit("Cancel"),
            ]
            let menu = Menu(terminal: terminal, title: "Large upload (~\(parts) parts)", items: items)
            menu.run()
        } else {
            var args = ["upload", path]
            if !values[1].isEmpty { args += ["-k", values[1]] }
            runner.run(binary: bin, arguments: args)
        }
    }

    private func pathSize(_ path: String) -> Int {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &isDir) else { return 0 }

        if !isDir.boolValue {
            return (try? fm.attributesOfItem(atPath: path)[.size] as? Int) ?? 0
        }

        var total = 0
        if let enumerator = fm.enumerator(atPath: path) {
            while let file = enumerator.nextObject() as? String {
                if let attrs = try? fm.attributesOfItem(atPath: "\(path)/\(file)"),
                   let size = attrs[.size] as? Int {
                    total += size
                }
            }
        }
        return total
    }

    private func estimateChunks(bytes: Int, chunkKB: Int) -> Int {
        let compressed = Double(bytes) * 0.5
        let base64 = compressed * 4.0 / 3.0
        let chunkSize = Double(chunkKB) * 1024.0
        return max(1, Int(ceil(base64 / chunkSize)))
    }

    private func list() {
        runner.run(binary: bin, arguments: ["list"])
    }

    private func info() {
        let form = Form(
            terminal: terminal,
            title: "b2c info",
            fields: [
                FormField("index ID"),
            ]
        )
        guard let values = form.run() else { return }
        runner.run(binary: bin, arguments: ["info", values[0]])
    }

    private func delete() {
        let form = Form(
            terminal: terminal,
            title: "b2c delete",
            fields: [
                FormField("index ID", placeholder: "deletes index + all chunks"),
            ]
        )
        guard let values = form.run() else { return }
        runner.run(binary: bin, arguments: ["delete", values[0]])
    }

    private func download() {
        let form = Form(
            terminal: terminal,
            title: "b2c download",
            fields: [
                FormField("index ID", placeholder: "leave empty for latest", required: false),
                FormField("output directory (-o)", placeholder: "leave empty for current dir", required: false),
            ]
        )
        guard let values = form.run() else { return }
        var args = ["download"]
        if !values[0].isEmpty { args.append(values[0]) }
        if !values[1].isEmpty { args += ["-o", values[1]] }
        runner.run(binary: bin, arguments: args)
    }
}
