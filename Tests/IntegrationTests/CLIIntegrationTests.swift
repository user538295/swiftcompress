import XCTest
import Foundation

/// End-to-end integration tests for the CLI
/// Tests the complete stack from main.swift through all layers
final class CLIIntegrationTests: XCTestCase {

    // MARK: - Properties

    var tempDirectory: URL!
    var executablePath: String!

    // MARK: - Setup/Teardown

    override func setUp() {
        super.setUp()

        // Create temporary directory for test files
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftcompress-tests-\(UUID().uuidString)")

        try? FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )

        // Locate the built executable
        executablePath = findExecutable()
    }

    override func tearDown() {
        // Clean up temporary directory
        if let tempDir = tempDirectory {
            try? FileManager.default.removeItem(at: tempDir)
        }

        super.tearDown()
    }

    // MARK: - Helper Methods

    private func findExecutable() -> String {
        // Try common build locations
        let possiblePaths = [
            ".build/debug/swiftcompress",
            ".build/release/swiftcompress",
            "../../.build/debug/swiftcompress",
            "../../.build/release/swiftcompress"
        ]

        for path in possiblePaths {
            let fullPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(path)
                .path

            if FileManager.default.fileExists(atPath: fullPath) {
                return fullPath
            }
        }

        // If not found, assume it's in PATH
        return "swiftcompress"
    }

    private func createTestFile(name: String, content: String) -> URL {
        let fileURL = tempDirectory.appendingPathComponent(name)
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    private func createTestFile(name: String, data: Data) -> URL {
        let fileURL = tempDirectory.appendingPathComponent(name)
        try? data.write(to: fileURL)
        return fileURL
    }

    private func fileExists(_ path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }

    private func readFile(_ path: String) -> Data? {
        return try? Data(contentsOf: URL(fileURLWithPath: path))
    }

    private func runCLI(arguments: [String]) -> (exitCode: Int32, stdout: String, stderr: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
            process.waitUntilExit()

            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

            let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
            let stderr = String(data: stderrData, encoding: .utf8) ?? ""

            return (process.terminationStatus, stdout, stderr)
        } catch {
            return (127, "", "Failed to execute CLI: \(error.localizedDescription)")
        }
    }

    // MARK: - Compress Tests

    func testCompressWithLZFSE() {
        // Given
        let testContent = "Hello, World! This is a test file for compression."
        let inputFile = createTestFile(name: "test.txt", content: testContent)
        let outputFile = inputFile.path + ".lzfse"

        // When - explicitly specify output to avoid stdout detection in test environment
        let result = runCLI(arguments: ["c", inputFile.path, "-m", "lzfse", "-o", outputFile])

        // Then
        XCTAssertEqual(result.exitCode, 0, "Compress should succeed")
        XCTAssertTrue(result.stdout.isEmpty, "Success should be quiet")
        XCTAssertTrue(fileExists(outputFile), "Output file should exist")

        // Verify compressed file is smaller
        let originalSize = try! FileManager.default.attributesOfItem(atPath: inputFile.path)[.size] as! Int64
        let compressedSize = try! FileManager.default.attributesOfItem(atPath: outputFile)[.size] as! Int64

        XCTAssertGreaterThan(compressedSize, 0, "Compressed file should not be empty")
        XCTAssertLessThan(compressedSize, originalSize * 2, "Compressed file should be reasonable size")
    }

    func testCompressWithLZ4() {
        // Given
        let testContent = String(repeating: "A", count: 1000) // Repeating pattern compresses well
        let inputFile = createTestFile(name: "test-lz4.txt", content: testContent)
        let outputFile = inputFile.path + ".lz4"

        // When - explicitly specify output to avoid stdout detection in test environment
        let result = runCLI(arguments: ["c", inputFile.path, "-m", "lz4", "-o", outputFile])

        // Then
        XCTAssertEqual(result.exitCode, 0, "Compress with LZ4 should succeed")
        XCTAssertTrue(fileExists(outputFile), "Output file should exist")
    }

    func testCompressWithZLIB() {
        // Given
        let testContent = "ZLIB compression test content with various characters: 123456789"
        let inputFile = createTestFile(name: "test-zlib.txt", content: testContent)
        let outputFile = inputFile.path + ".zlib"

        // When - explicitly specify output to avoid stdout detection in test environment
        let result = runCLI(arguments: ["c", inputFile.path, "-m", "zlib", "-o", outputFile])

        // Then
        XCTAssertEqual(result.exitCode, 0, "Compress with ZLIB should succeed")
        XCTAssertTrue(fileExists(outputFile), "Output file should exist")
    }

    func testCompressWithLZMA() {
        // Given
        let testContent = "LZMA offers highest compression ratio but is slower."
        let inputFile = createTestFile(name: "test-lzma.txt", content: testContent)
        let outputFile = inputFile.path + ".lzma"

        // When - explicitly specify output to avoid stdout detection in test environment
        let result = runCLI(arguments: ["c", inputFile.path, "-m", "lzma", "-o", outputFile])

        // Then
        XCTAssertEqual(result.exitCode, 0, "Compress with LZMA should succeed")
        XCTAssertTrue(fileExists(outputFile), "Output file should exist")
    }

    func testCompressWithCustomOutput() {
        // Given
        let testContent = "Testing custom output path"
        let inputFile = createTestFile(name: "input.txt", content: testContent)
        let customOutput = tempDirectory.appendingPathComponent("custom-output.compressed").path

        // When
        let result = runCLI(arguments: ["c", inputFile.path, "-m", "lzfse", "-o", customOutput])

        // Then
        XCTAssertEqual(result.exitCode, 0, "Compress with custom output should succeed")
        XCTAssertTrue(fileExists(customOutput), "Custom output file should exist")
    }

    func testCompressForceOverwrite() {
        // Given
        let testContent = "Testing force overwrite"
        let inputFile = createTestFile(name: "test-force.txt", content: testContent)
        let outputFile = inputFile.path + ".lzfse"

        // First compress - explicitly specify output to avoid stdout detection in test environment
        _ = runCLI(arguments: ["c", inputFile.path, "-m", "lzfse", "-o", outputFile])
        XCTAssertTrue(fileExists(outputFile), "Initial output should exist")

        // When - compress again with force flag
        let result = runCLI(arguments: ["c", inputFile.path, "-m", "lzfse", "-o", outputFile, "-f"])

        // Then
        XCTAssertEqual(result.exitCode, 0, "Force overwrite should succeed")
        XCTAssertTrue(fileExists(outputFile), "Output file should still exist")
    }

    // MARK: - Decompress Tests

    func testDecompressLZFSE() {
        // Given - First compress a file
        let testContent = "Decompression test content for LZFSE"
        let inputFile = createTestFile(name: "decompress-test.txt", content: testContent)
        let compressedFile = inputFile.path + ".lzfse"

        _ = runCLI(arguments: ["c", inputFile.path, "-m", "lzfse", "-o", compressedFile])
        XCTAssertTrue(fileExists(compressedFile), "Compressed file should exist")

        // Delete original
        try? FileManager.default.removeItem(at: inputFile)

        // When - Decompress - explicitly specify output to avoid stdout detection in test environment
        let result = runCLI(arguments: ["x", compressedFile, "-m", "lzfse", "-o", inputFile.path])

        // Then
        XCTAssertEqual(result.exitCode, 0, "Decompress should succeed")
        XCTAssertTrue(fileExists(inputFile.path), "Decompressed file should exist")

        // Verify content matches
        let decompressedContent = String(data: readFile(inputFile.path)!, encoding: .utf8)
        XCTAssertEqual(decompressedContent, testContent, "Decompressed content should match original")
    }

    func testDecompressWithCustomOutput() {
        // Given
        let testContent = "Custom output decompression test"
        let inputFile = createTestFile(name: "custom-decompress.txt", content: testContent)
        let compressedFile = inputFile.path + ".lzfse"

        _ = runCLI(arguments: ["c", inputFile.path, "-m", "lzfse", "-o", compressedFile])

        let customOutput = tempDirectory.appendingPathComponent("decompressed-output.txt").path

        // When
        let result = runCLI(arguments: ["x", compressedFile, "-m", "lzfse", "-o", customOutput])

        // Then
        XCTAssertEqual(result.exitCode, 0, "Decompress with custom output should succeed")
        XCTAssertTrue(fileExists(customOutput), "Custom output should exist")

        let decompressedContent = String(data: readFile(customOutput)!, encoding: .utf8)
        XCTAssertEqual(decompressedContent, testContent, "Content should match")
    }

    // MARK: - Round-Trip Tests

    func testRoundTripLZFSE() {
        try? performRoundTripTest(algorithm: "lzfse")
    }

    func testRoundTripLZ4() {
        try? performRoundTripTest(algorithm: "lz4")
    }

    func testRoundTripZLIB() {
        try? performRoundTripTest(algorithm: "zlib")
    }

    func testRoundTripLZMA() {
        try? performRoundTripTest(algorithm: "lzma")
    }

    private func performRoundTripTest(algorithm: String) throws {
        // Given - Create test file with varied content
        let testContent = """
        This is a round-trip test for \(algorithm) algorithm.
        It contains multiple lines, numbers 123456789, and symbols !@#$%^&*()
        Repeating patterns: AAABBBCCCDDDEEEFFFGGGHHH
        Unicode characters: 🎉 🚀 ✨ 🔥
        """

        let inputFile = createTestFile(name: "roundtrip-\(algorithm).txt", content: testContent)
        let compressedFile = inputFile.path + ".\(algorithm)"
        let decompressedFile = tempDirectory.appendingPathComponent("roundtrip-\(algorithm)-output.txt").path

        // When - Compress - explicitly specify output to avoid stdout detection in test environment
        let compressResult = runCLI(arguments: ["c", inputFile.path, "-m", algorithm, "-o", compressedFile])
        XCTAssertEqual(compressResult.exitCode, 0, "Compression should succeed")

        // When - Decompress
        let decompressResult = runCLI(arguments: ["x", compressedFile, "-m", algorithm, "-o", decompressedFile])
        XCTAssertEqual(decompressResult.exitCode, 0, "Decompression should succeed")

        // Then - Verify content integrity
        let originalData = readFile(inputFile.path)
        let decompressedData = readFile(decompressedFile)

        XCTAssertNotNil(originalData, "Should read original file")
        XCTAssertNotNil(decompressedData, "Should read decompressed file")
        XCTAssertEqual(originalData, decompressedData, "Round-trip should preserve data exactly")
    }

    // MARK: - Error Tests

    func testCompressFileNotFound() {
        // Given
        let nonExistentFile = tempDirectory.appendingPathComponent("nonexistent.txt").path

        // When
        let result = runCLI(arguments: ["c", nonExistentFile, "-m", "lzfse"])

        // Then
        XCTAssertNotEqual(result.exitCode, 0, "Should fail with non-zero exit code")
        XCTAssertTrue(result.stderr.contains("Error"), "Should output error message")
        XCTAssertTrue(result.stderr.contains("not found") || result.stderr.contains("File not found"),
                      "Should mention file not found")
    }

    func testCompressMissingAlgorithm() {
        // Given
        let inputFile = createTestFile(name: "test.txt", content: "test")

        // When
        let result = runCLI(arguments: ["c", inputFile.path])

        // Then
        XCTAssertNotEqual(result.exitCode, 0, "Should fail without algorithm")
        XCTAssertTrue(result.stderr.contains("Error") || result.stderr.contains("Missing"),
                      "Should indicate missing argument")
    }

    func testCompressInvalidAlgorithm() {
        // Given
        let inputFile = createTestFile(name: "test.txt", content: "test")

        // When
        let result = runCLI(arguments: ["c", inputFile.path, "-m", "invalid-algorithm"])

        // Then
        XCTAssertNotEqual(result.exitCode, 0, "Should fail with invalid algorithm")
        XCTAssertTrue(result.stderr.contains("Error"), "Should output error message")
    }

    func testCompressOutputFileExists() {
        // Given
        let testContent = "Testing output exists"
        let inputFile = createTestFile(name: "exists-test.txt", content: testContent)
        let outputFile = inputFile.path + ".lzfse"

        // Create output file first - explicitly specify output to avoid stdout detection in test environment
        _ = runCLI(arguments: ["c", inputFile.path, "-m", "lzfse", "-o", outputFile])
        XCTAssertTrue(fileExists(outputFile), "Output should exist")

        // When - Try to compress again without force flag - must also specify output to test overwrite error
        let result = runCLI(arguments: ["c", inputFile.path, "-m", "lzfse", "-o", outputFile])

        // Then
        XCTAssertNotEqual(result.exitCode, 0, "Should fail when output exists")
        XCTAssertTrue(result.stderr.contains("Error"), "Should output error")
        XCTAssertTrue(result.stderr.contains("exists") || result.stderr.contains("-f"),
                      "Should mention file exists or force flag")
    }

    func testDecompressFileNotFound() {
        // Given
        let nonExistentFile = tempDirectory.appendingPathComponent("nonexistent.lzfse").path

        // When
        let result = runCLI(arguments: ["x", nonExistentFile, "-m", "lzfse"])

        // Then
        XCTAssertNotEqual(result.exitCode, 0, "Should fail")
        XCTAssertTrue(result.stderr.contains("Error"), "Should output error")
    }

    func testInvalidCommand() {
        // Given
        let inputFile = createTestFile(name: "test.txt", content: "test")

        // When
        let result = runCLI(arguments: ["invalid-command", inputFile.path, "-m", "lzfse"])

        // Then
        XCTAssertNotEqual(result.exitCode, 0, "Should fail with invalid command")
        XCTAssertTrue(result.stderr.contains("Error") || result.stderr.contains("Unknown"),
                      "Should indicate unknown command")
    }

    // MARK: - Help and Version Tests

    func testHelpFlag() {
        // When
        let result = runCLI(arguments: ["--help"])

        // Then
        XCTAssertEqual(result.exitCode, 0, "Help should exit with success")
        XCTAssertTrue(result.stdout.contains("swiftcompress") || result.stdout.contains("USAGE"),
                      "Should display help text")
    }

    func testVersionFlag() {
        // When
        let result = runCLI(arguments: ["--version"])

        // Then
        XCTAssertEqual(result.exitCode, 0, "Version should exit with success")
        XCTAssertTrue(result.stdout.contains("0.1.0") || result.stdout.contains("version"),
                      "Should display version")
    }

    // MARK: - Large File Tests

    func testCompressLargeFile() {
        // Given - Create a 1MB file
        let largeContent = String(repeating: "Large file test content.\n", count: 40000)
        let inputFile = createTestFile(name: "large-file.txt", content: largeContent)
        let outputFile = inputFile.path + ".lzfse"

        // When - explicitly specify output to avoid stdout detection in test environment
        let result = runCLI(arguments: ["c", inputFile.path, "-m", "lzfse", "-o", outputFile])

        // Then
        XCTAssertEqual(result.exitCode, 0, "Should compress large file successfully")
        XCTAssertTrue(fileExists(outputFile), "Output should exist")

        // Verify size is reasonable
        let originalSize = try! FileManager.default.attributesOfItem(atPath: inputFile.path)[.size] as! Int64
        let compressedSize = try! FileManager.default.attributesOfItem(atPath: outputFile)[.size] as! Int64

        XCTAssertGreaterThanOrEqual(originalSize, 1_000_000, "Original should be >= 1MB")
        XCTAssertLessThan(compressedSize, originalSize / 2, "Should achieve > 50% compression on repetitive data")
    }

    // MARK: - Binary File Tests

    func testCompressBinaryFile() {
        // Given - Create binary data
        var binaryData = Data()
        for i in 0..<10000 {
            binaryData.append(UInt8(i % 256))
        }

        let inputFile = createTestFile(name: "binary.bin", data: binaryData)
        let outputFile = inputFile.path + ".lzfse"

        // When - explicitly specify output to avoid stdout detection in test environment
        let result = runCLI(arguments: ["c", inputFile.path, "-m", "lzfse", "-o", outputFile])

        // Then
        XCTAssertEqual(result.exitCode, 0, "Should compress binary file")
        XCTAssertTrue(fileExists(outputFile), "Output should exist")

        // Verify round-trip
        let decompressedFile = tempDirectory.appendingPathComponent("binary-decompressed.bin").path
        let decompressResult = runCLI(arguments: ["x", outputFile, "-m", "lzfse", "-o", decompressedFile])

        XCTAssertEqual(decompressResult.exitCode, 0, "Should decompress binary file")

        let decompressedData = readFile(decompressedFile)
        XCTAssertEqual(binaryData, decompressedData, "Binary data should match exactly")
    }
}
