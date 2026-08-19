import Foundation
import Darwin

// Ensure we restore the terminal on exit, even on Ctrl-C.
let terminal = Terminal()

// Install signal handler to restore terminal on SIGINT / SIGTERM.
signal(SIGINT) { _ in
    var t = termios()
    tcgetattr(STDIN_FILENO, &t)
    // Re-enable canonical mode + echo before exiting.
    t.c_lflag |= UInt(ICANON | ECHO)
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &t)
    print(ANSI.showCursor, terminator: "")
    fflush(stdout)
    exit(0)
}

signal(SIGTERM) { _ in
    var t = termios()
    tcgetattr(STDIN_FILENO, &t)
    t.c_lflag |= UInt(ICANON | ECHO)
    tcsetattr(STDIN_FILENO, TCSAFLUSH, &t)
    print(ANSI.showCursor, terminator: "")
    fflush(stdout)
    exit(0)
}

terminal.enableRawMode()
defer {
    terminal.disableRawMode()
    terminal.clearScreen()
}

MainScreen(terminal: terminal).run()
