import Foundation
import Compression

/// Utilities for true streaming compression/decompression using Apple's compression_stream API
/// Provides chunk-by-chunk processing with constant memory usage regardless of file size
enum StreamingUtilities {

    // MARK: - Constants

    /// Default buffer size for streaming operations (64 KB)
    static let defaultBufferSize = 65_536

    // MARK: - Compression Stream Processing

    /// Process compression using streaming API for constant memory usage
    /// - Parameters:
    ///   - input: Input stream to read data from
    ///   - output: Output stream to write compressed data to
    ///   - algorithm: Compression algorithm constant (COMPRESSION_LZFSE, COMPRESSION_LZ4, etc.)
    ///   - algorithmName: Algorithm name for error reporting
    ///   - bufferSize: Size of read/write buffers (default: 64 KB)
    /// - Throws: InfrastructureError if compression fails
    static func processCompressionStream(
        input: InputStream,
        output: OutputStream,
        algorithm: compression_algorithm,
        algorithmName: String,
        bufferSize: Int = defaultBufferSize
    ) throws {
        // Open streams
        input.open()
        output.open()
        defer {
            input.close()
            output.close()
        }

        // Allocate buffers first
        let sourceBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            sourceBuffer.deallocate()
            destinationBuffer.deallocate()
        }

        // Initialize compression stream with allocated pointers
        var stream = compression_stream(
            dst_ptr: destinationBuffer,
            dst_size: 0,
            src_ptr: sourceBuffer,
            src_size: 0,
            state: nil
        )

        var status = compression_stream_init(
            &stream,
            COMPRESSION_STREAM_ENCODE,
            algorithm
        )

        guard status == COMPRESSION_STATUS_OK else {
            throw InfrastructureError.compressionInitFailed(
                algorithm: algorithmName,
                underlyingError: NSError(
                    domain: "CompressionStream",
                    code: Int(status.rawValue),
                    userInfo: [NSLocalizedDescriptionKey: "Failed to initialize compression stream"]
                )
            )
        }

        defer {
            compression_stream_destroy(&stream)
        }

        // Reset destination buffer to buffer size after init
        stream.dst_ptr = destinationBuffer
        stream.dst_size = bufferSize

        // Process input stream in chunks
        var inputExhausted = false

