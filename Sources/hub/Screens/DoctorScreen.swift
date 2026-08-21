import Foundation

// MARK: - DoctorScreen

final class DoctorScreen {
    private let terminal: Terminal

    init(terminal: Terminal) {
        self.terminal = terminal
    }

    func run() {
        terminal.suspendRawMode()
        terminal.clearScreen()

        let cols = terminal.size().cols
        let sepWidth = max(10, min(cols - 2, 60))

        print(ANSI.bold + ANSI.fgCyan + "  hub doctor" + ANSI.reset)
        print(String(repeating: "─", count: sepWidth))
        print()

        // Check tools with minimum versions
        print(ANSI.bold + "  Tools:" + ANSI.reset)
        let requirements: [(name: String, minVersion: String?)] = [
            ("jcloud", "1.3.0"),
            ("b2c",    "1.8.0"),
            ("gsync",  "1.11.0"),
            ("git",    nil),
        ]
        var allFound = true
        for req in requirements {
            let path = findBinary(req.name)
            let version = binaryVersion(path)
            let exists = FileManager.default.isExecutableFile(atPath: path)
            if exists {
                let minLabel = req.minVersion != nil ? " (min: \(req.minVersion!))" : ""
                print("  \(ANSI.fgGreen)✓\(ANSI.reset) \(pad(req.name, 8)) \(pad(version, 8)) \(path)\(minLabel)")
            } else {
                let minLabel = req.minVersion ?? ""
                print("  \(ANSI.fgRed)✗\(ANSI.reset) \(req.name) — not found in PATH (requires \(minLabel)+)")
                allFound = false
            }
        }
        print()

        // Check channel
        print(ANSI.bold + "  Channel:" + ANSI.reset)
        let channelPath = "\(NSHomeDirectory())/.config/b2c-gsync/channel"
        if let channelId = try? String(contentsOfFile: channelPath, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines), !channelId.isEmpty {
            print("  \(ANSI.fgGreen)✓\(ANSI.reset) Configured: \(channelId)")
        } else {
            print("  \(ANSI.fgRed)✗\(ANSI.reset) No channel configured (run: jcloud channel create)")
        }
        print()

        // Check git repo + sync point
        print(ANSI.bold + "  Git repo:" + ANSI.reset)
        let isRepo = checkGitRepo()
        if isRepo {
            print("  \(ANSI.fgGreen)✓\(ANSI.reset) Inside git repository")
            let syncPoint = checkSyncPoint()
            if let sp = syncPoint {
                print("  \(ANSI.fgGreen)✓\(ANSI.reset) Sync point: \(sp)")
            } else {
                print("  \(ANSI.fgYellow)!\(ANSI.reset) No sync point set (run: gsync mark HEAD)")
            }
        } else {
            print("  \(ANSI.fgYellow)!\(ANSI.reset) Not inside a git repository")
        }
        print()

        // Summary
        print(String(repeating: "─", count: sepWidth))
        if allFound {
            print("  \(ANSI.fgGreen + ANSI.bold)All tools found.\(ANSI.reset)")
        } else {
            print("  \(ANSI.fgRed + ANSI.bold)Some tools missing.\(ANSI.reset)")
        }
        print()
        print(ANSI.dim + "  Press any key to return to menu…" + ANSI.reset)

        terminal.resumeRawMode()
        _ = terminal.readKey()
    }

    // MARK: - Helpers

    private func pad(_ s: String, _ width: Int) -> String {
        s.count >= width ? s : s + String(repeating: " ", count: width - s.count)
    }

    private func checkGitRepo() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["rev-parse", "--is-inside-work-tree"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try? process.run()
        process.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return output == "true"
    }

    private func checkSyncPoint() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["rev-parse", "--git-dir"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try? process.run()
        process.waitUntilExit()
        let gitDir = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ".git"

        // Get current branch
        let branchProc = Process()
        branchProc.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        branchProc.arguments = ["rev-parse", "--abbrev-ref", "HEAD"]
        let branchPipe = Pipe()
        branchProc.standardOutput = branchPipe
        branchProc.standardError = branchPipe
        try? branchProc.run()
        branchProc.waitUntilExit()
        let branch = String(data: branchPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "main"

        // Check new path first, then old
        let newPath = "\(gitDir)/gsync/branch/\(branch)/sync-point"
        let oldPath = "\(gitDir)/gsync/\(branch)/sync-point"

        for path in [newPath, oldPath] {
            if let content = try? String(contentsOfFile: path, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines), !content.isEmpty {
                return String(content.prefix(7))
            }
        }
        return nil
    }
}
