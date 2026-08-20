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
            MenuItem("b2c",    hint: "blob store"),
            MenuItem("gsync",  hint: "git sync"),
            MenuItem("jcloud", hint: "document cloud"),
            .separator,
            MenuItem("Quit"),
        ]
        let menu = Menu(terminal: terminal, title: "infra-hub v\(hubVersion)", items: items)

        while true {
            guard let choice = menu.run() else { break }

            switch choice {
            case 0: B2CScreen(terminal: terminal, runner: runner).run()
            case 1: GsyncScreen(terminal: terminal, runner: runner).run()
            case 2: JcloudScreen(terminal: terminal, runner: runner).run()
            default: break // Quit or unknown — exit loop below
            }

            if choice == 4 { break }
        }
    }
}