        repeat {
            // Read chunk from input stream if source buffer is empty
            if stream.src_size == 0 && !inputExhausted {
                let bytesRead = input.read(sourceBuffer, maxLength: bufferSize)

                if bytesRead < 0 {
                    throw InfrastructureError.streamReadFailed(
                        underlyingError: input.streamError ?? NSError(
                            domain: "InputStream",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Stream read failed"]
                        )
                    )
                }

                if bytesRead == 0 {
                    inputExhausted = true
                } else {
                    stream.src_ptr = UnsafePointer(sourceBuffer)
                    stream.src_size = bytesRead
                }
            }

            // Determine compression flags
            let flags: Int32 = inputExhausted ? Int32(COMPRESSION_STREAM_FINALIZE.rawValue) : 0

            // Process compression
            status = compression_stream_process(&stream, flags)

            // Check for errors
            switch status {
            case COMPRESSION_STATUS_OK, COMPRESSION_STATUS_END:
                break
            case COMPRESSION_STATUS_ERROR:
                throw InfrastructureError.compressionFailed(
                    algorithm: algorithmName,
                    reason: "Compression stream processing failed"
                )
            default:
                throw InfrastructureError.compressionFailed(
                    algorithm: algorithmName,
                    reason: "Unexpected compression status: \(status.rawValue)"
                )
            }

            // Write compressed data to output if destination buffer is full or we're at the end
            let bytesToWrite = bufferSize - stream.dst_size
            if bytesToWrite > 0 {
                let bytesWritten = output.write(destinationBuffer, maxLength: bytesToWrite)

                if bytesWritten < 0 {
                    throw InfrastructureError.streamWriteFailed(
                        underlyingError: output.streamError ?? NSError(
                            domain: "OutputStream",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Stream write failed"]
                        )
                    )
                }

                if bytesWritten != bytesToWrite {
                    throw InfrastructureError.streamWriteFailed(
                        underlyingError: NSError(
                            domain: "OutputStream",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Incomplete write: \(bytesWritten) of \(bytesToWrite) bytes"]
                        )
                    )
                }

                // Reset destination buffer for next iteration
                stream.dst_ptr = destinationBuffer
                stream.dst_size = bufferSize
            }

        } while status != COMPRESSION_STATUS_END
    }

    // MARK: - Decompression Stream Processing

    /// Process decompression using streaming API for constant memory usage
    /// - Parameters:
    ///   - input: Input stream to read compressed data from
    ///   - output: Output stream to write decompressed data to
    ///   - algorithm: Compression algorithm constant (COMPRESSION_LZFSE, COMPRESSION_LZ4, etc.)
    ///   - algorithmName: Algorithm name for error reporting
    ///   - bufferSize: Size of read/write buffers (default: 64 KB)
    /// - Throws: InfrastructureError if decompression fails
    static func processDecompressionStream(
        input: InputStream,
        output: OutputStream,
        algorithm: compression_algorithm,
        algorithmName: String,
        bufferSize: Int = defaultBufferSize
    ) throws {
        // Open streams
        input.open()
        output.open()
        defer {
            input.close()
            output.close()
        }

        // Allocate buffers first
        let sourceBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            sourceBuffer.deallocate()
            destinationBuffer.deallocate()
        }

        // Initialize decompression stream with allocated pointers
        var stream = compression_stream(
            dst_ptr: destinationBuffer,
            dst_size: 0,
            src_ptr: sourceBuffer,
            src_size: 0,
            state: nil
        )

        var status = compression_stream_init(
            &stream,
            COMPRESSION_STREAM_DECODE,
            algorithm
        )

        guard status == COMPRESSION_STATUS_OK else {
            throw InfrastructureError.compressionInitFailed(
                algorithm: algorithmName,
                underlyingError: NSError(
                    domain: "CompressionStream",
                    code: Int(status.rawValue),
                    userInfo: [NSLocalizedDescriptionKey: "Failed to initialize decompression stream"]
                )
            )
        }

        defer {
            compression_stream_destroy(&stream)
        }

        // Reset destination buffer to buffer size after init
        stream.dst_ptr = destinationBuffer
        stream.dst_size = bufferSize

        // Process input stream in chunks
        var inputExhausted = false

        repeat {
            // Read chunk from input stream if source buffer is empty
            if stream.src_size == 0 && !inputExhausted {
                let bytesRead = input.read(sourceBuffer, maxLength: bufferSize)

                if bytesRead < 0 {
                    throw InfrastructureError.streamReadFailed(
                        underlyingError: input.streamError ?? NSError(
                            domain: "InputStream",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Stream read failed"]
                        )
                    )
                }

                if bytesRead == 0 {
                    inputExhausted = true
                } else {
                    stream.src_ptr = UnsafePointer(sourceBuffer)
                    stream.src_size = bytesRead
                }
            }

            // Determine decompression flags
            let flags: Int32 = inputExhausted ? Int32(COMPRESSION_STREAM_FINALIZE.rawValue) : 0

            // Process decompression
            status = compression_stream_process(&stream, flags)

            // Check for errors
            switch status {
            case COMPRESSION_STATUS_OK, COMPRESSION_STATUS_END:
                break
            case COMPRESSION_STATUS_ERROR:
                throw InfrastructureError.decompressionFailed(
                    algorithm: algorithmName,
                    reason: "Decompression stream processing failed - data may be corrupted"
                )
            default:
                throw InfrastructureError.decompressionFailed(
                    algorithm: algorithmName,
                    reason: "Unexpected decompression status: \(status.rawValue)"
                )
            }

            // Write decompressed data to output if destination buffer is full or we're at the end
            let bytesToWrite = bufferSize - stream.dst_size
            if bytesToWrite > 0 {
                let bytesWritten = output.write(destinationBuffer, maxLength: bytesToWrite)

                if bytesWritten < 0 {
                    throw InfrastructureError.streamWriteFailed(
                        underlyingError: output.streamError ?? NSError(
                            domain: "OutputStream",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Stream write failed"]
                        )
                    )
                }

                if bytesWritten != bytesToWrite {
                    throw InfrastructureError.streamWriteFailed(
                        underlyingError: NSError(
                            domain: "OutputStream",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Incomplete write: \(bytesWritten) of \(bytesToWrite) bytes"]
                        )
                    )
                }

                // Reset destination buffer for next iteration
                stream.dst_ptr = destinationBuffer
                stream.dst_size = bufferSize
            }

        } while status != COMPRESSION_STATUS_END
    }
}
