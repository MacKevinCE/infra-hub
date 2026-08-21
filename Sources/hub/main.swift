import Foundation
import Darwin

// Save original terminal state BEFORE any modification.
var savedTermios = termios()
tcgetattr(STDIN_FILENO, &savedTermios)

let terminal = Terminal()

// Install signal handler to restore terminal on SIGINT / SIGTERM.
func restoreTerminal() {
    // Exit alt screen using async-signal-safe write() syscall
    let seq = ANSI.showCursor + ANSI.exitAltScreen
    seq.withCString { ptr in
        _ = Darwin.write(STDOUT_FILENO, ptr, strlen(ptr))
    }
    // Restore full original termios
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &savedTermios)
}

// Handle CLI commands before TUI
if CommandLine.arguments.count >= 2 {
    let arg = CommandLine.arguments[1]
    if arg == "--version" || arg == "-v" {
        print("hub \(hubVersion)")
        exit(0)
    }
    if arg == "doctor" {
        DoctorScreen(terminal: terminal).runCLI()
        exit(0)
    }
}

signal(SIGINT)  { _ in restoreTerminal(); _exit(0) }
signal(SIGTERM) { _ in restoreTerminal(); _exit(0) }

terminal.enableRawMode()
defer {
    terminal.disableRawMode()
}

MainScreen(terminal: terminal).run()
