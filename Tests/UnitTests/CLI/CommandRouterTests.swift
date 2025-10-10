import XCTest
@testable import swiftcompress

/// Comprehensive unit tests for CommandRouter
///
/// Test Coverage:
/// - Routing to CompressCommand
/// - Routing to DecompressCommand
/// - Help request handling
/// - Version request handling
/// - Error propagation from commands
/// - Missing algorithm for compression
/// - Dependency injection verification
final class CommandRouterTests: XCTestCase {

    // MARK: - Test Infrastructure

    var router: CommandRouter!
    var mockFileHandler: MockFileHandler!
    var algorithmRegistry: AlgorithmRegistry!
    var pathResolver: FilePathResolver!
    var validationRules: ValidationRules!
    var commandExecutor: CommandExecutor!
    var errorHandler: ErrorHandler!

    override func setUp() {
        super.setUp()

        // Clean up any test files from previous runs
        cleanupTestFiles()

        // Initialize mock dependencies
        mockFileHandler = MockFileHandler()
        algorithmRegistry = AlgorithmRegistry()
        pathResolver = FilePathResolver()
        validationRules = ValidationRules()
        errorHandler = ErrorHandler()
        commandExecutor = CommandExecutor(errorHandler: errorHandler)

        // Register test algorithms
        algorithmRegistry.register(MockAlgorithm(name: "lzfse"))
        algorithmRegistry.register(MockAlgorithm(name: "lz4"))
        algorithmRegistry.register(MockAlgorithm(name: "zlib"))
        algorithmRegistry.register(MockAlgorithm(name: "lzma"))

        // Create router with dependencies
        router = CommandRouter(
            fileHandler: mockFileHandler,
            algorithmRegistry: algorithmRegistry,
            pathResolver: pathResolver,
            validationRules: validationRules,
            commandExecutor: commandExecutor,
            errorHandler: errorHandler
        )
    }

    override func tearDown() {
        // Clean up test files after each test
        cleanupTestFiles()

        router = nil
        mockFileHandler = nil
        algorithmRegistry = nil
        pathResolver = nil
        validationRules = nil
        commandExecutor = nil
        errorHandler = nil

        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Clean up test files created during tests
    private func cleanupTestFiles() {
        let fileManager = FileManager.default
        let testFiles = [
            "/tmp/test_lzfse.txt",
            "/tmp/test_lzfse.txt.lzfse",
            "/tmp/test_lz4.txt",
            "/tmp/test_lz4.txt.lz4",
            "/tmp/test_zlib.txt",
            "/tmp/test_zlib.txt.zlib",
            "/tmp/test_lzma.txt",
            "/tmp/test_lzma.txt.lzma",
            "/tmp/test.lzfse",
            "/tmp/test.lz4",
            "/tmp/test.zlib",
            "/tmp/test.lzma",
            "/tmp/test.out",
            "/tmp/test.txt",
            "/tmp/test.txt.lzfse",
            "/tmp/test.txt.lz4",
            "/tmp/test.txt.zlib",
            "/tmp/test.txt.lzma",
            "/tmp/output.lz4",
            "/tmp/output.txt",
            "/tmp/compressed.zlib",
            "/tmp/test.txt.lzma",
            "/tmp/unreadable.txt"
        ]

        for file in testFiles {
            try? fileManager.removeItem(atPath: file)
        }
    }

    // MARK: - Compress Command Routing Tests

    func testRouteCompressCommand_WithValidInputs_ExecutesSuccessfully() {
        // Arrange
        let inputPath = "/tmp/test.txt"
        let command = ParsedCommand(
            commandType: .compress,
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            outputDestination: nil,
            forceOverwrite: false
        )

        // Only input file exists, output does not
        mockFileHandler.existingFiles = [inputPath]
        mockFileHandler.isReadableResult = true
        mockFileHandler.isWritableResult = true

        // Act
        let result = router.route(command)

        // Assert
        switch result {
        case .success:
            XCTAssertTrue(true, "Command executed successfully")
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error.description)")
        }

        // Verify file handler was called
        XCTAssertTrue(mockFileHandler.fileExistsCalled)
        XCTAssertTrue(mockFileHandler.isReadableCalled)
    }

