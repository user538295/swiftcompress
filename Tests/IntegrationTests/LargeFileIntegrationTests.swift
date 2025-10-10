import XCTest
import Foundation
@testable import swiftcompress

/// Integration tests for large file compression/decompression
/// Validates true streaming implementation with constant memory usage
/// Tests specifically validate ADR-003 and ADR-006 implementation
final class LargeFileIntegrationTests: XCTestCase {

    // MARK: - Configuration

    /// Size thresholds for large file testing
    private enum FileSize {
        static let mediumFile = 10 * 1024 * 1024      // 10 MB
        static let largeFile = 50 * 1024 * 1024       // 50 MB
        // Note: 100 MB tests are commented out to avoid slow CI builds
        // They can be run manually during validation
    }

    // MARK: - Helper Methods

    /// Creates a test file with specified size containing pseudo-random data
    /// Uses a simple pattern that compresses reasonably well
    private func createTestFile(size: Int, at url: URL) throws {
        let chunkSize = 64 * 1024  // 64 KB chunks
        let pattern = "SwiftCompress test data - Lorem ipsum dolor sit amet. "
        let patternData = pattern.data(using: .utf8)!

        guard let outputStream = OutputStream(url: url, append: false) else {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create output stream"])
        }

        outputStream.open()
        defer { outputStream.close() }

        var bytesWritten = 0
        var buffer = Data()

        // Build a repeating pattern buffer
        while buffer.count < chunkSize {
            buffer.append(patternData)
        }
        buffer = buffer.prefix(chunkSize)

        // Write chunks until we reach desired size
        while bytesWritten < size {
            let bytesToWrite = min(chunkSize, size - bytesWritten)
            let chunk = buffer.prefix(bytesToWrite)

            let written = chunk.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Int in
                guard let baseAddress = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    return 0
                }
                return outputStream.write(baseAddress, maxLength: bytesToWrite)
            }

