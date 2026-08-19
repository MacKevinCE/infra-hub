import Foundation

private let bin = "/usr/local/bin/b2c"

// MARK: - B2CScreen

final class B2CScreen {
    private let terminal: Terminal
    private let runner: Runner

    init(terminal: Terminal, runner: Runner) {
        self.terminal = terminal
        self.runner   = runner
    }

    func run() {
        let version = binaryVersion(bin)
        let items: [MenuItem] = [
            MenuItem("upload",   hint: "upload file or directory"),
            MenuItem("download", hint: "download by index ID"),
            MenuItem("delete",   hint: "delete index + all chunks"),
        ]
        let menu = Menu(terminal: terminal, title: "b2c v\(version)", items: items)

        while true {
            guard let choice = menu.run() else { return }

            switch choice {
            case 0: upload()
            case 1: download()
            case 2: delete()
            default: break
            }
        }
    }

    // MARK: - Command builders

    private func upload() {
        let form = Form(
            terminal: terminal,
            title: "b2c upload",
            fields: [
                FormField("file or directory", placeholder: "path to file or directory"),
                FormField("chunk size (-k KB)", placeholder: "e.g. 512", required: false),
            ]
        )
        guard let values = form.run() else { return }
        var args = ["upload", values[0]]
        if !values[1].isEmpty { args += ["-k", values[1]] }
        runner.run(binary: bin, arguments: args)
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
