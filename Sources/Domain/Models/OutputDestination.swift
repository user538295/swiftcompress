import Foundation

/// Represents a destination for output data
/// Can be either a file path or stdout stream
/// Used throughout the application to abstract output destinations for compression/decompression
public enum OutputDestination: Equatable {
    /// Write to a file at the specified path
    case file(path: String)

    /// Write to standard output (stdout)
    case stdout

    /// Human-readable description for logging and error messages
    public var description: String {
        switch self {
        case .file(let path):
            return path
        case .stdout:
            return "<stdout>"
        }
    }

    /// Check if destination is stdout
    public var isStdout: Bool {
        if case .stdout = self { return true }
        return false
    }

    /// Check if destination is a file
    public var isFile: Bool {
        if case .file = self { return true }
        return false
    }

    /// Extract file path if destination is a file, nil otherwise
    public var filePath: String? {
        if case .file(let path) = self { return path }
        return nil
    }
}
