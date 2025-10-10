import Foundation

/// Terminal progress reporter that displays progress to stderr
/// Displays formatted progress bar with percentage, speed, and ETA
/// Updates are throttled to avoid excessive terminal writes
/// Format: [=====>    ] 45% 5.2 MB/s ETA 00:03
public final class TerminalProgressReporter: ProgressReporterProtocol {

    // MARK: - Properties

    private let stderr = FileHandle.standardError
    private var description: String = ""
    private var lastUpdateTime: Date = .distantPast
    private var startTime: Date?
    private var lastBytesProcessed: Int64 = 0

    // Configuration
    private let updateThrottleInterval: TimeInterval = 0.1  // 100ms minimum between updates
    private let progressBarWidth: Int = 30

    // MARK: - Initialization

    /// Initialize terminal progress reporter
    public init() {}

    // MARK: - ProgressReporterProtocol

    /// Update progress with current status
    /// - Parameters:
    ///   - bytesProcessed: Number of bytes processed so far
    ///   - totalBytes: Total bytes to process (0 if unknown)
    public func update(bytesProcessed: Int64, totalBytes: Int64) {
        // Initialize start time on first update
        if startTime == nil {
            startTime = Date()
        }

        // Throttle updates to avoid excessive terminal writes
        let now = Date()
        let timeSinceLastUpdate = now.timeIntervalSince(lastUpdateTime)
        guard timeSinceLastUpdate >= updateThrottleInterval else {
            return
        }

        lastUpdateTime = now
        lastBytesProcessed = bytesProcessed

        // Format and display progress
        let progressLine = formatProgressLine(
            bytesProcessed: bytesProcessed,
            totalBytes: totalBytes,
            elapsedTime: now.timeIntervalSince(startTime ?? now)
        )

        writeToStderr(progressLine)
    }

    /// Mark operation as complete
    public func complete() {
        // Clear progress line by overwriting with spaces and carriage return
        let clearLine = "\r" + String(repeating: " ", count: 80) + "\r"
        writeToStderr(clearLine)
    }

    /// Set description for the operation being tracked
    /// - Parameter description: Human-readable operation description
    public func setDescription(_ description: String) {
        self.description = description
    }

    // MARK: - Private Methods

    /// Format progress line for display
    /// - Parameters:
    ///   - bytesProcessed: Bytes processed so far
    ///   - totalBytes: Total bytes to process (0 if unknown)
    ///   - elapsedTime: Time elapsed since start
    /// - Returns: Formatted progress string
    private func formatProgressLine(
        bytesProcessed: Int64,
        totalBytes: Int64,
        elapsedTime: TimeInterval
    ) -> String {
        var line = "\r"

        // Add description if available
        if !description.isEmpty {
            line += "\(description): "
        }

        if totalBytes > 0 {
            // Known total size: show progress bar, percentage, speed, ETA
            let percentage = Double(bytesProcessed) / Double(totalBytes)
            let progressBar = formatProgressBar(percentage: percentage)
            let percentageText = String(format: "%d%%", Int(percentage * 100))
            let speed = formatSpeed(bytesProcessed: bytesProcessed, elapsedTime: elapsedTime)
            let eta = formatETA(
                bytesProcessed: bytesProcessed,
                totalBytes: totalBytes,
                elapsedTime: elapsedTime
            )

            line += "[\(progressBar)] \(percentageText) \(speed) ETA \(eta)"
        } else {
            // Unknown total size: show only speed and bytes processed
            let speed = formatSpeed(bytesProcessed: bytesProcessed, elapsedTime: elapsedTime)
            let bytesText = formatBytes(bytesProcessed)

            line += "\(speed) (bytes processed: \(bytesText))"
        }

        return line
    }

    /// Format progress bar visualization
    /// - Parameter percentage: Progress percentage (0.0 to 1.0)
    /// - Returns: Progress bar string (e.g., "=====>    ")
    private func formatProgressBar(percentage: Double) -> String {
        let filledWidth = Int(Double(progressBarWidth) * percentage)
        let emptyWidth = progressBarWidth - filledWidth

        var bar = String(repeating: "=", count: max(0, filledWidth - 1))
        if filledWidth > 0 {
            bar += ">"
        }
        bar += String(repeating: " ", count: max(0, emptyWidth))

        return bar
    }

    /// Format processing speed
    /// - Parameters:
    ///   - bytesProcessed: Total bytes processed
    ///   - elapsedTime: Time elapsed in seconds
    /// - Returns: Formatted speed string (e.g., "5.2 MB/s")
    private func formatSpeed(bytesProcessed: Int64, elapsedTime: TimeInterval) -> String {
        guard elapsedTime > 0 else { return "0 B/s" }

        let bytesPerSecond = Double(bytesProcessed) / elapsedTime
        return formatBytes(Int64(bytesPerSecond)) + "/s"
    }

    /// Format estimated time of arrival
    /// - Parameters:
    ///   - bytesProcessed: Bytes processed so far
    ///   - totalBytes: Total bytes to process
    ///   - elapsedTime: Time elapsed in seconds
    /// - Returns: Formatted ETA string (e.g., "00:03")
    private func formatETA(bytesProcessed: Int64, totalBytes: Int64, elapsedTime: TimeInterval) -> String {
        guard bytesProcessed > 0 && elapsedTime > 0 else { return "--:--" }

        let bytesRemaining = totalBytes - bytesProcessed
        let bytesPerSecond = Double(bytesProcessed) / elapsedTime
        let secondsRemaining = Double(bytesRemaining) / bytesPerSecond

        guard secondsRemaining.isFinite && secondsRemaining >= 0 else { return "--:--" }

        let minutes = Int(secondsRemaining) / 60
        let seconds = Int(secondsRemaining) % 60

        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Format byte count in human-readable format
    /// - Parameter bytes: Number of bytes
    /// - Returns: Formatted string (e.g., "5.2 MB", "1.3 GB")
    private func formatBytes(_ bytes: Int64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = 0

        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        if unitIndex == 0 {
            return "\(Int(value)) \(units[unitIndex])"
        } else {
            return String(format: "%.1f %@", value, units[unitIndex])
        }
    }

    /// Write string to stderr
    /// - Parameter string: String to write
    private func writeToStderr(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        stderr.write(data)
    }
}