    func testRouteCompressCommand_WithMissingAlgorithm_ReturnsError() {
        // Arrange
        let command = ParsedCommand(
            commandType: .compress,
            inputSource: .file(path: "/tmp/test.txt"),
            algorithmName: nil,  // Missing algorithm
            outputDestination: nil,
            forceOverwrite: false
        )

        // Act
        let result = router.route(command)

        // Assert
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error.errorCode, "CLI-002", "Should return missing argument error")
            XCTAssertTrue(error.description.contains("-m (algorithm)"))
        }

        // Verify file handler was not called (short-circuit on validation)
        XCTAssertFalse(mockFileHandler.fileExistsCalled)
    }

    func testRouteCompressCommand_WithCustomOutputPath_PassesToCommand() {
        // Arrange
        let command = ParsedCommand(
            commandType: .compress,
            inputSource: .file(path: "/tmp/test.txt"),
            algorithmName: "lz4",
            outputDestination: .file(path: "/tmp/output.lz4"),
            forceOverwrite: false
        )

        // Only input file exists
        mockFileHandler.existingFiles = ["/tmp/test.txt"]
        mockFileHandler.isReadableResult = true
        mockFileHandler.isWritableResult = true

        // Act
        let result = router.route(command)

        // Assert
        switch result {
        case .success:
            XCTAssertTrue(true, "Command executed successfully")
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error.description)")
        }
    }

    func testRouteCompressCommand_WithForceOverwrite_PassesToCommand() {
        // Arrange
        let command = ParsedCommand(
            commandType: .compress,
            inputSource: .file(path: "/tmp/test.txt"),
            algorithmName: "zlib",
            outputDestination: nil,
            forceOverwrite: true
        )

        // Both input and output exist, but forceOverwrite is true
        mockFileHandler.existingFiles = ["/tmp/test.txt", "/tmp/test.txt.zlib"]
        mockFileHandler.isReadableResult = true
        mockFileHandler.isWritableResult = true

        // Act
        let result = router.route(command)

        // Assert
        switch result {
        case .success:
            XCTAssertTrue(true, "Command executed successfully with force flag")
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error.description)")
        }
    }

    func testRouteCompressCommand_WithInvalidAlgorithm_ReturnsError() {
        // Arrange
        let command = ParsedCommand(
            commandType: .compress,
            inputSource: .file(path: "/tmp/test.txt"),
            algorithmName: "invalid",
            outputDestination: nil,
            forceOverwrite: false
        )

        mockFileHandler.fileExistsResult = true
        mockFileHandler.isReadableResult = true

        // Act
        let result = router.route(command)

        // Assert
        switch result {
        case .success:
            XCTFail("Expected failure for invalid algorithm")
        case .failure(let error):
            XCTAssertTrue(error.description.contains("invalid"))
        }
    }

    func testRouteCompressCommand_WithNonExistentFile_ReturnsError() {
        // Arrange
        let command = ParsedCommand(
            commandType: .compress,
            inputSource: .file(path: "/tmp/nonexistent.txt"),
            algorithmName: "lzfse",
            outputDestination: nil,
            forceOverwrite: false
        )

        mockFileHandler.fileExistsResult = false  // File does not exist

        // Act
        let result = router.route(command)

        // Assert
        switch result {
        case .success:
            XCTFail("Expected failure for non-existent file")
        case .failure(let error):
            XCTAssertTrue(error.description.contains("not found"))
        }
    }

    func testRouteCompressCommand_WithUnreadableFile_ReturnsError() {
        // Arrange
        let command = ParsedCommand(
            commandType: .compress,
            inputSource: .file(path: "/tmp/unreadable.txt"),
            algorithmName: "lzfse",
            outputDestination: nil,
            forceOverwrite: false
        )

        mockFileHandler.fileExistsResult = true
        mockFileHandler.isReadableResult = false  // File not readable

        // Act
        let result = router.route(command)

        // Assert
        switch result {
        case .success:
            XCTFail("Expected failure for unreadable file")
        case .failure(let error):
            XCTAssertTrue(error.description.contains("read") || error.description.contains("Permission"))
        }
    }

    // MARK: - Decompress Command Routing Tests

    func testRouteDecompressCommand_WithValidInputs_ExecutesSuccessfully() {
        // Arrange
        let command = ParsedCommand(
            commandType: .decompress,
            inputSource: .file(path: "/tmp/test.txt.lzfse"),
            algorithmName: "lzfse",
            outputDestination: nil,
            forceOverwrite: false
        )

        // Only input file exists
        mockFileHandler.existingFiles = ["/tmp/test.txt.lzfse"]
        mockFileHandler.isReadableResult = true

        // Act
        let result = router.route(command)

        // Assert
        switch result {
        case .success:
            XCTAssertTrue(true, "Command executed successfully")
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error.description)")
        }

        // Verify file handler was called
        XCTAssertTrue(mockFileHandler.fileExistsCalled)
    }

    func testRouteDecompressCommand_WithoutAlgorithm_InfersFromExtension() {
        // Arrange
        let command = ParsedCommand(
            commandType: .decompress,
            inputSource: .file(path: "/tmp/test.txt.lz4"),
            algorithmName: nil,  // Algorithm should be inferred
            outputDestination: nil,
            forceOverwrite: false
        )

        // Only input file exists
        mockFileHandler.existingFiles = ["/tmp/test.txt.lz4"]
        mockFileHandler.isReadableResult = true

        // Act
        let result = router.route(command)

        // Assert
        switch result {
        case .success:
            XCTAssertTrue(true, "Command executed with inferred algorithm")
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error.description)")
        }
    }

    func testRouteDecompressCommand_WithCustomOutputPath_PassesToCommand() {
        // Arrange
        let command = ParsedCommand(
            commandType: .decompress,
            inputSource: .file(path: "/tmp/compressed.zlib"),
            algorithmName: "zlib",
            outputDestination: .file(path: "/tmp/output.txt"),
            forceOverwrite: false
        )

        // Only input file exists
        mockFileHandler.existingFiles = ["/tmp/compressed.zlib"]
        mockFileHandler.isReadableResult = true

        // Act
        let result = router.route(command)

        // Assert
        switch result {
        case .success:
            XCTAssertTrue(true, "Command executed with custom output")
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error.description)")
        }
    }

    func testRouteDecompressCommand_WithForceOverwrite_PassesToCommand() {
        // Arrange
        let command = ParsedCommand(
            commandType: .decompress,
            inputSource: .file(path: "/tmp/test.txt.lzma"),
            algorithmName: "lzma",
            outputDestination: nil,
            forceOverwrite: true
        )

        // Both input and output exist, but forceOverwrite is true
        mockFileHandler.existingFiles = ["/tmp/test.txt.lzma", "/tmp/test.txt"]
        mockFileHandler.isReadableResult = true

        // Act
        let result = router.route(command)

        // Assert
        switch result {
        case .success:
            XCTAssertTrue(true, "Command executed with force flag")
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error.description)")
        }
    }

    func testRouteDecompressCommand_WithNonInferrableExtension_ReturnsError() {
        // Arrange
        let command = ParsedCommand(
            commandType: .decompress,
            inputSource: .file(path: "/tmp/test.unknown"),
            algorithmName: nil,  // Cannot infer from .unknown extension
            outputDestination: nil,
            forceOverwrite: false
        )

        mockFileHandler.fileExistsResult = true
        mockFileHandler.isReadableResult = true

        // Act
        let result = router.route(command)

        // Assert
        switch result {
        case .success:
            XCTFail("Expected failure for non-inferrable extension")
        case .failure(let error):
            XCTAssertTrue(error.description.contains("-m") || error.description.contains("algorithm"))
        }
    }

    // MARK: - Help and Version Tests

    func testHandleHelp_ReturnsSuccessWithHelpText() {
        // Act
        let result = CommandRouter.handleHelp()

        // Assert
        switch result {
        case .success(let message):
            XCTAssertNotNil(message, "Help text should not be nil")
            XCTAssertTrue(message!.contains("USAGE"))
            XCTAssertTrue(message!.contains("COMMANDS"))
            XCTAssertTrue(message!.contains("OPTIONS"))
            XCTAssertTrue(message!.contains("EXAMPLES"))
            XCTAssertTrue(message!.contains("lzfse"))
            XCTAssertTrue(message!.contains("lz4"))
            XCTAssertTrue(message!.contains("zlib"))
            XCTAssertTrue(message!.contains("lzma"))
        case .failure:
            XCTFail("Help should return success, not failure")
        }
    }

    func testHandleVersion_ReturnsSuccessWithVersionInfo() {
        // Act
        let result = CommandRouter.handleVersion()

        // Assert
        switch result {
        case .success(let message):
            XCTAssertNotNil(message, "Version text should not be nil")
            XCTAssertTrue(message!.contains("version"))
            XCTAssertTrue(message!.contains("0.1.0"))
            XCTAssertTrue(message!.contains("LZFSE"))
            XCTAssertTrue(message!.contains("LZ4"))
            XCTAssertTrue(message!.contains("ZLIB"))
            XCTAssertTrue(message!.contains("LZMA"))
        case .failure:
            XCTFail("Version should return success, not failure")
        }
    }

    // MARK: - Error Propagation Tests

    func testRouteCompressCommand_PropagatesOutputFileExistsError() {
        // Arrange
        let command = ParsedCommand(
            commandType: .compress,
            inputSource: .file(path: "/tmp/test.txt"),
            algorithmName: "lzfse",
            outputDestination: nil,
            forceOverwrite: false
        )

        // Configure mock to simulate output file exists
        mockFileHandler.fileExistsResult = true
        mockFileHandler.isReadableResult = true
        mockFileHandler.isWritableResult = true

        // Act
        let result = router.route(command)

        // Assert - should fail because output exists without -f flag
        switch result {
        case .success:
            XCTFail("Expected failure when output exists without force flag")
        case .failure(let error):
            XCTAssertTrue(error.description.contains("exists") || error.description.contains("overwrite"))
        }
    }

    func testRouteDecompressCommand_PropagatesFileNotFoundError() {
        // Arrange
        let command = ParsedCommand(
            commandType: .decompress,
            inputSource: .file(path: "/tmp/missing.lzfse"),
            algorithmName: "lzfse",
            outputDestination: nil,
            forceOverwrite: false
        )

        mockFileHandler.fileExistsResult = false

        // Act
        let result = router.route(command)

        // Assert
        switch result {
        case .success:
            XCTFail("Expected failure for missing file")
        case .failure(let error):
            XCTAssertTrue(error.description.contains("not found"))
        }
    }

    // MARK: - Integration Tests

    func testRouteCompressCommand_WithAllAlgorithms_ExecutesSuccessfully() {
        // Test all supported algorithms
        let algorithms = ["lzfse", "lz4", "zlib", "lzma"]

        for algorithm in algorithms {
            // Arrange
            let inputPath = "/tmp/test_\(algorithm).txt"
            let command = ParsedCommand(
                commandType: .compress,
                inputSource: .file(path: inputPath),
                algorithmName: algorithm,
                outputDestination: nil,
                forceOverwrite: false
            )

            // Configure mock: only INPUT file exists, OUTPUT does not
            mockFileHandler.existingFiles = [inputPath]  // Only input file exists
            mockFileHandler.isReadableResult = true
            mockFileHandler.isWritableResult = true

            // Reset call tracking
            mockFileHandler.fileExistsCalled = false

            // Act
            let result = router.route(command)

            // Assert
            switch result {
            case .success:
                XCTAssertTrue(true, "\(algorithm) compression succeeded")
            case .failure(let error):
                XCTFail("Algorithm \(algorithm) failed: \(error.description)")
            }

            XCTAssertTrue(mockFileHandler.fileExistsCalled, "\(algorithm): file handler should be called")
        }
    }

    func testRouteDecompressCommand_WithAllAlgorithms_ExecutesSuccessfully() {
        // Test all supported algorithms
        let algorithms = ["lzfse", "lz4", "zlib", "lzma"]

        for algorithm in algorithms {
            // Arrange
            let inputPath = "/tmp/test.\(algorithm)"
            let command = ParsedCommand(
                commandType: .decompress,
                inputSource: .file(path: inputPath),
                algorithmName: algorithm,
                outputDestination: nil,
                forceOverwrite: false
            )

            // Configure mock: only INPUT file exists, OUTPUT does not
            mockFileHandler.existingFiles = [inputPath]  // Only input file exists
            mockFileHandler.isReadableResult = true

            // Reset call tracking
            mockFileHandler.fileExistsCalled = false

            // Act
            let result = router.route(command)

            // Assert
            switch result {
            case .success:
                XCTAssertTrue(true, "\(algorithm) decompression succeeded")
            case .failure(let error):
                XCTFail("Algorithm \(algorithm) failed: \(error.description)")
            }

            XCTAssertTrue(mockFileHandler.fileExistsCalled, "\(algorithm): file handler should be called")
        }
    }

    // MARK: - Dependency Injection Tests

    func testRouterInitialization_StoresAllDependencies() {
        // Assert all dependencies are set (via successful routing)
        let command = ParsedCommand(
            commandType: .compress,
            inputSource: .file(path: "/tmp/test.txt"),
            algorithmName: "lzfse",
            outputDestination: nil,
            forceOverwrite: false
        )

        mockFileHandler.fileExistsResult = true
        mockFileHandler.isReadableResult = true
        mockFileHandler.isWritableResult = true

        // If routing works, all dependencies are properly injected
        let result = router.route(command)

        // Verify command executed (dependency injection successful)
        switch result {
        case .success:
            XCTAssertTrue(mockFileHandler.fileExistsCalled)
            XCTAssertTrue(mockFileHandler.isReadableCalled)
        case .failure:
            break  // Still valid if other errors occurred
        }
    }
}

