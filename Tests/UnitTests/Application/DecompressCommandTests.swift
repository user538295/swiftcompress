import XCTest
@testable import swiftcompress

/// Comprehensive unit tests for DecompressCommand
/// Tests all workflow steps, validation, error handling, and edge cases
final class DecompressCommandTests: XCTestCase {

    // MARK: - Test Fixtures

    private var mockFileHandler: DecompressMockFileHandler!
    private var pathResolver: FilePathResolver!
    private var validationRules: ValidationRules!
    private var algorithmRegistry: AlgorithmRegistry!
    private var mockAlgorithm: DecompressMockAlgorithm!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockFileHandler = DecompressMockFileHandler()
        pathResolver = FilePathResolver()
        validationRules = ValidationRules()
        algorithmRegistry = AlgorithmRegistry()

        // Register mock algorithm
        mockAlgorithm = DecompressMockAlgorithm(name: "lzfse")
        algorithmRegistry.register(mockAlgorithm)
    }

    override func tearDown() {
        mockFileHandler = nil
        pathResolver = nil
        validationRules = nil
        algorithmRegistry = nil
        mockAlgorithm = nil
        super.tearDown()
    }

    // MARK: - Successful Decompression Tests

    func testExecute_SuccessfulDecompression_WithExplicitAlgorithm() throws {
        // Arrange
        let inputPath = "/tmp/test.txt.lzfse"
        let outputPath = "/tmp/test.txt"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            outputPath: false,
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            outputDestination: .file(path: outputPath),
            forceOverwrite: false,
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert - should not throw
        XCTAssertNoThrow(try command.execute())

        // Verify streams were created
        XCTAssertEqual(mockFileHandler.inputStreamPaths.count, 1)
        XCTAssertEqual(mockFileHandler.inputStreamPaths.first, inputPath)
        XCTAssertEqual(mockFileHandler.outputStreamPaths.count, 1)
        XCTAssertEqual(mockFileHandler.outputStreamPaths.first, outputPath)
    }

    func testExecute_SuccessfulDecompression_WithInferredAlgorithm() throws {
        // Arrange
        let inputPath = "/tmp/file.txt.lz4"

        // Register lz4 algorithm
        let lz4Algorithm = DecompressMockAlgorithm(name: "lz4")
        algorithmRegistry.register(lz4Algorithm)

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            "/tmp/file.txt": false,
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: nil,  // Should be inferred
            outputDestination: nil,
            forceOverwrite: false,
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertNoThrow(try command.execute())

        // Verify correct output path was used
        XCTAssertEqual(mockFileHandler.outputStreamPaths.first, "/tmp/file.txt")
    }

    func testExecute_SuccessfulDecompression_WithDefaultOutputPath() throws {
        // Arrange
        let inputPath = "/tmp/archive.zlib"

        // Register zlib algorithm
        let zlibAlgorithm = DecompressMockAlgorithm(name: "zlib")
        algorithmRegistry.register(zlibAlgorithm)

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            "/tmp/archive": false,
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "zlib",
            outputDestination: nil,  // Should use default
            forceOverwrite: false,
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertNoThrow(try command.execute())

        // Verify default output path (stripped extension)
        XCTAssertEqual(mockFileHandler.outputStreamPaths.first, "/tmp/archive")
    }

    func testExecute_SuccessfulDecompression_WithForceOverwrite() throws {
        // Arrange
        let inputPath = "/tmp/test.lzma"
        let outputPath = "/tmp/test"

        // Register lzma algorithm
        let lzmaAlgorithm = DecompressMockAlgorithm(name: "lzma")
        algorithmRegistry.register(lzmaAlgorithm)

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            outputPath: true,  // Already exists
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzma",
            outputDestination: .file(path: outputPath),
            forceOverwrite: true,  // Force overwrite
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertNoThrow(try command.execute())
    }

    func testExecute_AddsOutSuffix_WhenDefaultOutputExists() throws {
        // Arrange
        let inputPath = "/tmp/data.txt.lzfse"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            "/tmp/data.txt": true,  // Original exists
            "/tmp/data.txt.out": false,  // But .out doesn't
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            outputDestination: nil,
            forceOverwrite: false,
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act
        XCTAssertNoThrow(try command.execute())

        // Assert - should use .out suffix
        XCTAssertEqual(mockFileHandler.outputStreamPaths.first, "/tmp/data.txt.out")
    }

    // MARK: - Validation Failure Tests

    func testExecute_ThrowsError_WhenInputPathEmpty() {
        // Arrange
        let command = DecompressCommand(
            inputSource: .file(path: ""),
            algorithmName: "lzfse",
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertThrowsError(try command.execute()) { error in
            XCTAssertTrue(error is DomainError)
            if case DomainError.invalidInputPath(let path, _) = error {
                XCTAssertEqual(path, "")
            } else {
                XCTFail("Expected invalidInputPath error")
            }
        }
    }

    func testExecute_ThrowsError_WhenInputPathContainsNullBytes() {
        // Arrange
        let command = DecompressCommand(
            inputSource: .file(path: "/tmp/file\0.txt"),
            algorithmName: "lzfse",
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertThrowsError(try command.execute()) { error in
            XCTAssertTrue(error is DomainError)
        }
    }

    func testExecute_ThrowsError_WhenPathTraversalAttempt() {
        // Arrange
        // Use a relative path with .. that doesn't normalize away
        let command = DecompressCommand(
            inputSource: .file(path: "../etc/passwd"),
            algorithmName: "lzfse",
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertThrowsError(try command.execute()) { error in
            XCTAssertTrue(error is DomainError)
            if case DomainError.pathTraversalAttempt = error {
                // Expected
            } else {
                XCTFail("Expected pathTraversalAttempt error, got: \(error)")
            }
        }
    }

    // MARK: - File Not Found Tests

    func testExecute_ThrowsError_WhenInputFileNotFound() {
        // Arrange
        let inputPath = "/tmp/nonexistent.lzfse"

        mockFileHandler.fileExistsResults = [inputPath: false]

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertThrowsError(try command.execute()) { error in
            XCTAssertTrue(error is InfrastructureError)
            if case InfrastructureError.fileNotFound(let path) = error {
                XCTAssertEqual(path, inputPath)
            } else {
                XCTFail("Expected fileNotFound error")
            }
        }
    }

    func testExecute_ThrowsError_WhenInputFileNotReadable() {
        // Arrange
        let inputPath = "/tmp/nopermission.lzfse"

        mockFileHandler.fileExistsResults = [inputPath: true]
        mockFileHandler.isReadableResults = [inputPath: false]

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertThrowsError(try command.execute()) { error in
            XCTAssertTrue(error is InfrastructureError)
            if case InfrastructureError.fileNotReadable(let path, _) = error {
                XCTAssertEqual(path, inputPath)
            } else {
                XCTFail("Expected fileNotReadable error")
            }
        }
    }

    // MARK: - Algorithm Tests

    func testExecute_ThrowsError_WhenAlgorithmCannotBeInferred() {
        // Arrange
        let inputPath = "/tmp/file.unknown"

        mockFileHandler.fileExistsResults = [inputPath: true]
        mockFileHandler.isReadableResults = [inputPath: true]

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: nil,  // No explicit algorithm
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertThrowsError(try command.execute()) { error in
            XCTAssertTrue(error is DomainError)
            if case DomainError.algorithmCannotBeInferred(let path, let ext, let supported) = error {
                XCTAssertEqual(path, inputPath)
                XCTAssertEqual(ext, "unknown")
                XCTAssertTrue(supported.contains("lzfse"))  // Registry has lzfse registered
            } else {
                XCTFail("Expected algorithmCannotBeInferred error")
            }
        }
    }

    func testExecute_ThrowsError_WhenAlgorithmNotSupported() {
        // Arrange
        let inputPath = "/tmp/test.lzfse"

        mockFileHandler.fileExistsResults = [inputPath: true]
        mockFileHandler.isReadableResults = [inputPath: true]

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "unsupported",
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertThrowsError(try command.execute()) { error in
            XCTAssertTrue(error is DomainError)
            if case DomainError.invalidAlgorithmName(let name, _) = error {
                XCTAssertEqual(name, "unsupported")
            } else {
                XCTFail("Expected invalidAlgorithmName error")
            }
        }
    }

    func testExecute_ThrowsError_WhenAlgorithmNotRegistered() {
        // Arrange
        let inputPath = "/tmp/test.lz4"

        mockFileHandler.fileExistsResults = [inputPath: true]
        mockFileHandler.isReadableResults = [inputPath: true]

        // Clear registry
        algorithmRegistry = AlgorithmRegistry()

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lz4",
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertThrowsError(try command.execute()) { error in
            XCTAssertTrue(error is DomainError)
        }
    }

    func testExecute_UsesExplicitAlgorithm_EvenWhenInferenceWouldDiffer() throws {
        // Arrange
        let inputPath = "/tmp/file.lzfse"  // Extension suggests lzfse

        // Register both algorithms
        let lz4Algorithm = DecompressMockAlgorithm(name: "lz4")
        algorithmRegistry.register(lz4Algorithm)

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            "/tmp/file": false,
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lz4",  // Explicit override
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertNoThrow(try command.execute())
        // Should use lz4, not lzfse from extension
    }

    // MARK: - Output File Overwrite Tests

    func testExecute_ThrowsError_WhenOutputFileExists_WithoutForceFlag() {
        // Arrange
        let inputPath = "/tmp/test.lzfse"
        let outputPath = "/tmp/test"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            outputPath: true,  // Output exists
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            outputDestination: .file(path: outputPath),
            forceOverwrite: false,  // No force
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertThrowsError(try command.execute()) { error in
            XCTAssertTrue(error is DomainError)
            if case DomainError.outputFileExists(let path) = error {
                XCTAssertEqual(path, outputPath)
            } else {
                XCTFail("Expected outputFileExists error")
            }
        }
    }

    func testExecute_ThrowsError_WhenInputAndOutputSame() {
        // Arrange
        let path = "/tmp/test.txt"

        mockFileHandler.fileExistsResults = [
            path: true,
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [path: true]

        let command = DecompressCommand(
            inputSource: .file(path: path),
            algorithmName: "lzfse",
            outputDestination: .file(path: path),  // Same as input
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertThrowsError(try command.execute()) { error in
            XCTAssertTrue(error is DomainError)
            if case DomainError.inputOutputSame = error {
                // Expected
            } else {
                XCTFail("Expected inputOutputSame error")
            }
        }
    }

    // MARK: - Directory Creation Tests

    func testExecute_CreatesOutputDirectory_WhenNotExists() throws {
        // Arrange
        let inputPath = "/tmp/test.lzfse"
        let outputPath = "/tmp/subdir/test"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            outputPath: false,
            "/tmp/subdir": false,  // Directory doesn't exist
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            outputDestination: .file(path: outputPath),
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act
        XCTAssertNoThrow(try command.execute())

        // Assert - directory creation was attempted
        XCTAssertTrue(mockFileHandler.createDirectoryPaths.contains("/tmp/subdir"))
    }

    // MARK: - Decompression Failure Tests

    func testExecute_ThrowsError_WhenDecompressionFails() {
        // Arrange
        let inputPath = "/tmp/corrupted.lzfse"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            "/tmp/corrupted": false,
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]

        // Configure algorithm to fail
        mockAlgorithm.decompressStreamError = InfrastructureError.corruptedData(algorithm: "lzfse")

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertThrowsError(try command.execute()) { error in
            XCTAssertTrue(error is InfrastructureError)
        }
    }

    func testExecute_CleansUpPartialOutput_OnDecompressionFailure() {
        // Arrange
        let inputPath = "/tmp/test.lzfse"
        let outputPath = "/tmp/test"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            outputPath: false,
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]

        // Configure algorithm to fail
        mockAlgorithm.decompressStreamError = InfrastructureError.decompressionFailed(
            algorithm: "lzfse",
            reason: "Test failure"
        )

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            outputDestination: .file(path: outputPath),
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act
        XCTAssertThrowsError(try command.execute())

        // Assert - cleanup was attempted
        XCTAssertTrue(mockFileHandler.deleteFilePaths.contains(outputPath))
    }

    // MARK: - Stream Creation Failure Tests

    func testExecute_ThrowsError_WhenInputStreamCreationFails() {
        // Arrange
        let inputPath = "/tmp/test.lzfse"

        mockFileHandler.fileExistsResults = [inputPath: true]
        mockFileHandler.isReadableResults = [inputPath: true]
        mockFileHandler.inputStreamError = InfrastructureError.streamCreationFailed(path: inputPath)

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertThrowsError(try command.execute()) { error in
            XCTAssertTrue(error is InfrastructureError)
            if case InfrastructureError.streamCreationFailed = error {
                // Expected
            } else {
                XCTFail("Expected streamCreationFailed error")
            }
        }
    }

    func testExecute_ThrowsError_WhenOutputStreamCreationFails() {
        // Arrange
        let inputPath = "/tmp/test.lzfse"
        let outputPath = "/tmp/test"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            outputPath: false,
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]
        mockFileHandler.outputStreamError = InfrastructureError.streamCreationFailed(path: outputPath)

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            outputDestination: .file(path: outputPath),
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertThrowsError(try command.execute()) { error in
            XCTAssertTrue(error is InfrastructureError)
        }
    }

    // MARK: - Edge Case Tests

    func testExecute_HandlesFileWithoutExtension() throws {
        // Arrange
        let inputPath = "/tmp/compressed_data"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            "/tmp/decompressed": false,  // Output path
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",  // Must be explicit
            outputDestination: .file(path: "/tmp/decompressed"),
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertNoThrow(try command.execute())
    }

    func testExecute_HandlesFileWithMultipleDots() throws {
        // Arrange
        let inputPath = "/tmp/archive.backup.tar.lzfse"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            "/tmp/archive.backup.tar": false,
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act
        XCTAssertNoThrow(try command.execute())

        // Assert - correct output path
        XCTAssertEqual(mockFileHandler.outputStreamPaths.first, "/tmp/archive.backup.tar")
    }

    func testExecute_HandlesCaseInsensitiveAlgorithmNames() throws {
        // Arrange
        let inputPath = "/tmp/test.lzfse"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            "/tmp/test": false,
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]

        let command = DecompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "LZFSE",  // Uppercase
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert - should work (case-insensitive)
        XCTAssertNoThrow(try command.execute())
    }
}

