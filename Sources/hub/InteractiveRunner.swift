import Foundation

// MARK: - Interactive Protocol (hub side)
// Calls CLI with --interactive, parses JSON response,
// shows native UI for prompts, calls back with --reply.

enum InteractiveRunner {

    struct Option: Codable {
        let value: String
        let label: String
    }

    struct Prompt: Codable {
        let status: String
        let taskId: String
        let title: String
        let type: String
        let options: [Option]
    }

    struct Done: Codable {
        let status: String
        let message: String
    }

    /// Run a command with --interactive protocol.
    /// Returns true if the command completed (done or prompt handled).
    @discardableResult
    static func run(
        binary: String,
        arguments: [String],
        terminal: Terminal,
        runner: Runner
    ) -> Bool {
        // Phase 1: call with --interactive
        let output = callCLI(binary: binary, arguments: arguments + ["--interactive"])
        guard !output.isEmpty,
              let data = output.data(using: .utf8) else {
            // Fallback: run without --interactive
            runner.run(binary: binary, arguments: arguments)
            return true
        }

        // Try parse as Done
        if let done = try? JSONDecoder().decode(Done.self, from: data),
           done.status == "done" {
            showMessage(terminal: terminal, runner: runner, binary: binary, message: done.message)
            return true
        }

        // Try parse as Prompt
        guard let prompt = try? JSONDecoder().decode(Prompt.self, from: data),
              prompt.status == "prompt" else {
            // Fallback
            runner.run(binary: binary, arguments: arguments)
            return true
        }

        // Show native UI based on type
        let reply: String?
        switch prompt.type {
        case "multi-select":
            let checkItems = prompt.options.map {
                ChecklistItem($0.label, hint: nil, selected: false)
            }
            let checklist = Checklist(terminal: terminal, title: prompt.title, items: checkItems)
            guard let selected = checklist.run() else { return false }
            // Map labels back to values
            let values = selected.compactMap { label in
                prompt.options.first { $0.label == label }?.value
            }
            reply = values.joined(separator: ",")

        default: // "select"
            var selectedValue: String?
            var items: [MenuItem] = prompt.options.map { option in
                MenuItem(option.label) {
                    selectedValue = option.value
                }
            }
            items.append(.separator)
            items.append(.quit("Cancel"))
            let menu = Menu(terminal: terminal, title: prompt.title, items: items)
            menu.run()
            reply = selectedValue
        }

        guard let reply, !reply.isEmpty else { return false }

        // Phase 2: call with --interactive --reply <value>
        runner.run(binary: binary, arguments: arguments + ["--interactive", "--reply", reply])
        return true
    }

    // MARK: - Private

    private static func callCLI(binary: String, arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binary)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static func showMessage(terminal: Terminal, runner: Runner, binary: String, message: String) {
        terminal.suspendRawMode()
        terminal.clearScreen()
        let cols = terminal.size().cols
        let sepWidth = max(10, min(cols - 2, 60))
        terminal.write(ANSI.bold + ANSI.fgCyan)
        terminal.writeln("  \(URL(fileURLWithPath: binary).lastPathComponent)")
        terminal.write(ANSI.reset)
        terminal.writeln(String(repeating: "─", count: sepWidth))
        terminal.writeln()
        terminal.write(ANSI.fgGreen)
        terminal.writeln("  \(message)")
        terminal.write(ANSI.reset)
        terminal.writeln()
        terminal.write(ANSI.dim)
        terminal.write("  Press any key to return to menu…")
        terminal.write(ANSI.reset)
        terminal.writeln()
        terminal.resumeRawMode()
        _ = terminal.readKey()
    }
}
