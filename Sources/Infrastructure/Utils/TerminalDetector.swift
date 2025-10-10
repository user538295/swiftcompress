import Foundation

/// Utility for detecting whether stdin/stdout are connected to terminals or pipes
/// Uses POSIX isatty() function to determine connection type
/// This is essential for automatic pipe detection in Unix pipeline scenarios
public enum TerminalDetector {
    /// Check if stdin is connected to a pipe (not a terminal)
    /// - Returns: true if stdin is receiving piped data from another command
    public static func isStdinPipe() -> Bool {
        return isatty(STDIN_FILENO) == 0
    }

    /// Check if stdin is connected to a terminal (not a pipe)
    /// - Returns: true if stdin is an interactive terminal
    public static func isStdinTerminal() -> Bool {
        return isatty(STDIN_FILENO) != 0
    }

    /// Check if stdout is connected to a pipe (not a terminal)
    /// - Returns: true if stdout is being piped to another command or redirected
    public static func isStdoutPipe() -> Bool {
        return isatty(STDOUT_FILENO) == 0
    }

    /// Check if stdout is connected to a terminal (not a pipe)
    /// - Returns: true if stdout is displaying to user's terminal
    public static func isStdoutTerminal() -> Bool {
        return isatty(STDOUT_FILENO) != 0
    }

    /// Check if stderr is connected to a terminal
    /// - Returns: true if stderr is displaying to user's terminal
    public static func isStderrTerminal() -> Bool {
        return isatty(STDERR_FILENO) != 0
    }
}
