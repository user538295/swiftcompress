import Foundation

/// Protocol for reporting compression/decompression progress
/// Abstraction for progress reporting to keep domain layer independent of UI
/// Implementations can display progress to terminal, log to file, or silently ignore
public protocol ProgressReporterProtocol {
    /// Update progress with current status
    /// - Parameters:
    ///   - bytesProcessed: Number of bytes processed so far
    ///   - totalBytes: Total bytes to process (0 if unknown, e.g., stdin)
    func update(bytesProcessed: Int64, totalBytes: Int64)

    /// Mark operation as complete
    /// Called when compression/decompression finishes successfully
    func complete()

    /// Set description for the operation being tracked
    /// - Parameter description: Human-readable operation description (e.g., "Compressing file.txt")
    func setDescription(_ description: String)
}