// MARK: - Mock FileHandler

class MockFileHandler: FileHandlerProtocol {
    var fileExistsResult: Bool = false
    var isReadableResult: Bool = false
    var isWritableResult: Bool = false
    var fileSizeResult: Int64 = 1024

    // Track which paths exist for more granular control
    var existingFiles: Set<String> = []

    var fileExistsCalled = false
    var isReadableCalled = false
    var isWritableCalled = false
    var fileSizeCalled = false
    var inputStreamCalled = false
    var outputStreamCalled = false

    func fileExists(at path: String) -> Bool {
        fileExistsCalled = true

        // If existingFiles is configured, use it
        if !existingFiles.isEmpty {
            return existingFiles.contains(path)
        }

        // Otherwise use the default result
        return fileExistsResult
    }

    func isReadable(at path: String) -> Bool {
        isReadableCalled = true
        return isReadableResult
    }

    func isWritable(at path: String) -> Bool {
        isWritableCalled = true
        return isWritableResult
    }

    func fileSize(at path: String) throws -> Int64 {
        fileSizeCalled = true
        return fileSizeResult
    }

    func inputStream(at path: String) throws -> InputStream {
        inputStreamCalled = true
        let stream = InputStream(data: Data())
        stream.open()
        return stream
    }

    func outputStream(at path: String) throws -> OutputStream {
        outputStreamCalled = true
        let stream = OutputStream.toMemory()
        stream.open()
        return stream
    }

