import Foundation

/// Input stream wrapper that tracks bytes read and reports progress
/// Intercepts read operations to track data flow through compression/decompression pipeline
/// Uses composition to wrap any InputStream and add progress tracking capability
public final class ProgressTrackingInputStream: InputStream {

    // MARK: - Properties

    private let wrappedStream: InputStream
    private let progressReporter: ProgressReporterProtocol
    private let totalBytes: Int64
    private var bytesRead: Int64 = 0

    // MARK: - Initialization

    /// Initialize progress tracking input stream
    /// - Parameters:
    ///   - stream: The underlying input stream to wrap
    ///   - totalBytes: Total bytes expected to read (0 if unknown)
    ///   - progressReporter: Progress reporter to notify of read operations
    public init(
        stream: InputStream,
        totalBytes: Int64,
        progressReporter: ProgressReporterProtocol
    ) {
        self.wrappedStream = stream
        self.totalBytes = totalBytes
        self.progressReporter = progressReporter
        super.init(data: Data()) // Required by InputStream initializer
    }

    // MARK: - InputStream Overrides

    /// Read bytes from wrapped stream and track progress
    /// - Parameters:
    ///   - buffer: Buffer to read into
    ///   - len: Maximum number of bytes to read
    /// - Returns: Number of bytes actually read, 0 on EOF, -1 on error
    public override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        let bytesReadNow = wrappedStream.read(buffer, maxLength: len)

        if bytesReadNow > 0 {
            bytesRead += Int64(bytesReadNow)
            progressReporter.update(bytesProcessed: bytesRead, totalBytes: totalBytes)
        }

        return bytesReadNow
    }

    /// Get single byte from wrapped stream
    /// - Parameter buffer: Buffer to store byte
    /// - Returns: true if byte was read successfully
    public override func getBuffer(
        _ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>,
        length len: UnsafeMutablePointer<Int>
    ) -> Bool {
        return wrappedStream.getBuffer(buffer, length: len)
    }

    /// Check if wrapped stream has bytes available
    public override var hasBytesAvailable: Bool {
        return wrappedStream.hasBytesAvailable
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