// MARK: - Mock FileHandler

private class DecompressMockFileHandler: FileHandlerProtocol {
    var fileExistsResults: [String: Bool] = [:]
    var isReadableResults: [String: Bool] = [:]
    var isWritableResults: [String: Bool] = [:]

    var inputStreamPaths: [String] = []
    var outputStreamPaths: [String] = []
    var deleteFilePaths: [String] = []
    var createDirectoryPaths: [String] = []

    var inputStreamError: Error?
    var outputStreamError: Error?

    func fileExists(at path: String) -> Bool {
        return fileExistsResults[path] ?? false
    }

    func isReadable(at path: String) -> Bool {
        return isReadableResults[path] ?? false
    }

    func isWritable(at path: String) -> Bool {
        return isWritableResults[path] ?? false
    }

    func fileSize(at path: String) throws -> Int64 {
        return 1024
    }

    func inputStream(at path: String) throws -> InputStream {
        inputStreamPaths.append(path)
        if let error = inputStreamError {
            throw error
        }
        // Return a valid stream for testing
        return InputStream(data: Data())
    }

    func outputStream(at path: String) throws -> OutputStream {
        outputStreamPaths.append(path)
        if let error = outputStreamError {
            throw error
        }
        // Return a valid stream for testing
        return OutputStream(toMemory: ())
    }

