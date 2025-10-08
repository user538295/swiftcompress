import XCTest
import Foundation
@testable import swiftcompress

/// Integration tests for all compression algorithms
/// Tests round-trip compression/decompression and file I/O
final class AlgorithmIntegrationTests: XCTestCase {

    // MARK: - Test Data

    private let testText = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod
        tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
        quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

        This is a test string with multiple paragraphs and some repetition.
        This is a test string with multiple paragraphs and some repetition.
        This is a test string with multiple paragraphs and some repetition.

        12345678901234567890123456789012345678901234567890
        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
        !@#$%^&*()_+-=[]{}|;:',.<>?/~`
        """

    private func createBinaryData() -> Data {
        var data = Data()
        for i in 0..<1000 {
            data.append(UInt8(i % 256))
        }
        return data
    }

    // MARK: - LZFSE Algorithm Tests

    func testLZFSE_InMemoryRoundTrip_Text() throws {
        let algorithm = LZFSEAlgorithm()
        let originalData = testText.data(using: .utf8)!

        let compressed = try algorithm.compress(input: originalData)
        XCTAssertLessThan(compressed.count, originalData.count, "Compressed data should be smaller")

        let decompressed = try algorithm.decompress(input: compressed)
        XCTAssertEqual(decompressed, originalData, "Round-trip should preserve data")

        let recoveredText = String(data: decompressed, encoding: .utf8)
        XCTAssertEqual(recoveredText, testText, "Round-trip should preserve text")
    }

    func testLZFSE_InMemoryRoundTrip_Binary() throws {
        let algorithm = LZFSEAlgorithm()
        let originalData = createBinaryData()

        let compressed = try algorithm.compress(input: originalData)
        let decompressed = try algorithm.decompress(input: compressed)

        XCTAssertEqual(decompressed, originalData, "Round-trip should preserve binary data")
    }

    func testLZFSE_StreamRoundTrip() throws {
        let algorithm = LZFSEAlgorithm()
        let originalData = testText.data(using: .utf8)!

        // Create temporary files
        let tempDir = FileManager.default.temporaryDirectory
        let inputFile = tempDir.appendingPathComponent("lzfse_test_input.txt")
        let compressedFile = tempDir.appendingPathComponent("lzfse_test_compressed.bin")
        let outputFile = tempDir.appendingPathComponent("lzfse_test_output.txt")

        defer {
            try? FileManager.default.removeItem(at: inputFile)
            try? FileManager.default.removeItem(at: compressedFile)
            try? FileManager.default.removeItem(at: outputFile)
        }

        // Write original data
        try originalData.write(to: inputFile)

        // Compress via stream
        let inputStream = InputStream(url: inputFile)!
        let compressedOutputStream = OutputStream(url: compressedFile, append: false)!
        try algorithm.compressStream(input: inputStream, output: compressedOutputStream, bufferSize: 65536)

        // Decompress via stream
        let compressedInputStream = InputStream(url: compressedFile)!
        let outputStream = OutputStream(url: outputFile, append: false)!
        try algorithm.decompressStream(input: compressedInputStream, output: outputStream, bufferSize: 65536)

        // Verify
        let recoveredData = try Data(contentsOf: outputFile)
        XCTAssertEqual(recoveredData, originalData, "Stream round-trip should preserve data")
    }

    // MARK: - LZ4 Algorithm Tests

    func testLZ4_InMemoryRoundTrip_Text() throws {
        let algorithm = LZ4Algorithm()
        let originalData = testText.data(using: .utf8)!

        let compressed = try algorithm.compress(input: originalData)
        XCTAssertLessThan(compressed.count, originalData.count, "Compressed data should be smaller")

        let decompressed = try algorithm.decompress(input: compressed)
        XCTAssertEqual(decompressed, originalData, "Round-trip should preserve data")
    }

    func testLZ4_InMemoryRoundTrip_Binary() throws {
        let algorithm = LZ4Algorithm()
        let originalData = createBinaryData()

        let compressed = try algorithm.compress(input: originalData)
        let decompressed = try algorithm.decompress(input: compressed)

        XCTAssertEqual(decompressed, originalData, "Round-trip should preserve binary data")
    }

    func testLZ4_StreamRoundTrip() throws {
        let algorithm = LZ4Algorithm()
        let originalData = testText.data(using: .utf8)!

        let tempDir = FileManager.default.temporaryDirectory
        let inputFile = tempDir.appendingPathComponent("lz4_test_input.txt")
        let compressedFile = tempDir.appendingPathComponent("lz4_test_compressed.bin")
        let outputFile = tempDir.appendingPathComponent("lz4_test_output.txt")

        defer {
            try? FileManager.default.removeItem(at: inputFile)
            try? FileManager.default.removeItem(at: compressedFile)
            try? FileManager.default.removeItem(at: outputFile)
        }

        try originalData.write(to: inputFile)

        let inputStream = InputStream(url: inputFile)!
        let compressedOutputStream = OutputStream(url: compressedFile, append: false)!
        try algorithm.compressStream(input: inputStream, output: compressedOutputStream, bufferSize: 65536)

        let compressedInputStream = InputStream(url: compressedFile)!
        let outputStream = OutputStream(url: outputFile, append: false)!
        try algorithm.decompressStream(input: compressedInputStream, output: outputStream, bufferSize: 65536)

        let recoveredData = try Data(contentsOf: outputFile)
        XCTAssertEqual(recoveredData, originalData, "Stream round-trip should preserve data")
    }

    // MARK: - Zlib Algorithm Tests

    func testZlib_InMemoryRoundTrip_Text() throws {
        let algorithm = ZLIBAlgorithm()
        let originalData = testText.data(using: .utf8)!

        let compressed = try algorithm.compress(input: originalData)
        XCTAssertLessThan(compressed.count, originalData.count, "Compressed data should be smaller")

        let decompressed = try algorithm.decompress(input: compressed)
        XCTAssertEqual(decompressed, originalData, "Round-trip should preserve data")
    }

    func testZlib_InMemoryRoundTrip_Binary() throws {
        let algorithm = ZLIBAlgorithm()
        let originalData = createBinaryData()

        let compressed = try algorithm.compress(input: originalData)
        let decompressed = try algorithm.decompress(input: compressed)

        XCTAssertEqual(decompressed, originalData, "Round-trip should preserve binary data")
    }

    func testZlib_StreamRoundTrip() throws {
        let algorithm = ZLIBAlgorithm()
        let originalData = testText.data(using: .utf8)!

        let tempDir = FileManager.default.temporaryDirectory
        let inputFile = tempDir.appendingPathComponent("zlib_test_input.txt")
        let compressedFile = tempDir.appendingPathComponent("zlib_test_compressed.bin")
        let outputFile = tempDir.appendingPathComponent("zlib_test_output.txt")

        defer {
            try? FileManager.default.removeItem(at: inputFile)
            try? FileManager.default.removeItem(at: compressedFile)
            try? FileManager.default.removeItem(at: outputFile)
        }

        try originalData.write(to: inputFile)

        let inputStream = InputStream(url: inputFile)!
        let compressedOutputStream = OutputStream(url: compressedFile, append: false)!
        try algorithm.compressStream(input: inputStream, output: compressedOutputStream, bufferSize: 65536)

        let compressedInputStream = InputStream(url: compressedFile)!
        let outputStream = OutputStream(url: outputFile, append: false)!
        try algorithm.decompressStream(input: compressedInputStream, output: outputStream, bufferSize: 65536)

        let recoveredData = try Data(contentsOf: outputFile)
        XCTAssertEqual(recoveredData, originalData, "Stream round-trip should preserve data")
    }

    // MARK: - LZMA Algorithm Tests

    func testLZMA_InMemoryRoundTrip_Text() throws {
        let algorithm = LZMAAlgorithm()
        let originalData = testText.data(using: .utf8)!

        let compressed = try algorithm.compress(input: originalData)
        XCTAssertLessThan(compressed.count, originalData.count, "Compressed data should be smaller")

        let decompressed = try algorithm.decompress(input: compressed)
        XCTAssertEqual(decompressed, originalData, "Round-trip should preserve data")
    }

    func testLZMA_InMemoryRoundTrip_Binary() throws {
        let algorithm = LZMAAlgorithm()
        let originalData = createBinaryData()

        let compressed = try algorithm.compress(input: originalData)
        let decompressed = try algorithm.decompress(input: compressed)

        XCTAssertEqual(decompressed, originalData, "Round-trip should preserve binary data")
    }

    func testLZMA_StreamRoundTrip() throws {
        let algorithm = LZMAAlgorithm()
        let originalData = testText.data(using: .utf8)!

        let tempDir = FileManager.default.temporaryDirectory
        let inputFile = tempDir.appendingPathComponent("lzma_test_input.txt")
        let compressedFile = tempDir.appendingPathComponent("lzma_test_compressed.bin")
        let outputFile = tempDir.appendingPathComponent("lzma_test_output.txt")

        defer {
            try? FileManager.default.removeItem(at: inputFile)
            try? FileManager.default.removeItem(at: compressedFile)
            try? FileManager.default.removeItem(at: outputFile)
        }

        try originalData.write(to: inputFile)

        let inputStream = InputStream(url: inputFile)!
        let compressedOutputStream = OutputStream(url: compressedFile, append: false)!
        try algorithm.compressStream(input: inputStream, output: compressedOutputStream, bufferSize: 65536)

        let compressedInputStream = InputStream(url: compressedFile)!
        let outputStream = OutputStream(url: outputFile, append: false)!
        try algorithm.decompressStream(input: compressedInputStream, output: outputStream, bufferSize: 65536)

        let recoveredData = try Data(contentsOf: outputFile)
        XCTAssertEqual(recoveredData, originalData, "Stream round-trip should preserve data")
    }

    // MARK: - Compression Effectiveness Tests

    func testCompressionRatios() throws {
        let algorithms: [(String, CompressionAlgorithmProtocol)] = [
            ("LZFSE", LZFSEAlgorithm()),
            ("LZ4", LZ4Algorithm()),
            ("Zlib", ZLIBAlgorithm()),
            ("LZMA", LZMAAlgorithm())
        ]

        let originalData = testText.data(using: .utf8)!

        print("\n=== Compression Ratios ===")
        print("Original size: \(originalData.count) bytes")

        for (name, algorithm) in algorithms {
            let compressed = try algorithm.compress(input: originalData)
            let ratio = Double(compressed.count) / Double(originalData.count) * 100
            print("\(name): \(compressed.count) bytes (\(String(format: "%.1f", ratio))%)")

            // Verify decompression works
            let decompressed = try algorithm.decompress(input: compressed)
            XCTAssertEqual(decompressed, originalData, "\(name) round-trip failed")
        }
    }

    // MARK: - Empty Data Tests

    func testEmptyData_AllAlgorithms() throws {
        let algorithms: [(String, CompressionAlgorithmProtocol)] = [
            ("LZFSE", LZFSEAlgorithm()),
            ("LZ4", LZ4Algorithm()),
            ("Zlib", ZLIBAlgorithm()),
            ("LZMA", LZMAAlgorithm())
        ]

        let emptyData = Data()

        for (name, algorithm) in algorithms {
            do {
                let compressed = try algorithm.compress(input: emptyData)
                // If compression succeeds, decompression should return empty data
                let decompressed = try algorithm.decompress(input: compressed)
                XCTAssertEqual(decompressed, emptyData, "\(name) should handle empty data")
            } catch InfrastructureError.compressionFailed {
                // It's acceptable for some algorithms to fail on empty input
                print("\(name) failed on empty data (acceptable)")
            }
        }
    }
}
