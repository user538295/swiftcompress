import Foundation
@testable import swiftcompress

/// Mock compression algorithm for testing
class MockCompressionAlgorithm: CompressionAlgorithmProtocol {
    let name: String
    let supportsCustomLevels = false

    // Test configuration
    var compressResult: Data?
    var compressError: Error?
    var decompressResult: Data?
    var decompressError: Error?

    init(name: String) {
        self.name = name
    }

    func compress(input: Data) throws -> Data {
        if let error = compressError {
            throw error
        }
        return compressResult ?? Data()
    }

    func decompress(input: Data) throws -> Data {
        if let error = decompressError {
            throw error
        }
        return decompressResult ?? input
    }

    func compressStream(input: InputStream, output: OutputStream, bufferSize: Int, compressionLevel: CompressionLevel = .balanced) throws {
        // Stub implementation for testing
    }

    func decompressStream(input: InputStream, output: OutputStream, bufferSize: Int) throws {
        // Stub implementation for testing
    }
}
