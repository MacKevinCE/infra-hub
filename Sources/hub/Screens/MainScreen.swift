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
            MenuItem("b2c",    hint: "blob store")     { B2CScreen(terminal: self.terminal, runner: self.runner).run() },
            MenuItem("gsync",  hint: gsyncHint())      { GsyncScreen(terminal: self.terminal, runner: self.runner).run() },
            MenuItem("jcloud", hint: channelHint())    { JcloudScreen(terminal: self.terminal, runner: self.runner).run() },
            .separator,
            MenuItem("doctor", hint: "check tools and config") { DoctorScreen(terminal: self.terminal).run() },
            .separator,
            .quit(),
        ]
        let menu = Menu(terminal: terminal, title: "infra-hub v\(hubVersion)", items: items)

        menu.run()
    }

    // MARK: - Status hints

    private func gsyncHint() -> String {
        guard GitInfo.isRepo() else { return "git sync (no repo)" }
        guard GitInfo.syncPoint() != nil else { return "git sync (no sync point)" }
        if let n = GitInfo.commitsAhead(), n > 0 {
            return "git sync (\(n) commits ahead)"
        }
        return "git sync (in sync)"
    }

    private func channelHint() -> String {
        if let id = GitInfo.channelId() {
            return "document cloud (channel: \(String(id.prefix(8)))…)"
        }
        return "document cloud (no channel)"
    }
}
