import Foundation
import Compression

/// Base class for all Apple Compression framework algorithm implementations
/// Implements the Template Method Pattern to eliminate code duplication
///
/// This abstract base class provides common implementation for all compression
/// operations, requiring subclasses to only specify the algorithm constant and name.
///
/// Subclasses must override:
/// - `algorithmConstant`: The COMPRESSION_* constant for the specific algorithm
/// - `name`: The algorithm name string
class AppleCompressionAlgorithm: CompressionAlgorithmProtocol {

    // MARK: - Abstract Properties (Must Override)

    /// The Apple Compression framework algorithm constant
    /// Subclasses must override with appropriate COMPRESSION_* constant
    var algorithmConstant: compression_algorithm {
        fatalError("Subclass must override algorithmConstant")
    }

    /// Algorithm name (e.g., "lzfse", "lz4", "zlib", "lzma")
    /// Subclasses must override with algorithm-specific name
    var name: String {
        fatalError("Subclass must override name")
    }

    // MARK: - Concrete Properties

    /// Apple's Compression framework does not support custom compression levels
    /// This property indicates future extensibility when/if Apple adds level support
    var supportsCustomLevels: Bool {
        return false
    }

    // MARK: - Initialization

    init() {}

    // MARK: - In-Memory Compression

    func compress(input: Data) throws -> Data {
        let inputSize = input.count
        let outputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: inputSize * 2)
        defer { outputBuffer.deallocate() }

        let compressedSize = input.withUnsafeBytes { inputBytes -> Int in
            guard let baseAddress = inputBytes.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return 0
            }
            return compression_encode_buffer(
                outputBuffer,
                inputSize * 2,
                baseAddress,
                inputSize,
                nil,
                algorithmConstant
            )
        }

        guard compressedSize > 0 else {
            throw InfrastructureError.compressionFailed(
                algorithm: name,
                reason: "Compression returned zero bytes"
            )
        }

        return Data(bytes: outputBuffer, count: compressedSize)
    }

    // MARK: - In-Memory Decompression

    func decompress(input: Data) throws -> Data {
        let inputSize = input.count
        // Allocate buffer for decompressed data (estimate 4x compressed size)
        let estimatedOutputSize = max(inputSize * 4, 65536)
        let outputBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: estimatedOutputSize)
        defer { outputBuffer.deallocate() }

        let decompressedSize = input.withUnsafeBytes { inputBytes -> Int in
            guard let baseAddress = inputBytes.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return 0
            }
            return compression_decode_buffer(
                outputBuffer,
                estimatedOutputSize,
                baseAddress,
                inputSize,
                nil,
                algorithmConstant
            )
        }

        guard decompressedSize > 0 else {
            throw InfrastructureError.decompressionFailed(
                algorithm: name,
                reason: "Decompression returned zero bytes or data is corrupted"
            )
        }

        return Data(bytes: outputBuffer, count: decompressedSize)
    }

    // MARK: - Stream-Based Compression (True streaming implementation)

    func compressStream(
        input: InputStream,
        output: OutputStream,
        bufferSize: Int,
        compressionLevel: CompressionLevel = .balanced
    ) throws {
        // Note: Apple's Compression framework does not support compression levels
        // The compressionLevel parameter is accepted for future extensibility
        // and to maintain a consistent API across all algorithms
        try StreamingUtilities.processCompressionStream(
            input: input,
            output: output,
            algorithm: algorithmConstant,
            algorithmName: name,
            bufferSize: bufferSize
        )
    }

    // MARK: - Stream-Based Decompression (True streaming implementation)

    func decompressStream(
        input: InputStream,
        output: OutputStream,
        bufferSize: Int
    ) throws {
        try StreamingUtilities.processDecompressionStream(
            input: input,
            output: output,
            algorithm: algorithmConstant,
            algorithmName: name,
            bufferSize: bufferSize
        )
    }
}
