import XCTest
import Foundation
@testable import swiftcompress

/// Integration tests for progress indicator feature
/// Tests end-to-end progress functionality with real compression/decompression
final class ProgressIntegrationTests: XCTestCase {

    var testDirectory: String!
    var fileHandler: FileSystemHandler!

    override func setUp() {
        super.setUp()

        // Create temporary test directory
        let tempDir = NSTemporaryDirectory()
        testDirectory = "\(tempDir)progress_test_\(UUID().uuidString)"

        fileHandler = FileSystemHandler()
        try? fileHandler.createDirectory(at: testDirectory)
    }

    override func tearDown() {
        // Clean up test directory
        try? fileHandler.deleteFile(at: testDirectory)
        super.tearDown()
    }

    // MARK: - Test Helpers

    func createAlgorithmRegistry() -> AlgorithmRegistry {
        let registry = AlgorithmRegistry()
        registry.register(LZFSEAlgorithm())
        registry.register(LZ4Algorithm())
        registry.register(ZLIBAlgorithm())
        registry.register(LZMAAlgorithm())
        return registry
    }

    // MARK: - Progress Coordinator Integration

    func testProgressCoordinator_IntegratesWithCompression() throws {
        // Arrange
        let inputPath = "\(testDirectory!)/input.txt"
        let outputPath = "\(testDirectory!)/output.lzfse"

        // Create test file
        let testData = String(repeating: "Hello, World!\n", count: 1000).data(using: .utf8)!
        try testData.write(to: URL(fileURLWithPath: inputPath))

        let algorithmRegistry = createAlgorithmRegistry()
        let pathResolver = FilePathResolver()
        let validationRules = ValidationRules()

        // Act - Create compress command with progress enabled
        let command = CompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            outputDestination: .file(path: outputPath),
            forceOverwrite: false,
            compressionLevel: .balanced,
            progressEnabled: true,
            fileHandler: fileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry,
            progressCoordinator: ProgressCoordinator()
        )

        // Execute
        try command.execute()

