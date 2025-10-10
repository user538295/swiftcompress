import Foundation

/// Represents a source for input data
/// Can be either a file path or stdin stream
/// Used throughout the application to abstract input sources for compression/decompression
public enum InputSource: Equatable {
    /// Read from a file at the specified path
    case file(path: String)

    /// Read from standard input (stdin)
    case stdin

    /// Human-readable description for logging and error messages
    public var description: String {
        switch self {
        case .file(let path):
            return path
        case .stdin:
            return "<stdin>"
        }
    }

    /// Check if source is stdin
    public var isStdin: Bool {
        if case .stdin = self { return true }
        return false
    }

    /// Check if source is a file
    public var isFile: Bool {
        if case .file = self { return true }
        return false
    }

    /// Extract file path if source is a file, nil otherwise
    public var filePath: String? {
        if case .file(let path) = self { return path }
        return nil
    }
}
