import Foundation

// MARK: - MenuItem

struct MenuItem {
    let label: String
    let hint: String?
    let action: (() -> Void)?
	
	var isSeparator: Bool {
		label.isEmpty && (hint ?? "").isEmpty
	}

    init(_ label: String, hint: String? = nil, action: @escaping () -> Void) {
        self.label = label
        self.hint  = hint
        self.action = action
    }

    private init() {
        self.label = ""
        self.hint  = nil
        self.action = nil
    }

    private init(quitLabel: String) {
        self.label = quitLabel
        self.hint  = nil
        self.action = nil
    }

    static let separator = MenuItem()
    static func quit(_ label: String = "Quit") -> MenuItem { MenuItem(quitLabel: label) }
}

// MARK: - Menu

/// Generic arrow-key navigable menu.
final class Menu {
    private let terminal: Terminal
    private let title: String
    private let items: [MenuItem]

    init(terminal: Terminal, title: String, items: [MenuItem]) {
        self.terminal = terminal
        self.title    = title
        self.items    = items
    }

    /// Blocks until user quits (q/ESC or Quit item).
    /// Items with action closures execute and loop back to the menu.
    func run() {
        var selected = 0

        while true {
            render(selected: selected)
            let key = terminal.readKey()

            switch key {
            case .up:
                selected = prevSelectable(from: selected)
            case .down:
                selected = nextSelectable(from: selected)
            case .enter:
				if let action = items[selected].action {
					action()
				} else {
					return
				}
            case .quit, .escape:
                return
            default:
                break
            }
        }
    }

    // MARK: Private

    private func nextSelectable(from index: Int) -> Int {
        var next = (index + 1) % items.count
        while items[next].isSeparator {
            next = (next + 1) % items.count
        }
        return next
    }

    private func prevSelectable(from index: Int) -> Int {
        var prev = (index - 1 + items.count) % items.count
        while items[prev].isSeparator {
            prev = (prev - 1 + items.count) % items.count
        }
        return prev
    }

    private func render(selected: Int) {
        let cols = terminal.size().cols
        let sepWidth = max(10, min(cols - 2, 60))

        terminal.clearScreen()

        // Title bar
        terminal.write(ANSI.bold + ANSI.fgCyan)
        terminal.writeln("  \(title)")
        terminal.write(ANSI.reset)
        terminal.writeln(String(repeating: "─", count: sepWidth))

        for (i, item) in items.enumerated() {
            if item.isSeparator {
                terminal.writeln()
                continue
            }

            let isSelected = i == selected
            let prefix = isSelected ? "  ▶ " : "    "
            let maxContent = max(4, cols - prefix.count - 1)

            // Build label + hint, truncating to fit
            var content = item.label
            if let hint = item.hint {
                let full = item.label + " - " + hint
                if full.count <= maxContent {
                    content = full
                } else {
                    let available = maxContent - item.label.count - 3
                    if available > 3 {
                        content = item.label + " - " + String(hint.prefix(available)) + "…"
                    } else if item.label.count > maxContent {
                        content = String(item.label.prefix(maxContent - 1)) + "…"
                    }
                }
            } else if content.count > maxContent {
                content = String(content.prefix(maxContent - 1)) + "…"
            }

            if isSelected {
                terminal.write(ANSI.bgBlue + ANSI.fgWhite + ANSI.bold)
                terminal.write(prefix + content)
                terminal.write(ANSI.reset)
                terminal.writeln()
            } else {
                terminal.write(ANSI.reset)
                terminal.write(prefix + content)
                terminal.writeln()
            }
        }

        terminal.writeln()
        let footer = "  ↑/↓ navigate   Enter select   q/ESC back or quit"
        terminal.write(ANSI.dim + ANSI.fgWhite)
        terminal.write(cols >= footer.count + 2 ? footer : "  ↑/↓  Enter  q/ESC")
        terminal.write(ANSI.reset)
        terminal.writeln()
    }
}
