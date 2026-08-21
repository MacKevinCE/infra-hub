import Foundation

// MARK: - MainScreen

final class MainScreen {
    private let terminal: Terminal
    private let runner: Runner

    init(terminal: Terminal) {
        self.terminal = terminal
        self.runner   = Runner(terminal: terminal)
    }

    func run() {
        let items: [MenuItem] = [
            MenuItem("b2c",    hint: "blob store")    { B2CScreen(terminal: self.terminal, runner: self.runner).run() },
            MenuItem("gsync",  hint: "git sync")      { GsyncScreen(terminal: self.terminal, runner: self.runner).run() },
            MenuItem("jcloud", hint: "document cloud") { JcloudScreen(terminal: self.terminal, runner: self.runner).run() },
            .separator,
            MenuItem("Quit"),
        ]
        let menu = Menu(terminal: terminal, title: "infra-hub v\(hubVersion)", items: items)

		while menu.run() != nil {}
    }
}