        // Assert - Output file should exist
        XCTAssertTrue(fileHandler.fileExists(at: outputPath))
        XCTAssertGreaterThan(try fileHandler.fileSize(at: outputPath), 0)
    }

    func testProgressCoordinator_IntegratesWithDecompression() throws {
        // Arrange - First compress a file
        let inputPath = "\(testDirectory!)/input.txt"
        let compressedPath = "\(testDirectory!)/compressed.lzfse"
        let decompressedPath = "\(testDirectory!)/output.txt"

        let testData = String(repeating: "Test data\n", count: 500).data(using: .utf8)!
        try testData.write(to: URL(fileURLWithPath: inputPath))

        let algorithmRegistry = createAlgorithmRegistry()
        let pathResolver = FilePathResolver()
        let validationRules = ValidationRules()

        // Compress
        let compressCommand = CompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            outputDestination: .file(path: compressedPath),
            forceOverwrite: false,
            compressionLevel: .balanced,
            progressEnabled: false,
            fileHandler: fileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )
        try compressCommand.execute()

        // Act - Decompress with progress enabled
        let decompressCommand = DecompressCommand(
            inputSource: .file(path: compressedPath),
            algorithmName: "lzfse",
            outputDestination: .file(path: decompressedPath),
            forceOverwrite: false,
            progressEnabled: true,
            fileHandler: fileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry,
            progressCoordinator: ProgressCoordinator()
        )
        try decompressCommand.execute()

        // Assert - Decompressed file should match original
        let decompressedData = try Data(contentsOf: URL(fileURLWithPath: decompressedPath))
        XCTAssertEqual(decompressedData, testData)
    }

    func testProgressCoordinator_SilentMode_WithStdout() throws {
        // Arrange
        let inputPath = "\(testDirectory!)/input.txt"
        let testData = "Test data".data(using: .utf8)!
        try testData.write(to: URL(fileURLWithPath: inputPath))

        let algorithmRegistry = createAlgorithmRegistry()
        let pathResolver = FilePathResolver()
        let validationRules = ValidationRules()

        // Act - Compress to stdout with progress enabled (should be silent)
        let command = CompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            outputDestination: .stdout,  // stdout destination
            forceOverwrite: false,
            compressionLevel: .balanced,
            progressEnabled: true,  // Should be ignored due to stdout
            fileHandler: fileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry,
            progressCoordinator: ProgressCoordinator()
        )

        // Assert - Should not crash (progress is silently disabled)
        XCTAssertNoThrow(try command.execute())
    }

    func testProgressCoordinator_HandlesLargeFile() throws {
        // Arrange
        let inputPath = "\(testDirectory!)/large.txt"
        let outputPath = "\(testDirectory!)/large.lzfse"

        // Create larger test file (1 MB)
        let testData = Data(repeating: 0x41, count: 1024 * 1024)
        try testData.write(to: URL(fileURLWithPath: inputPath))

        let algorithmRegistry = createAlgorithmRegistry()
        let pathResolver = FilePathResolver()
        let validationRules = ValidationRules()

        // Act - Compress large file with progress
        let command = CompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lz4",  // Fast algorithm for test
            outputDestination: .file(path: outputPath),
            forceOverwrite: false,
            compressionLevel: .fast,
            progressEnabled: true,
            fileHandler: fileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry,
            progressCoordinator: ProgressCoordinator()
        )

        // Execute
        try command.execute()

        // Assert
        XCTAssertTrue(fileHandler.fileExists(at: outputPath))
    }

    func testProgressCoordinator_MultipleOperationsSequential() throws {
        // Arrange
        let algorithmRegistry = createAlgorithmRegistry()
        let pathResolver = FilePathResolver()
        let validationRules = ValidationRules()

        // Act - Run multiple operations with progress
        for i in 0..<5 {
            let inputPath = "\(testDirectory!)/input\(i).txt"
            let outputPath = "\(testDirectory!)/output\(i).lzfse"

            let testData = "Test \(i)".data(using: .utf8)!
            try testData.write(to: URL(fileURLWithPath: inputPath))

            let command = CompressCommand(
                inputSource: .file(path: inputPath),
                algorithmName: "lzfse",
                outputDestination: .file(path: outputPath),
                forceOverwrite: false,
                compressionLevel: .balanced,
                progressEnabled: true,
                fileHandler: fileHandler,
                pathResolver: pathResolver,
                validationRules: validationRules,
                algorithmRegistry: algorithmRegistry,
                progressCoordinator: ProgressCoordinator()
            )

            try command.execute()
        }

        // Assert - All files should exist
        for i in 0..<5 {
            let outputPath = "\(testDirectory!)/output\(i).lzfse"
            XCTAssertTrue(fileHandler.fileExists(at: outputPath))
        }
    }

    func testProgressCoordinator_DisabledProgress_Works() throws {
        // Arrange
        let inputPath = "\(testDirectory!)/input.txt"
        let outputPath = "\(testDirectory!)/output.lzfse"

        let testData = "Test data".data(using: .utf8)!
        try testData.write(to: URL(fileURLWithPath: inputPath))

        let algorithmRegistry = createAlgorithmRegistry()
        let pathResolver = FilePathResolver()
        let validationRules = ValidationRules()

        // Act - Compress without progress
        let command = CompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            outputDestination: .file(path: outputPath),
            forceOverwrite: false,
            compressionLevel: .balanced,
            progressEnabled: false,  // Disabled
            fileHandler: fileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry,
            progressCoordinator: ProgressCoordinator()
        )

        // Execute
        try command.execute()

        // Assert
        XCTAssertTrue(fileHandler.fileExists(at: outputPath))
    }

    func testProgressCoordinator_RoundTrip_WithProgress() throws {
        // Arrange
        let originalPath = "\(testDirectory!)/original.txt"
        let compressedPath = "\(testDirectory!)/compressed.lzfse"
        let decompressedPath = "\(testDirectory!)/decompressed.txt"

        let originalData = String(repeating: "Round trip test\n", count: 100).data(using: .utf8)!
        try originalData.write(to: URL(fileURLWithPath: originalPath))

        let algorithmRegistry = createAlgorithmRegistry()
        let pathResolver = FilePathResolver()
        let validationRules = ValidationRules()

        // Act - Compress with progress
        let compressCommand = CompressCommand(
            inputSource: .file(path: originalPath),
            algorithmName: "lzfse",
            outputDestination: .file(path: compressedPath),
            forceOverwrite: false,
            compressionLevel: .balanced,
            progressEnabled: true,
            fileHandler: fileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry,
            progressCoordinator: ProgressCoordinator()
        )
        try compressCommand.execute()

        // Decompress with progress
        let decompressCommand = DecompressCommand(
            inputSource: .file(path: compressedPath),
            algorithmName: "lzfse",
            outputDestination: .file(path: decompressedPath),
            forceOverwrite: false,
            progressEnabled: true,
            fileHandler: fileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry,
            progressCoordinator: ProgressCoordinator()
        )
        try decompressCommand.execute()

        // Assert - Data should be identical
        let decompressedData = try Data(contentsOf: URL(fileURLWithPath: decompressedPath))
        XCTAssertEqual(decompressedData, originalData)
    }
}
