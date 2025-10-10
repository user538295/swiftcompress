import Foundation
import Compression

/// LZFSE compression algorithm implementation
/// Apple's native algorithm with good balance of speed and compression ratio
final class LZFSEAlgorithm: CompressionAlgorithmProtocol {

    // MARK: - Properties

    let name = "lzfse"

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
                COMPRESSION_LZFSE
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
                COMPRESSION_LZFSE
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
        bufferSize: Int
    ) throws {
        try StreamingUtilities.processCompressionStream(
            input: input,
            output: output,
            algorithm: COMPRESSION_LZFSE,
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
            algorithm: COMPRESSION_LZFSE,
            algorithmName: name,
            bufferSize: bufferSize
        )
    }
}
