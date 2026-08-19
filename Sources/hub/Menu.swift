import Foundation

// MARK: - MenuItem

struct MenuItem {
    let label: String
    let hint: String?

    init(_ label: String, hint: String? = nil) {
        self.label = label
        self.hint  = hint
    }
}

// MARK: - Menu

/// Generic arrow-key navigable menu.
/// Returns the selected index, or nil if the user pressed q/ESC.
final class Menu {
    private let terminal: Terminal
    private let title: String
    private let items: [MenuItem]

    init(terminal: Terminal, title: String, items: [MenuItem]) {
        self.terminal = terminal
        self.title    = title
        self.items    = items
    }

    /// Blocks until user picks an item or quits.
    func run() -> Int? {
        var selected = 0

        while true {
            render(selected: selected)
            let key = terminal.readKey()

            switch key {
            case .up:
                selected = (selected - 1 + items.count) % items.count
            case .down:
                selected = (selected + 1) % items.count
            case .enter:
                return selected
            case .quit, .escape:
                return nil
            default:
                break
            }
        }
    }

    // MARK: Private

    private func render(selected: Int) {
        terminal.clearScreen()

        // Title bar
        terminal.write(ANSI.bold + ANSI.fgCyan)
        terminal.writeln("  \(title)")
        terminal.write(ANSI.reset)
        terminal.writeln(String(repeating: "─", count: 40))

        for (i, item) in items.enumerated() {
            if i == selected {
                terminal.write(ANSI.bgBlue + ANSI.fgWhite + ANSI.bold)
                terminal.write("  ▶ \(item.label)")
                if let hint = item.hint {
                    terminal.write("  \(ANSI.dim)\(hint)")
                }
                terminal.write(ANSI.reset)
                terminal.writeln()
            } else {
                terminal.write(ANSI.reset)
                terminal.write("    \(item.label)")
                if let hint = item.hint {
                    terminal.write("  \(ANSI.dim)\(ANSI.fgWhite)\(hint)\(ANSI.reset)")
                }
                terminal.writeln()
            }
        }

        terminal.writeln()
        terminal.write(ANSI.dim + ANSI.fgWhite)
        terminal.write("  ↑/↓ navigate   Enter select   q/ESC back")
        terminal.write(ANSI.reset)
        terminal.writeln()
    }
}