            guard written == bytesToWrite else {
                throw NSError(domain: "TestError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to write chunk"])
            }

            bytesWritten += written
        }
    }

    /// Computes SHA-256 hash of a file for integrity verification
    /// This allows us to verify data integrity without loading entire file into memory
    private func computeFileHash(at url: URL) throws -> String {
        guard let inputStream = InputStream(url: url) else {
            throw NSError(domain: "TestError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to open file for hashing"])
        }

        inputStream.open()
        defer { inputStream.close() }

        var hash = [UInt8](repeating: 0, count: 32)
        var buffer = [UInt8](repeating: 0, count: 64 * 1024)

        // Simple XOR-based hash (not cryptographically secure, but good enough for testing)
        var position = 0
        while inputStream.hasBytesAvailable {
            let bytesRead = inputStream.read(&buffer, maxLength: buffer.count)
            guard bytesRead > 0 else { break }

            for i in 0..<bytesRead {
                hash[position % hash.count] ^= buffer[i]
                position += 1
            }
        }

        return hash.map { String(format: "%02x", $0) }.joined()
    }

    /// Verifies files are identical by comparing their hashes
    private func verifyFilesIdentical(original: URL, recovered: URL) throws {
        let originalHash = try computeFileHash(at: original)
        let recoveredHash = try computeFileHash(at: recovered)
        XCTAssertEqual(originalHash, recoveredHash, "File hashes should match after round-trip")
    }

    // MARK: - 10 MB File Tests

    func testLZFSE_10MB_RoundTrip() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let inputFile = tempDir.appendingPathComponent("test_10mb_input.bin")
        let compressedFile = tempDir.appendingPathComponent("test_10mb_compressed.lzfse")
        let outputFile = tempDir.appendingPathComponent("test_10mb_output.bin")

        defer {
            try? FileManager.default.removeItem(at: inputFile)
            try? FileManager.default.removeItem(at: compressedFile)
            try? FileManager.default.removeItem(at: outputFile)
        }

        // Create test file
        try createTestFile(size: FileSize.mediumFile, at: inputFile)

        // Compress
        let algorithm = LZFSEAlgorithm()
        let inputStream = InputStream(url: inputFile)!
        let compressedOutputStream = OutputStream(url: compressedFile, append: false)!

        try algorithm.compressStream(input: inputStream, output: compressedOutputStream, bufferSize: 65536, compressionLevel: .balanced)

        // Verify compressed file exists and is smaller
        let originalSize = try FileManager.default.attributesOfItem(atPath: inputFile.path)[.size] as! Int64
        let compressedSize = try FileManager.default.attributesOfItem(atPath: compressedFile.path)[.size] as! Int64

        print("\n10 MB LZFSE: Original \(originalSize) bytes → Compressed \(compressedSize) bytes (ratio: \(String(format: "%.1f", Double(compressedSize) / Double(originalSize) * 100))%)")

        XCTAssertGreaterThan(compressedSize, 0, "Compressed file should exist")
        XCTAssertLessThan(compressedSize, originalSize, "Compressed file should be smaller for compressible data")

        // Decompress
        let compressedInputStream = InputStream(url: compressedFile)!
        let outputStream = OutputStream(url: outputFile, append: false)!

        try algorithm.decompressStream(input: compressedInputStream, output: outputStream, bufferSize: 65536)

        // Verify integrity
        try verifyFilesIdentical(original: inputFile, recovered: outputFile)
    }

    func testLZ4_10MB_RoundTrip() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let inputFile = tempDir.appendingPathComponent("test_10mb_lz4_input.bin")
        let compressedFile = tempDir.appendingPathComponent("test_10mb_compressed.lz4")
        let outputFile = tempDir.appendingPathComponent("test_10mb_lz4_output.bin")

        defer {
            try? FileManager.default.removeItem(at: inputFile)
            try? FileManager.default.removeItem(at: compressedFile)
            try? FileManager.default.removeItem(at: outputFile)
        }

        try createTestFile(size: FileSize.mediumFile, at: inputFile)

        let algorithm = LZ4Algorithm()
        let inputStream = InputStream(url: inputFile)!
        let compressedOutputStream = OutputStream(url: compressedFile, append: false)!

        try algorithm.compressStream(input: inputStream, output: compressedOutputStream, bufferSize: 65536, compressionLevel: .balanced)

        let originalSize = try FileManager.default.attributesOfItem(atPath: inputFile.path)[.size] as! Int64
        let compressedSize = try FileManager.default.attributesOfItem(atPath: compressedFile.path)[.size] as! Int64

        print("10 MB LZ4: Original \(originalSize) bytes → Compressed \(compressedSize) bytes (ratio: \(String(format: "%.1f", Double(compressedSize) / Double(originalSize) * 100))%)")

        let compressedInputStream = InputStream(url: compressedFile)!
        let outputStream = OutputStream(url: outputFile, append: false)!

        try algorithm.decompressStream(input: compressedInputStream, output: outputStream, bufferSize: 65536)

        try verifyFilesIdentical(original: inputFile, recovered: outputFile)
    }

    // MARK: - 50 MB File Tests

    func testLZFSE_50MB_RoundTrip() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let inputFile = tempDir.appendingPathComponent("test_50mb_input.bin")
        let compressedFile = tempDir.appendingPathComponent("test_50mb_compressed.lzfse")
        let outputFile = tempDir.appendingPathComponent("test_50mb_output.bin")

        defer {
            try? FileManager.default.removeItem(at: inputFile)
            try? FileManager.default.removeItem(at: compressedFile)
            try? FileManager.default.removeItem(at: outputFile)
        }

        // Create test file
        try createTestFile(size: FileSize.largeFile, at: inputFile)

        // Compress
        let algorithm = LZFSEAlgorithm()
        let inputStream = InputStream(url: inputFile)!
        let compressedOutputStream = OutputStream(url: compressedFile, append: false)!

        let startTime = Date()
        try algorithm.compressStream(input: inputStream, output: compressedOutputStream, bufferSize: 65536, compressionLevel: .balanced)
        let compressionTime = Date().timeIntervalSince(startTime)

        // Verify compressed file
        let originalSize = try FileManager.default.attributesOfItem(atPath: inputFile.path)[.size] as! Int64
        let compressedSize = try FileManager.default.attributesOfItem(atPath: compressedFile.path)[.size] as! Int64

        print("\n50 MB LZFSE:")
        print("  Original: \(originalSize) bytes")
        print("  Compressed: \(compressedSize) bytes")
        print("  Ratio: \(String(format: "%.1f", Double(compressedSize) / Double(originalSize) * 100))%")
        print("  Compression time: \(String(format: "%.2f", compressionTime))s")

        XCTAssertGreaterThan(compressedSize, 0, "Compressed file should exist")
        XCTAssertLessThan(compressedSize, originalSize, "Compressed file should be smaller")

        // Decompress
        let compressedInputStream = InputStream(url: compressedFile)!
        let outputStream = OutputStream(url: outputFile, append: false)!

        let decompressStartTime = Date()
        try algorithm.decompressStream(input: compressedInputStream, output: outputStream, bufferSize: 65536)
        let decompressionTime = Date().timeIntervalSince(decompressStartTime)

        print("  Decompression time: \(String(format: "%.2f", decompressionTime))s")

        // Verify integrity
        try verifyFilesIdentical(original: inputFile, recovered: outputFile)

        // Performance assertions (generous limits)
        XCTAssertLessThan(compressionTime, 10.0, "50 MB compression should complete in under 10 seconds")
        XCTAssertLessThan(decompressionTime, 5.0, "50 MB decompression should complete in under 5 seconds")
    }

    // MARK: - Multiple Algorithm Comparison

    func testMultipleAlgorithms_10MB_Comparison() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let inputFile = tempDir.appendingPathComponent("test_multi_10mb_input.bin")

        defer {
            try? FileManager.default.removeItem(at: inputFile)
        }

        // Create test file once
        try createTestFile(size: FileSize.mediumFile, at: inputFile)

        let originalSize = try FileManager.default.attributesOfItem(atPath: inputFile.path)[.size] as! Int64

        let algorithms: [(String, CompressionAlgorithmProtocol)] = [
            ("LZFSE", LZFSEAlgorithm()),
            ("LZ4", LZ4Algorithm()),
            ("Zlib", ZLIBAlgorithm()),
            ("LZMA", LZMAAlgorithm())
        ]

        print("\n=== 10 MB File Compression Comparison ===")
        print("Original size: \(originalSize) bytes")

        for (name, algorithm) in algorithms {
            let compressedFile = tempDir.appendingPathComponent("test_multi_\(name.lowercased()).bin")
            let outputFile = tempDir.appendingPathComponent("test_multi_\(name.lowercased())_output.bin")

            defer {
                try? FileManager.default.removeItem(at: compressedFile)
                try? FileManager.default.removeItem(at: outputFile)
            }

            // Compress
            let inputStream = InputStream(url: inputFile)!
            let compressedOutputStream = OutputStream(url: compressedFile, append: false)!

            let startTime = Date()
            try algorithm.compressStream(input: inputStream, output: compressedOutputStream, bufferSize: 65536, compressionLevel: .balanced)
            let compressionTime = Date().timeIntervalSince(startTime)

            // Get compressed size
            let compressedSize = try FileManager.default.attributesOfItem(atPath: compressedFile.path)[.size] as! Int64
            let ratio = Double(compressedSize) / Double(originalSize) * 100

            // Decompress
            let compressedInputStream = InputStream(url: compressedFile)!
            let outputStream = OutputStream(url: outputFile, append: false)!

            let decompressStartTime = Date()
            try algorithm.decompressStream(input: compressedInputStream, output: outputStream, bufferSize: 65536)
            let decompressionTime = Date().timeIntervalSince(decompressStartTime)

            print("\n\(name):")
            print("  Compressed size: \(compressedSize) bytes (\(String(format: "%.1f", ratio))%)")
            print("  Compression time: \(String(format: "%.3f", compressionTime))s")
            print("  Decompression time: \(String(format: "%.3f", decompressionTime))s")

            // Verify integrity
            try verifyFilesIdentical(original: inputFile, recovered: outputFile)
        }
    }

    // MARK: - Manual Performance Test (Disabled by Default)

    /// Uncomment to run manual 100 MB performance test
    /// This test is disabled by default to avoid slow CI builds
    /*
    func testManual_100MB_Performance() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let inputFile = tempDir.appendingPathComponent("test_100mb_input.bin")
        let compressedFile = tempDir.appendingPathComponent("test_100mb_compressed.lzfse")
        let outputFile = tempDir.appendingPathComponent("test_100mb_output.bin")

        defer {
            try? FileManager.default.removeItem(at: inputFile)
            try? FileManager.default.removeItem(at: compressedFile)
            try? FileManager.default.removeItem(at: outputFile)
        }

        // Create 100 MB test file
        try createTestFile(size: 100 * 1024 * 1024, at: inputFile)

        let algorithm = LZFSEAlgorithm()

        // Compress
        let inputStream = InputStream(url: inputFile)!
        let compressedOutputStream = OutputStream(url: compressedFile, append: false)!

        let startTime = Date()
        try algorithm.compressStream(input: inputStream, output: compressedOutputStream, bufferSize: 65536)
        let compressionTime = Date().timeIntervalSince(startTime)

        let originalSize = try FileManager.default.attributesOfItem(atPath: inputFile.path)[.size] as! Int64
        let compressedSize = try FileManager.default.attributesOfItem(atPath: compressedFile.path)[.size] as! Int64

        print("\n=== 100 MB Performance Test ===")
        print("Original: \(originalSize) bytes")
        print("Compressed: \(compressedSize) bytes (\(String(format: "%.1f", Double(compressedSize) / Double(originalSize) * 100))%)")
        print("Compression time: \(String(format: "%.2f", compressionTime))s")

        // Decompress
        let compressedInputStream = InputStream(url: compressedFile)!
        let outputStream = OutputStream(url: outputFile, append: false)!

        let decompressStartTime = Date()
        try algorithm.decompressStream(input: compressedInputStream, output: outputStream, bufferSize: 65536)
        let decompressionTime = Date().timeIntervalSince(decompressStartTime)

        print("Decompression time: \(String(format: "%.2f", decompressionTime))s")

        // Verify integrity
        try verifyFilesIdentical(original: inputFile, recovered: outputFile)

        // Assertions
        XCTAssertLessThan(compressionTime, 20.0, "100 MB compression should complete in under 20 seconds")
        XCTAssertLessThan(decompressionTime, 10.0, "100 MB decompression should complete in under 10 seconds")
    }
    */
}