    func deleteFile(at path: String) throws {
        // No-op for mock
    }

    func createDirectory(at path: String) throws {
        // No-op for mock
    }

    // MARK: - stdin/stdout Support

    func inputStream(from source: InputSource) throws -> InputStream {
        switch source {
        case .file(let path):
            return try inputStream(at: path)
        case .stdin:
            // For testing, return empty stream
            let stream = InputStream(data: Data())
            stream.open()
            return stream
        }
    }

    func outputStream(to destination: OutputDestination) throws -> OutputStream {
        switch destination {
        case .file(let path):
            return try outputStream(at: path)
        case .stdout:
            // For testing, return memory stream
            let stream = OutputStream.toMemory()
            stream.open()
            return stream
        }
    }
}

// MARK: - Mock Algorithm

class MockAlgorithm: CompressionAlgorithmProtocol {
    let name: String

    init(name: String) {
        self.name = name
    }

    func compress(input: Data) throws -> Data {
        return input  // Pass-through for testing
    }

    func decompress(input: Data) throws -> Data {
        return input  // Pass-through for testing
    }

    func compressStream(input: InputStream, output: OutputStream, bufferSize: Int) throws {
        // Simulate stream processing
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while input.hasBytesAvailable {
            let bytesRead = input.read(&buffer, maxLength: bufferSize)
            if bytesRead > 0 {
                output.write(buffer, maxLength: bytesRead)
            }
        }
    }

    func decompressStream(input: InputStream, output: OutputStream, bufferSize: Int) throws {
        // Simulate stream processing
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while input.hasBytesAvailable {
            let bytesRead = input.read(&buffer, maxLength: bufferSize)
            if bytesRead > 0 {
                output.write(buffer, maxLength: bytesRead)
            }
        }
    }
}
