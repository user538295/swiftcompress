import Foundation

/// Coordinates progress reporting for compression/decompression operations
/// Factory for creating appropriate progress reporters based on context
/// Handles logic for when progress should be displayed vs. silently ignored
public final class ProgressCoordinator {

    // MARK: - Initialization

    /// Initialize progress coordinator
    public init() {}

    // MARK: - Factory Methods

    /// Create appropriate progress reporter based on context
    /// - Parameters:
    ///   - progressEnabled: Whether user requested progress display
    ///   - outputDestination: Where output is being written
    /// - Returns: Terminal reporter if conditions met, silent reporter otherwise
    ///
    /// Progress is displayed when ALL conditions are met:
    /// 1. User requested progress with --progress flag
    /// 2. stderr is connected to a terminal (not redirected)
    /// 3. Output is NOT going to stdout (would interfere with piping)
    public func createReporter(
        progressEnabled: Bool,
        outputDestination: OutputDestination
    ) -> ProgressReporterProtocol {
        // Check if progress should be displayed
        let shouldDisplayProgress = progressEnabled
            && TerminalDetector.isStderrTerminal()
            && !outputDestination.isStdout

        if shouldDisplayProgress {
            return TerminalProgressReporter()
        } else {
            return SilentProgressReporter()
        }
    }

    /// Wrap input stream with progress tracking
    /// - Parameters:
    ///   - stream: Input stream to wrap
    ///   - totalBytes: Total bytes expected to read (0 if unknown)
    ///   - reporter: Progress reporter to notify
    /// - Returns: Progress tracking input stream wrapper
    public func wrapInputStream(
        _ stream: InputStream,
        totalBytes: Int64,
        reporter: ProgressReporterProtocol
    ) -> InputStream {
        return ProgressTrackingInputStream(
            stream: stream,
            totalBytes: totalBytes,
            progressReporter: reporter
        )
    }

    /// Wrap output stream with progress tracking
    /// - Parameters:
    ///   - stream: Output stream to wrap
    ///   - totalBytes: Total bytes expected to write (0 if unknown)
    ///   - reporter: Progress reporter to notify
    /// - Returns: Progress tracking output stream wrapper
    public func wrapOutputStream(
        _ stream: OutputStream,
        totalBytes: Int64,
        reporter: ProgressReporterProtocol
    ) -> OutputStream {
        return ProgressTrackingOutputStream(
            stream: stream,
            totalBytes: totalBytes,
            progressReporter: reporter
        )
    }
}
