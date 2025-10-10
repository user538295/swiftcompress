import Foundation

/// Output stream wrapper that tracks bytes written and reports progress
/// Intercepts write operations to track data flow through compression/decompression pipeline
/// Uses composition to wrap any OutputStream and add progress tracking capability
public final class ProgressTrackingOutputStream: OutputStream {

    // MARK: - Properties

    private let wrappedStream: OutputStream
    private let progressReporter: ProgressReporterProtocol
    private let totalBytes: Int64
    private var bytesWritten: Int64 = 0

    // MARK: - Initialization

    /// Initialize progress tracking output stream
    /// - Parameters:
    ///   - stream: The underlying output stream to wrap
    ///   - totalBytes: Total bytes expected to write (0 if unknown)
    ///   - progressReporter: Progress reporter to notify of write operations
    public init(
        stream: OutputStream,
        totalBytes: Int64,
        progressReporter: ProgressReporterProtocol
    ) {
        self.wrappedStream = stream
        self.totalBytes = totalBytes
        self.progressReporter = progressReporter
        super.init(toMemory: ()) // Required by OutputStream initializer
    }

    // MARK: - OutputStream Overrides

    /// Write bytes to wrapped stream and track progress
    /// - Parameters:
    ///   - buffer: Buffer containing bytes to write
    ///   - len: Number of bytes to write
    /// - Returns: Number of bytes actually written, -1 on error
    public override func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        let bytesWrittenNow = wrappedStream.write(buffer, maxLength: len)

        if bytesWrittenNow > 0 {
            bytesWritten += Int64(bytesWrittenNow)
            progressReporter.update(bytesProcessed: bytesWritten, totalBytes: totalBytes)
        }

        return bytesWrittenNow
    }

    /// Check if wrapped stream has space available
    public override var hasSpaceAvailable: Bool {
        return wrappedStream.hasSpaceAvailable
    }

    /// Open wrapped stream
    public override func open() {
        wrappedStream.open()
    }

    /// Close wrapped stream
    public override func close() {
        wrappedStream.close()
    }

    /// Delegate to wrapped stream
    public override var delegate: StreamDelegate? {
        get { return wrappedStream.delegate }
        set { wrappedStream.delegate = newValue }
    }

    /// Delegate to wrapped stream
    public override var streamStatus: Stream.Status {
        return wrappedStream.streamStatus
    }

    /// Delegate to wrapped stream
    public override var streamError: Error? {
        return wrappedStream.streamError
    }

    /// Schedule wrapped stream in run loop
    public override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        wrappedStream.schedule(in: aRunLoop, forMode: mode)
    }

    /// Remove wrapped stream from run loop
    public override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        wrappedStream.remove(from: aRunLoop, forMode: mode)
    }

    /// Get property from wrapped stream
    public override func property(forKey key: Stream.PropertyKey) -> Any? {
        return wrappedStream.property(forKey: key)
    }

    /// Set property on wrapped stream
    public override func setProperty(_ property: Any?, forKey key: Stream.PropertyKey) -> Bool {
        return wrappedStream.setProperty(property, forKey: key)
    }
}
