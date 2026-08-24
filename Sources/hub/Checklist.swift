import Foundation

// MARK: - ChecklistItem

struct ChecklistItem {
    let label: String
    let hint: String?
    var selected: Bool

    init(_ label: String, hint: String? = nil, selected: Bool = true) {
        self.label    = label
        self.hint     = hint
        self.selected = selected
    }
}

// MARK: - Checklist

/// Interactive checkbox list. Returns selected labels, or nil if cancelled.
final class Checklist {
    private let terminal: Terminal
    private let title: String
    private var items: [ChecklistItem]

    init(terminal: Terminal, title: String, items: [ChecklistItem]) {
        self.terminal = terminal
        self.title    = title
        self.items    = items
    }

    func run() -> [String]? {
        guard !items.isEmpty else { return [] }
        var cursor = 0

        while true {
            render(cursor: cursor)
            let key = terminal.readKey()

            switch key {
            case .up:
                cursor = (cursor - 1 + items.count) % items.count
            case .down:
                cursor = (cursor + 1) % items.count
            case .char(" "):
                items[cursor].selected.toggle()
            case .char("a"):
                for i in items.indices { items[i].selected = true }
            case .char("n"):
                for i in items.indices { items[i].selected = false }
            case .enter:
                let selected = items.filter(\.selected).map(\.label)
                return selected
            case .quit, .escape:
                return nil
            default:
                break
            }
        }
    }

    // MARK: Private

    private func render(cursor: Int) {
        let cols = terminal.size().cols
        let sepWidth = max(10, min(cols - 2, 60))

        terminal.clearScreen()

        terminal.write(ANSI.bold + ANSI.fgCyan)
        terminal.writeln("  \(title)")
        terminal.write(ANSI.reset)
        terminal.writeln(String(repeating: "─", count: sepWidth))
        terminal.writeln()

        for (i, item) in items.enumerated() {
            let isCursor = i == cursor
            let check = item.selected ? "●" : "○"
            let prefix = isCursor ? "  ▸ " : "    "

            var content = "\(check) \(item.label)"
            if let hint = item.hint {
                content += "  \(hint)"
            }

            if isCursor {
                terminal.write(ANSI.bgBlue + ANSI.fgWhite + ANSI.bold)
                terminal.write(prefix + content)
                terminal.write(ANSI.reset)
            } else {
                terminal.write(item.selected ? ANSI.fgGreen : ANSI.dim)
                terminal.write(prefix + content)
                terminal.write(ANSI.reset)
            }
            terminal.writeln()
        }

        terminal.writeln()
        terminal.write(ANSI.dim + ANSI.fgWhite)
        terminal.writeln("  ↑/↓ move   Space toggle   a all   n none   Enter confirm   q cancel")
        terminal.write(ANSI.reset)
    }
}
