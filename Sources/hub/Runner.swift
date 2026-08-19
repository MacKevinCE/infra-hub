import Foundation

// MARK: - Runner

/// Executes a CLI binary and streams stdout/stderr to the terminal in real time.
final class Runner {
    private let terminal: Terminal

    init(terminal: Terminal) {
        self.terminal = terminal
    }

    /// Builds the argument array, filtering out empty strings.
    static func args(_ parts: String?...) -> [String] {
        parts.compactMap { $0 }.filter { !$0.isEmpty }
    }

    /// Runs `binary` with `arguments`, streaming output live.
    /// Restores normal terminal mode before execution and re-enables raw mode after.
    @discardableResult
    func run(binary: String, arguments: [String]) -> Int32 {
        terminal.disableRawMode()
        terminal.clearScreen()

        // Header
        let cols = terminal.size().cols
        let sepWidth = max(10, min(cols - 2, 80))
        terminal.write(ANSI.bold + ANSI.fgCyan)
        let cmd = ([binary] + arguments).joined(separator: " ")
        let cmdLine = "  Running: \(cmd)"
        let displayCmd = cmdLine.count > cols - 1 ? String(cmdLine.prefix(cols - 2)) + "…" : cmdLine
        terminal.writeln(displayCmd)
        terminal.write(ANSI.reset)
        terminal.writeln(String(repeating: "─", count: sepWidth))
        terminal.writeln()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: binary)
        process.arguments = arguments

        // Inherit environment
        process.environment = ProcessInfo.processInfo.environment

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError  = stderrPipe

        // Stream stdout
        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let str = String(data: data, encoding: .utf8) {
                Swift.print(str, terminator: "")
                fflush(stdout)
            }
        }

        // Stream stderr (in red)
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let str = String(data: data, encoding: .utf8) {
                Swift.print(ANSI.fgRed + str + ANSI.reset, terminator: "")
                fflush(stdout)
            }
        }

        do {
            try process.run()
        } catch {
            terminal.write(ANSI.fgRed)
            terminal.writeln("  Error launching \(binary): \(error.localizedDescription)")
            terminal.write(ANSI.reset)
            terminal.enableRawMode()
            return -1
        }

        process.waitUntilExit()

        // Drain remaining data
        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil

        let remainingOut = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let remainingErr = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        if !remainingOut.isEmpty, let s = String(data: remainingOut, encoding: .utf8) { Swift.print(s, terminator: "") }
        if !remainingErr.isEmpty, let s = String(data: remainingErr, encoding: .utf8) {
            Swift.print(ANSI.fgRed + s + ANSI.reset, terminator: "")
        }
        fflush(stdout)

        let code = process.terminationStatus
        terminal.writeln()
        terminal.writeln(String(repeating: "─", count: sepWidth))

        if code != 0 {
            terminal.write(ANSI.fgRed + ANSI.bold)
            terminal.writeln("  Exited with code: \(code)")
            terminal.write(ANSI.reset)
        } else {
            terminal.write(ANSI.fgGreen + ANSI.bold)
            terminal.writeln("  Done.")
            terminal.write(ANSI.reset)
        }

        terminal.writeln()
        terminal.write(ANSI.dim)
        terminal.write("  Press any key to return to menu…")
        terminal.write(ANSI.reset)
        terminal.writeln()

        terminal.enableRawMode()
        _ = terminal.readKey()

        return code
    }
}
