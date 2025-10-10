import Foundation

/// Protocol defining compression algorithm interface
/// All concrete algorithms must conform to this protocol
protocol CompressionAlgorithmProtocol {
    /// Algorithm name (e.g., "lzfse", "lz4", "zlib", "lzma")
    var name: String { get }

    /// Indicates whether this algorithm supports custom compression levels
    /// Currently false for all algorithms as Apple's Compression framework
    /// does not provide native level parameters
    var supportsCustomLevels: Bool { get }

    /// Compress data in-memory
    /// - Parameter input: Data to compress
    /// - Returns: Compressed data
    /// - Throws: InfrastructureError if compression fails
    func compress(input: Data) throws -> Data

    /// Decompress data in-memory
    /// - Parameter input: Compressed data
    /// - Returns: Decompressed data
    /// - Throws: InfrastructureError if decompression fails
    func decompress(input: Data) throws -> Data

    /// Stream-based compression for large files
    /// - Parameters:
    ///   - input: Input stream
    ///   - output: Output stream
    ///   - bufferSize: Buffer size in bytes (typically 64KB)
    ///   - compressionLevel: Compression level hint (currently unused by Apple's framework)
    /// - Throws: InfrastructureError if compression fails
    func compressStream(
        input: InputStream,
        output: OutputStream,
        bufferSize: Int,
        compressionLevel: CompressionLevel
    ) throws

    /// Stream-based decompression for large files
    /// - Parameters:
    ///   - input: Input stream (compressed data)
    ///   - output: Output stream (decompressed data)
    ///   - bufferSize: Buffer size in bytes (typically 64KB)
    /// - Throws: InfrastructureError if decompression fails
    func decompressStream(
        input: InputStream,
        output: OutputStream,
        bufferSize: Int
    ) throws
}
