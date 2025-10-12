import Foundation

extension Int64 {
    /// Formats byte count as human-readable string (e.g., "1.5 MB", "342 KB")
    /// Uses decimal (1000-based) formatting style which matches ByteCountFormatter.file behavior
    /// - Parameter style: The formatting style (default: .file for decimal)
    /// - Returns: Formatted string representation
    func formattedByteCount(style: ByteCountFormatter.CountStyle = .file) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = style
        return formatter.string(fromByteCount: self)
    }
}
