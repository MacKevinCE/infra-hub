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
        let items: [MenuItem] = [
            MenuItem("upload",          hint: "upload file or directory"),
            MenuItem("download",        hint: "download by index ID"),
            MenuItem("delete",          hint: "delete by index ID"),
            MenuItem("channel create",  hint: "create a new channel"),
            MenuItem("channel set",     hint: "set active channel"),
            MenuItem("channel show",    hint: "show current channel"),
            MenuItem("channel clear",   hint: "clear channel"),
        ]
        let menu = Menu(terminal: terminal, title: "b2c", items: items)

        while true {
            guard let choice = menu.run() else { return }

            switch choice {
            case 0: upload()
            case 1: download()
            case 2: delete()
            case 3: runner.run(binary: bin, arguments: ["channel", "create"])
            case 4: channelSet()
            case 5: runner.run(binary: bin, arguments: ["channel", "show"])
            case 6: runner.run(binary: bin, arguments: ["channel", "clear"])
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

    private func delete() {
        let form = Form(
            terminal: terminal,
            title: "b2c delete",
            fields: [
                FormField("index ID"),
            ]
        )
        guard let values = form.run() else { return }
        runner.run(binary: bin, arguments: ["delete", values[0]])
    }

    private func channelSet() {
        let form = Form(
            terminal: terminal,
            title: "b2c channel set",
            fields: [
                FormField("channel ID"),
            ]
        )
        guard let values = form.run() else { return }
        runner.run(binary: bin, arguments: ["channel", "set", values[0]])
    }
}
