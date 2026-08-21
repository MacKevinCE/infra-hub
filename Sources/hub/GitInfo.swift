import Foundation

/// Shared git queries for MainScreen and DoctorScreen.
/// All operations are local (no API calls).
enum GitInfo {

    static func isRepo() -> Bool {
        git(["rev-parse", "--is-inside-work-tree"]) == "true"
    }

    static func currentBranch() -> String? {
        let result = git(["rev-parse", "--abbrev-ref", "HEAD"])
        return result.isEmpty ? nil : result
    }

    static func gitDir() -> String {
        git(["rev-parse", "--git-dir"]).isEmpty ? ".git" : git(["rev-parse", "--git-dir"])
    }

    static func syncPoint() -> String? {
        let dir = gitDir()
        guard let branch = currentBranch() else { return nil }
        let paths = [
            "\(dir)/gsync/branch/\(branch)/sync-point",
            "\(dir)/gsync/\(branch)/sync-point",
        ]
        for path in paths {
            if let content = try? String(contentsOfFile: path, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines), !content.isEmpty {
                return String(content.prefix(7))
            }
        }
        return nil
    }

    static func commitsAhead() -> Int? {
        let dir = gitDir()
        guard let branch = currentBranch() else { return nil }
        let paths = [
            "\(dir)/gsync/branch/\(branch)/sync-point",
            "\(dir)/gsync/\(branch)/sync-point",
        ]
        var hash: String?
        for path in paths {
            if let content = try? String(contentsOfFile: path, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines), !content.isEmpty {
                hash = content
                break
            }
        }
        guard let h = hash else { return nil }
        let count = git(["rev-list", "--count", "\(h)..HEAD"])
        return Int(count)
    }

    static func channelId() -> String? {
        let path = "\(NSHomeDirectory())/.config/b2c-gsync/channel"
        guard let content = try? String(contentsOfFile: path, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines), !content.isEmpty else {
            return nil
        }
        return content
    }

    // MARK: - Private

    private static func git(_ arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try? process.run()
        process.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
