import Foundation

// MARK: - DoctorScreen

final class DoctorScreen {
    private let terminal: Terminal

    init(terminal: Terminal) {
        self.terminal = terminal
    }

    /// TUI mode: runs inside alt screen, waits for key
    func run() {
        terminal.suspendRawMode()
        terminal.clearScreen()
        printDiagnostics()
        print(ANSI.dim + "  Press any key to return to menu…" + ANSI.reset)
        terminal.resumeRawMode()
        _ = terminal.readKey()
    }

    /// CLI mode: runs directly in normal terminal
    func runCLI() {
        printDiagnostics()
    }

    private func printDiagnostics() {
        let sepWidth = 50

        print(ANSI.bold + ANSI.fgCyan + "  hub doctor" + ANSI.reset)
        print(String(repeating: "─", count: sepWidth))
        print()

        // Check tools with minimum versions
        print(ANSI.bold + "  Tools:" + ANSI.reset)
        let requirements: [(name: String, minVersion: String?)] = [
            ("jcloud", minJcloudVersion),
            ("b2c",    minB2cVersion),
            ("gsync",  minGsyncVersion),
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
        if let channelId = GitInfo.channelId() {
            print("  \(ANSI.fgGreen)✓\(ANSI.reset) Configured: \(channelId)")
        } else {
            print("  \(ANSI.fgRed)✗\(ANSI.reset) No channel configured (run: jcloud channel create)")
        }
        print()

        // Check git repo + sync point
        print(ANSI.bold + "  Git repo:" + ANSI.reset)
        if GitInfo.isRepo() {
            print("  \(ANSI.fgGreen)✓\(ANSI.reset) Inside git repository")
            if let sp = GitInfo.syncPoint() {
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
    }

    private func pad(_ s: String, _ width: Int) -> String {
        s.count >= width ? s : s + String(repeating: " ", count: width - s.count)
    }
}
