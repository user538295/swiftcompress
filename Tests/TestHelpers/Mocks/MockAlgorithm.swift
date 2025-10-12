import Foundation
@testable import swiftcompress

/// Consolidated mock compression algorithm for testing
/// Merges MockAlgorithm, CompressMockAlgorithm, and DecompressMockAlgorithm
public class MockCompressionAlgorithm: CompressionAlgorithmProtocol {
    public let name: String
    public let supportsCustomLevels: Bool

    // MARK: - Data-based Operations (from original MockAlgorithm)

    public var compressResult: Data?
    public var compressError: Error?
    public var decompressResult: Data?
    public var decompressError: Error?

    // MARK: - Stream-based Compression Tracking (from CompressMockAlgorithm)

    public var compressStreamCalled = false
    public var compressStreamError: Error?
    public var lastBufferSize: Int?
    public var lastCompressionLevel: CompressionLevel?

    // MARK: - Stream-based Decompression Tracking (from DecompressMockAlgorithm)

    public var decompressStreamCalled = false
    public var decompressStreamError: Error?

    // MARK: - Initialization

    public init(name: String, supportsCustomLevels: Bool = false) {
        self.name = name
        self.supportsCustomLevels = supportsCustomLevels
    }

    // MARK: - CompressionAlgorithmProtocol Implementation

    public func compress(input: Data) throws -> Data {
        if let error = compressError {
            throw error
        }
        return compressResult ?? Data()
    }

    public func decompress(input: Data) throws -> Data {
        if let error = decompressError {
            throw error
        }
        return decompressResult ?? input
    }

    public func compressStream(input: InputStream, output: OutputStream, bufferSize: Int, compressionLevel: CompressionLevel = .balanced) throws {
        compressStreamCalled = true
        lastBufferSize = bufferSize
        lastCompressionLevel = compressionLevel

        if let error = compressStreamError {
            throw error
        }
        // Success - do nothing
    }

    public func decompressStream(input: InputStream, output: OutputStream, bufferSize: Int) throws {
        decompressStreamCalled = true

        if let error = decompressStreamError {
            throw error
        }
        // Success - do nothing
    }
}
