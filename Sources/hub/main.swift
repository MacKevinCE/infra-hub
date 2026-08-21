import Foundation
import Darwin

// Ensure we restore the terminal on exit, even on Ctrl-C.
let terminal = Terminal()

// Install signal handler to restore terminal on SIGINT / SIGTERM.
func restoreTerminal() {
    // Exit alt screen first while terminal still accepts raw escape sequences
    print(ANSI.showCursor + ANSI.exitAltScreen, terminator: "")
    fflush(stdout)
    // Then restore canonical mode + echo
    var t = termios()
    tcgetattr(STDIN_FILENO, &t)
    t.c_lflag |= UInt(ICANON | ECHO)
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &t)
}

signal(SIGINT)  { _ in restoreTerminal(); exit(0) }
signal(SIGTERM) { _ in restoreTerminal(); exit(0) }

terminal.enableRawMode()
defer {
    terminal.disableRawMode()
}

MainScreen(terminal: terminal).run()
