import Foundation
import Compression

/// LZMA compression algorithm implementation
/// Highest compression ratio with slower compression speed, fast decompression
final class LZMAAlgorithm: CompressionAlgorithmProtocol {

    // MARK: - Properties

    let name = "lzma"

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
                COMPRESSION_LZMA
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
                COMPRESSION_LZMA
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

    // MARK: - Stream-Based Compression (MVP: File-based implementation)

    func compressStream(
        input: InputStream,
        output: OutputStream,
        bufferSize: Int
    ) throws {
        input.open()
        output.open()
        defer {
            input.close()
            output.close()
        }

        // Read entire input stream into memory
        var inputData = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while input.hasBytesAvailable {
            let bytesRead = input.read(buffer, maxLength: bufferSize)
            if bytesRead < 0 {
                throw InfrastructureError.streamReadFailed(
                    underlyingError: input.streamError ?? NSError(domain: "StreamProcessor", code: -1)
                )
            }
            if bytesRead == 0 {
                break
            }
            inputData.append(buffer, count: bytesRead)
        }

        // Compress using in-memory API
        let compressedData = try compress(input: inputData)

        // Write compressed data to output stream
        let bytesWritten = compressedData.withUnsafeBytes { bytes in
            output.write(bytes.baseAddress!.assumingMemoryBound(to: UInt8.self), maxLength: compressedData.count)
        }

        if bytesWritten < 0 {
            throw InfrastructureError.streamWriteFailed(
                underlyingError: output.streamError ?? NSError(domain: "StreamProcessor", code: -1)
            )
        }
    }

    // MARK: - Stream-Based Decompression (MVP: File-based implementation)

    func decompressStream(
        input: InputStream,
        output: OutputStream,
        bufferSize: Int
    ) throws {
        input.open()
        output.open()
        defer {
            input.close()
            output.close()
        }

        // Read entire input stream into memory
        var inputData = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        while input.hasBytesAvailable {
            let bytesRead = input.read(buffer, maxLength: bufferSize)
            if bytesRead < 0 {
                throw InfrastructureError.streamReadFailed(
                    underlyingError: input.streamError ?? NSError(domain: "StreamProcessor", code: -1)
                )
            }
            if bytesRead == 0 {
                break
            }
            inputData.append(buffer, count: bytesRead)
        }

        // Decompress using in-memory API
        let decompressedData = try decompress(input: inputData)

        // Write decompressed data to output stream
        let bytesWritten = decompressedData.withUnsafeBytes { bytes in
            output.write(bytes.baseAddress!.assumingMemoryBound(to: UInt8.self), maxLength: decompressedData.count)
        }

        if bytesWritten < 0 {
            throw InfrastructureError.streamWriteFailed(
                underlyingError: output.streamError ?? NSError(domain: "StreamProcessor", code: -1)
            )
        }
    }
}
