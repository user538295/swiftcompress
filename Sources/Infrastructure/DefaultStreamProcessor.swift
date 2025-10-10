import Foundation
import Compression

/// Stream-based file processor for compression operations
/// Handles large files with constant memory usage
final class DefaultStreamProcessor: StreamProcessorProtocol {

    // MARK: - Constants

    private static let defaultBufferSize = 65536 // 64KB

    // MARK: - Initialization

    init() {}

    // MARK: - Compression Processing

    func processCompression(
        input: InputStream,
        output: OutputStream,
        algorithm: CompressionAlgorithmProtocol,
        bufferSize: Int = defaultBufferSize
    ) throws {
        // Delegate to algorithm's stream compression
        // Use default balanced level since this is a generic processor
        try algorithm.compressStream(input: input, output: output, bufferSize: bufferSize, compressionLevel: .balanced)
    }

    // MARK: - Decompression Processing

    func processDecompression(
        input: InputStream,
        output: OutputStream,
        algorithm: CompressionAlgorithmProtocol,
        bufferSize: Int = defaultBufferSize
    ) throws {
        // Delegate to algorithm's stream decompression
        try algorithm.decompressStream(input: input, output: output, bufferSize: bufferSize)
    }
}
