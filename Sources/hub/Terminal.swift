import Darwin
import Foundation

// MARK: - ANSI Escape Codes

enum ANSI {
    static let reset       = "\u{1B}[0m"
    static let bold        = "\u{1B}[1m"
    static let dim         = "\u{1B}[2m"
    static let clearScreen = "\u{1B}[2J"
    static let home        = "\u{1B}[H"
    static let hideCursor  = "\u{1B}[?25l"
    static let showCursor  = "\u{1B}[?25h"
    static let enterAltScreen = "\u{1B}[?1049h"
    static let exitAltScreen  = "\u{1B}[?1049l"
    static let clearLine   = "\u{1B}[2K"
    static let saveCursor  = "\u{1B}7"
    static let restoreCursor = "\u{1B}8"

    // Colors
    static let fgBlack   = "\u{1B}[30m"
    static let fgRed     = "\u{1B}[31m"
    static let fgGreen   = "\u{1B}[32m"
    static let fgYellow  = "\u{1B}[33m"
    static let fgBlue    = "\u{1B}[34m"
    static let fgMagenta = "\u{1B}[35m"
    static let fgCyan    = "\u{1B}[36m"
    static let fgWhite   = "\u{1B}[37m"

    static let bgBlue    = "\u{1B}[44m"
    static let bgCyan    = "\u{1B}[46m"

    static func moveTo(row: Int, col: Int) -> String {
        "\u{1B}[\(row);\(col)H"
    }

    static func moveUp(_ n: Int) -> String {
        "\u{1B}[\(n)A"
    }

    static func eraseToEndOfLine() -> String {
        "\u{1B}[K"
    }
}

// MARK: - Key Input

enum Key {
    case up
    case down
    case enter
    case quit      // q
    case escape    // ESC / back
    case backspace
    case char(Character)
    case unknown
}

// MARK: - Terminal

final class Terminal {
    private var originalTermios = termios()
    private(set) var isRawMode = false

    // MARK: Raw mode

    func enableRawMode() {
        tcgetattr(STDIN_FILENO, &originalTermios)
        var raw = originalTermios
        cfmakeraw(&raw)
        // Keep ISIG so Ctrl-C still works
        raw.c_lflag |= UInt(ISIG)
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)
        isRawMode = true
        write(ANSI.enterAltScreen + ANSI.hideCursor)
    }

    func disableRawMode() {
        // Exit alt screen while still in raw mode (clean escape sequence)
        write(ANSI.showCursor + ANSI.exitAltScreen)
        // Then restore original terminal settings
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &originalTermios)
        isRawMode = false
    }

    // MARK: Output helpers

    func write(_ s: String) {
        Swift.print(s, terminator: "")
        fflush(stdout)
    }

    func writeln(_ s: String = "") {
        Swift.print(s + "\r", terminator: "\n")
        fflush(stdout)
    }

    func clearScreen() {
        write(ANSI.clearScreen + ANSI.home)
    }

    func moveTo(row: Int, col: Int = 1) {
        write(ANSI.moveTo(row: row, col: col))
    }

    // MARK: Key reading

    func readKey() -> Key {
        var buf = [UInt8](repeating: 0, count: 3)
        let n = Foundation.read(STDIN_FILENO, &buf, 3)
        guard n > 0 else { return .unknown }

        if n == 1 {
            switch buf[0] {
            case 13, 10:           return .enter          // CR / LF
            case 27:               return .escape          // lone ESC
            case 127, 8:           return .backspace       // DEL / BS
            case UInt8(ascii: "q"):return .quit
            default:
                let scalar = Unicode.Scalar(buf[0])
                if scalar.value >= 32 {
                    return .char(Character(scalar))
                }
                return .unknown
            }
        }

        // ESC sequence
        if n >= 3 && buf[0] == 27 && buf[1] == UInt8(ascii: "[") {
            switch buf[2] {
            case UInt8(ascii: "A"): return .up
            case UInt8(ascii: "B"): return .down
            default:                return .unknown
            }
        }

        return .unknown
    }

    // MARK: Terminal size

    func size() -> (rows: Int, cols: Int) {
        var ws = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 {
            return (Int(ws.ws_row), Int(ws.ws_col))
        }
        return (24, 80)
    }
}
