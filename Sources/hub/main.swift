import Foundation
import Darwin

// Save original terminal state BEFORE any modification.
var savedTermios = termios()
tcgetattr(STDIN_FILENO, &savedTermios)

let terminal = Terminal()

// Install signal handler to restore terminal on SIGINT / SIGTERM.
func restoreTerminal() {
    // Exit alt screen first while terminal still accepts raw escape sequences
    print(ANSI.showCursor + ANSI.exitAltScreen, terminator: "")
    fflush(stdout)
    // Restore full original termios (not just ICANON|ECHO)
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

signal(SIGINT)  { _ in restoreTerminal(); exit(0) }
signal(SIGTERM) { _ in restoreTerminal(); exit(0) }

terminal.enableRawMode()
defer {
    terminal.disableRawMode()
}

MainScreen(terminal: terminal).run()
