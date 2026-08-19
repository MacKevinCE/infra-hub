import Foundation

// MARK: - FormField

struct FormField {
    let label: String
    let placeholder: String
    let required: Bool

    init(_ label: String, placeholder: String = "", required: Bool = true) {
        self.label       = label
        self.placeholder = placeholder
        self.required    = required
    }
}

// MARK: - Form

/// Generic form that collects values for a list of fields.
/// Returns an ordered array of values (empty string = skipped optional).
/// Returns nil if the user pressed ESC.
final class Form {
    private let terminal: Terminal
    private let title: String
    private let fields: [FormField]

    init(terminal: Terminal, title: String, fields: [FormField]) {
        self.terminal = terminal
        self.title    = title
        self.fields   = fields
    }

    func run() -> [String]? {
        var values: [String] = Array(repeating: "", count: fields.count)
        var current = 0

        while current < fields.count {
            // Restore normal mode for line editing
            terminal.disableRawMode()

            render(values: values, current: current)

            let field = fields[current]
            terminal.write(ANSI.fgGreen + "  > " + ANSI.reset)

            // Read line from stdin (cooked mode)
            guard let line = readLine(strippingNewline: true) else {
                terminal.enableRawMode()
                return nil
            }

            // ESC check: user can type ":q" to abort (raw ESC doesn't reach readLine)
            if line == ":q" || line == ":quit" {
                terminal.enableRawMode()
                return nil
            }

            if line.isEmpty && field.required {
                terminal.write(ANSI.fgRed)
                terminal.writeln("  Field '\(field.label)' is required. Press Enter to retry or type :q to cancel.")
                terminal.write(ANSI.reset)
                _ = readLine()
                terminal.enableRawMode()
                continue
            }

            values[current] = line
            current += 1
            terminal.enableRawMode()
        }

        return values
    }

    // MARK: Private

    private func render(values: [String], current: Int) {
        terminal.clearScreen()
        let cols = terminal.size().cols
        let sepWidth = max(10, min(cols - 2, 60))
        terminal.write(ANSI.bold + ANSI.fgCyan)
        terminal.writeln("  \(title)")
        terminal.write(ANSI.reset)
        terminal.writeln(String(repeating: "─", count: sepWidth))
        terminal.writeln()

        for (i, field) in fields.enumerated() {
            let isCurrent = i == current
            let isFilled  = !values[i].isEmpty
            let isDone    = i < current

            if isCurrent {
                terminal.write(ANSI.bold + ANSI.fgYellow)
                terminal.writeln("  ▶ \(field.label)\(field.required ? "" : " (optional)")")
                terminal.write(ANSI.reset)
                if !field.placeholder.isEmpty {
                    terminal.write(ANSI.dim)
                    terminal.writeln("    hint: \(field.placeholder)")
                    terminal.write(ANSI.reset)
                }
            } else if isDone {
                terminal.write(ANSI.fgGreen)
                let display = isFilled ? values[i] : "(skipped)"
                terminal.writeln("  ✓ \(field.label): \(display)")
                terminal.write(ANSI.reset)
            } else {
                terminal.write(ANSI.dim + ANSI.fgWhite)
                terminal.writeln("    \(field.label)\(field.required ? "" : " (optional)")")
                terminal.write(ANSI.reset)
            }
        }

        terminal.writeln()
        terminal.write(ANSI.dim + ANSI.fgWhite)
        terminal.writeln("  Type :q to cancel")
        terminal.write(ANSI.reset)
        terminal.writeln()
    }
}
