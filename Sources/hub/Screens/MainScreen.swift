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
        guard isGitRepo() else { return "git sync (no repo)" }
        if hasSyncPoint() {
            let ahead = commitsAhead()
            if let n = ahead, n > 0 {
                return "git sync (\(n) commits ahead)"
            }
            return "git sync (in sync)"
        }
        return "git sync (no sync point)"
    }

    private func channelHint() -> String {
        let path = "\(NSHomeDirectory())/.config/b2c-gsync/channel"
        if let id = try? String(contentsOfFile: path, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty {
            return "document cloud (channel: \(String(id.prefix(8)))…)"
        }
        return "document cloud (no channel)"
    }

    private func isGitRepo() -> Bool {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        p.arguments = ["rev-parse", "--is-inside-work-tree"]
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        try? p.run()
        p.waitUntilExit()
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return out == "true"
    }

    private func hasSyncPoint() -> Bool {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        p.arguments = ["rev-parse", "--git-dir"]
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        try? p.run()
        p.waitUntilExit()
        let gitDir = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ".git"

        let branch = currentBranch() ?? "main"
        let newPath = "\(gitDir)/gsync/branch/\(branch)/sync-point"
        let oldPath = "\(gitDir)/gsync/\(branch)/sync-point"
        return FileManager.default.fileExists(atPath: newPath) || FileManager.default.fileExists(atPath: oldPath)
    }

    private func currentBranch() -> String? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        p.arguments = ["rev-parse", "--abbrev-ref", "HEAD"]
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        try? p.run()
        p.waitUntilExit()
        let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return out.isEmpty ? nil : out
    }

    private func commitsAhead() -> Int? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        p.arguments = ["rev-parse", "--git-dir"]
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        try? p.run()
        p.waitUntilExit()
        let gitDir = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ".git"

        let branch = currentBranch() ?? "main"
        let newPath = "\(gitDir)/gsync/branch/\(branch)/sync-point"
        let oldPath = "\(gitDir)/gsync/\(branch)/sync-point"

        var syncHash: String?
        for path in [newPath, oldPath] {
            if let content = try? String(contentsOfFile: path, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines), !content.isEmpty {
                syncHash = content
                break
            }
        }
        guard let hash = syncHash else { return nil }

        let countProc = Process()
        countProc.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        countProc.arguments = ["rev-list", "--count", "\(hash)..HEAD"]
        let countPipe = Pipe()
        countProc.standardOutput = countPipe
        countProc.standardError = countPipe
        try? countProc.run()
        countProc.waitUntilExit()
        let countStr = String(data: countPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return Int(countStr)
    }
}