    func deleteFile(at path: String) throws {
        deleteFilePaths.append(path)
    }

    func createDirectory(at path: String) throws {
        createDirectoryPaths.append(path)
    }

    // MARK: - stdin/stdout Support

    func inputStream(from source: InputSource) throws -> InputStream {
        switch source {
        case .file(let path):
            return try inputStream(at: path)
        case .stdin:
            // For testing, return empty stream
            return InputStream(data: Data())
        }
    }

    func outputStream(to destination: OutputDestination) throws -> OutputStream {
        switch destination {
        case .file(let path):
            return try outputStream(at: path)
        case .stdout:
            // For testing, return memory stream
            return OutputStream(toMemory: ())
        }
    }
}

// MARK: - Mock Algorithm with Stream Support

private class DecompressMockAlgorithm: CompressionAlgorithmProtocol {
    let name: String
    var decompressStreamError: Error?

    init(name: String) {
        self.name = name
    }

    func compress(input: Data) throws -> Data {
        return Data()
    }

    func decompress(input: Data) throws -> Data {
        return input
    }

    func compressStream(input: InputStream, output: OutputStream, bufferSize: Int) throws {
        // Not used in decompress tests
    }

    func decompressStream(input: InputStream, output: OutputStream, bufferSize: Int) throws {
        if let error = decompressStreamError {
            throw error
        }
        // Success - do nothing
    }
}
