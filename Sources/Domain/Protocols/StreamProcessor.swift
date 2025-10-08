import Foundation

/// Protocol for stream processing operations
/// Handles binary data streaming for compression/decompression
protocol StreamProcessorProtocol {
    /// Process compression stream
    /// - Parameters:
    ///   - input: Input stream (uncompressed data)
    ///   - output: Output stream (compressed data)
    ///   - algorithm: Compression algorithm to use
    ///   - bufferSize: Size of processing buffer
    /// - Throws: InfrastructureError if processing fails
    func processCompression(
        input: InputStream,
        output: OutputStream,
        algorithm: CompressionAlgorithmProtocol,
        bufferSize: Int
    ) throws

    /// Process decompression stream
    /// - Parameters:
    ///   - input: Input stream (compressed data)
    ///   - output: Output stream (decompressed data)
    ///   - algorithm: Decompression algorithm to use
    ///   - bufferSize: Size of processing buffer
    /// - Throws: InfrastructureError if processing fails
    func processDecompression(
        input: InputStream,
        output: OutputStream,
        algorithm: CompressionAlgorithmProtocol,
        bufferSize: Int
    ) throws
}
