import Foundation

/// Silent progress reporter that ignores all progress updates
/// Used when progress display is disabled or not appropriate (e.g., output to stdout)
/// No-op implementation of ProgressReporterProtocol for default behavior
public final class SilentProgressReporter: ProgressReporterProtocol {

    // MARK: - Initialization

    /// Initialize silent progress reporter
    public init() {}

    // MARK: - ProgressReporterProtocol

    /// No-op: silently ignore progress updates
    public func update(bytesProcessed: Int64, totalBytes: Int64) {
        // Intentionally empty - no progress displayed
    }

    /// No-op: silently ignore completion
    public func complete() {
        // Intentionally empty - no completion message
    }

    /// No-op: silently ignore description
    public func setDescription(_ description: String) {
        // Intentionally empty - no description displayed
    }
}
