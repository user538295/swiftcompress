import XCTest
@testable import swiftcompress
import TestHelpers

/// Comprehensive unit tests for CompressCommand
/// Tests all workflow steps, validation, error handling, and edge cases
final class CompressCommandTests: XCTestCase {

    // MARK: - Test Fixtures

    private var mockFileHandler: MockFileHandler!
    private var pathResolver: FilePathResolver!
    private var validationRules: ValidationRules!
    private var algorithmRegistry: AlgorithmRegistry!
    private var mockAlgorithm: MockCompressionAlgorithm!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockFileHandler = MockFileHandler()
        pathResolver = FilePathResolver()
        validationRules = ValidationRules()
        algorithmRegistry = AlgorithmRegistry()

        // Register mock algorithm
        mockAlgorithm = MockCompressionAlgorithm(name: "lzfse")
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

    // MARK: - Successful Compression Tests

    func testExecute_SuccessfulCompression_WithExplicitOutputPath() throws {
        // Arrange
        let inputPath = "/tmp/test.txt"
        let outputPath = "/tmp/test.txt.lzfse"

        mockFileHandler.fileExistsResults = [
            inputPath: true,       // Input exists
            outputPath: false,     // Output doesn't exist
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]
        mockFileHandler.isWritableResults = ["/tmp": true]

        let command = CompressCommand(
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

        // Verify algorithm was called
        XCTAssertTrue(mockAlgorithm.compressStreamCalled)
        XCTAssertEqual(mockAlgorithm.lastBufferSize, 65536)  // 64KB buffer
    }

    func testExecute_SuccessfulCompression_WithDefaultOutputPath() throws {
        // Arrange
        let inputPath = "/tmp/file.txt"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            "/tmp/file.txt.lzfse": false,  // Default output
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]
        mockFileHandler.isWritableResults = ["/tmp": true]

        let command = CompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            outputDestination: nil,  // Use default
            forceOverwrite: false,
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertNoThrow(try command.execute())

        // Verify default output path was used
        XCTAssertEqual(mockFileHandler.outputStreamPaths.first, "/tmp/file.txt.lzfse")
    }

    func testExecute_SuccessfulCompression_WithForceOverwrite() throws {
        // Arrange
        let inputPath = "/tmp/test.txt"
        let outputPath = "/tmp/test.txt.lzfse"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            outputPath: true,  // Output exists but force=true
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]
        mockFileHandler.isWritableResults = ["/tmp": true]

        let command = CompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            outputDestination: .file(path: outputPath),
            forceOverwrite: true,  // Force overwrite
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertNoThrow(try command.execute())

        // Verify compression proceeded despite existing output
        XCTAssertTrue(mockAlgorithm.compressStreamCalled)
    }

    // MARK: - Input Validation Tests

    func testExecute_ThrowsError_WhenInputPathEmpty() {
        // Arrange
        let command = CompressCommand(
            inputSource: .file(path: ""),  // Empty path
            algorithmName: "lzfse",
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertThrowsError(try command.execute()) { error in
            XCTAssertTrue(error is DomainError)
            if case DomainError.invalidInputPath(let path, let reason) = error {
                XCTAssertEqual(path, "")
                XCTAssertTrue(reason.contains("empty"))
            } else {
                XCTFail("Expected invalidInputPath error")
            }
        }
    }

    func testExecute_ThrowsError_WhenInputPathContainsNullByte() {
        // Arrange
        let command = CompressCommand(
            inputSource: .file(path: "/path/with\0null"),
            algorithmName: "lzfse",
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertThrowsError(try command.execute()) { error in
            XCTAssertTrue(error is DomainError)
            if case DomainError.invalidInputPath = error {
                // Expected
            } else {
                XCTFail("Expected invalidInputPath error")
            }
        }
    }

    func testExecute_ThrowsError_WhenPathTraversalAttempt() {
        // Arrange
        // Use a relative path with .. that doesn't normalize away
        let command = CompressCommand(
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

    // MARK: - Algorithm Validation Tests

    func testExecute_ThrowsError_WhenAlgorithmNotSupported() {
        // Arrange
        let inputPath = "/tmp/file.txt"

        // Set up mock so input validation passes, allowing algorithm validation to run
        mockFileHandler.fileExistsResults = [inputPath: true]
        mockFileHandler.isReadableResults = [inputPath: true]

        let command = CompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "invalid_algorithm",  // Unsupported
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act & Assert
        XCTAssertThrowsError(try command.execute()) { error in
            XCTAssertTrue(error is DomainError, "Expected DomainError but got: \(type(of: error))")
            if case DomainError.invalidAlgorithmName(let name, let supported) = error {
                XCTAssertEqual(name, "invalid_algorithm")
                XCTAssertTrue(supported.contains("lzfse"))
            } else {
                XCTFail("Expected invalidAlgorithmName error but got: \(error)")
            }
        }
    }

    func testExecute_ThrowsError_WhenAlgorithmNotRegistered() {
        // Arrange
        let inputPath = "/tmp/file.txt"

        mockFileHandler.fileExistsResults = [inputPath: true]
        mockFileHandler.isReadableResults = [inputPath: true]

        // Clear registry
        algorithmRegistry = AlgorithmRegistry()

        let command = CompressCommand(
            inputSource: .file(path: inputPath),
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

    func testExecute_HandlesCaseInsensitiveAlgorithmNames() throws {
        // Arrange
        let inputPath = "/tmp/file.txt"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            "/tmp/file.txt.lzfse": false,
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]
        mockFileHandler.isWritableResults = ["/tmp": true]

        let command = CompressCommand(
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

    // MARK: - File Existence Tests

    func testExecute_ThrowsError_WhenInputFileNotFound() {
        // Arrange
        let inputPath = "/tmp/missing.txt"

        mockFileHandler.fileExistsResults = [inputPath: false]  // Not found

        let command = CompressCommand(
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

        // Should not attempt compression
        XCTAssertFalse(mockAlgorithm.compressStreamCalled)
    }

    func testExecute_ThrowsError_WhenInputFileNotReadable() {
        // Arrange
        let inputPath = "/tmp/file.txt"

        mockFileHandler.fileExistsResults = [inputPath: true]
        mockFileHandler.isReadableResults = [inputPath: false]  // Not readable

        let command = CompressCommand(
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

    // MARK: - Output File Tests

    func testExecute_ThrowsError_WhenOutputExistsWithoutForceFlag() {
        // Arrange
        let inputPath = "/tmp/file.txt"
        let outputPath = "/tmp/file.txt.lzfse"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            outputPath: true  // Output exists
        ]
        mockFileHandler.isReadableResults = [inputPath: true]

        let command = CompressCommand(
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

        // Should not attempt compression
        XCTAssertFalse(mockAlgorithm.compressStreamCalled)
    }

    func testExecute_ThrowsError_WhenOutputDirectoryNotWritable() {
        // Arrange
        let inputPath = "/tmp/file.txt"
        let outputPath = "/readonly/output/file.txt.lzfse"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            outputPath: false
        ]
        mockFileHandler.isReadableResults = [inputPath: true]
        mockFileHandler.isWritableResults = ["/readonly/output": false]  // Not writable

        let command = CompressCommand(
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
            if case InfrastructureError.directoryNotWritable(let path) = error {
                XCTAssertEqual(path, "/readonly/output")
            } else {
                XCTFail("Expected directoryNotWritable error")
            }
        }
    }

    func testExecute_ThrowsError_WhenInputOutputSame() {
        // Arrange
        let path = "/tmp/file.txt"

        mockFileHandler.fileExistsResults = [path: true]
        mockFileHandler.isReadableResults = [path: true]

        let command = CompressCommand(
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

    // MARK: - Stream Creation Tests

    func testExecute_ThrowsError_WhenInputStreamCreationFails() {
        // Arrange
        let inputPath = "/tmp/file.txt"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            "/tmp/file.txt.lzfse": false,
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]
        mockFileHandler.isWritableResults = ["/tmp": true]
        mockFileHandler.inputStreamError = InfrastructureError.streamCreationFailed(path: inputPath)

        let command = CompressCommand(
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

        // Should not attempt compression
        XCTAssertFalse(mockAlgorithm.compressStreamCalled)
    }

    func testExecute_ThrowsError_WhenOutputStreamCreationFails() {
        // Arrange
        let inputPath = "/tmp/file.txt"
        let outputPath = "/tmp/file.txt.lzfse"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            outputPath: false,
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]
        mockFileHandler.isWritableResults = ["/tmp": true]
        mockFileHandler.outputStreamError = InfrastructureError.streamCreationFailed(path: outputPath)

        let command = CompressCommand(
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

    // MARK: - Compression Failure Tests

    func testExecute_ThrowsError_WhenCompressionFails() {
        // Arrange
        let inputPath = "/tmp/file.txt"
        let outputPath = "/tmp/file.txt.lzfse"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            outputPath: false,
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]
        mockFileHandler.isWritableResults = ["/tmp": true]

        // Configure algorithm to fail
        mockAlgorithm.compressStreamError = InfrastructureError.compressionFailed(
            algorithm: "lzfse",
            reason: "Test failure"
        )

        let command = CompressCommand(
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
            if case InfrastructureError.compressionFailed(let algorithm, _) = error {
                XCTAssertEqual(algorithm, "lzfse")
            } else {
                XCTFail("Expected compressionFailed error")
            }
        }

        // Verify partial output was cleaned up
        XCTAssertTrue(mockFileHandler.deleteFilePaths.contains(outputPath))
    }

    // MARK: - Resource Cleanup Tests

    func testExecute_CleansUpPartialOutput_OnCompressionFailure() {
        // Arrange
        let inputPath = "/tmp/file.txt"
        let outputPath = "/tmp/file.txt.lzfse"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            outputPath: false,
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]
        mockFileHandler.isWritableResults = ["/tmp": true]

        mockAlgorithm.compressStreamError = InfrastructureError.compressionFailed(
            algorithm: "lzfse",
            reason: "Test"
        )

        let command = CompressCommand(
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

        // Assert - partial output should be deleted
        XCTAssertTrue(mockFileHandler.deleteFilePaths.contains(outputPath))
    }

    func testExecute_DoesNotDeleteOutput_OnSuccess() throws {
        // Arrange
        let inputPath = "/tmp/file.txt"
        let outputPath = "/tmp/file.txt.lzfse"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            outputPath: false,
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]
        mockFileHandler.isWritableResults = ["/tmp": true]

        let command = CompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            outputDestination: .file(path: outputPath),
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act
        try command.execute()

        // Assert - output should not be deleted on success
        XCTAssertEqual(mockFileHandler.deleteFilePaths.count, 0)
    }

    // MARK: - Edge Case Tests

    func testExecute_HandlesFileWithMultipleDots() throws {
        // Arrange
        let inputPath = "/tmp/archive.backup.tar.txt"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            "/tmp/archive.backup.tar.txt.lzfse": false,
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]
        mockFileHandler.isWritableResults = ["/tmp": true]

        let command = CompressCommand(
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
        XCTAssertEqual(mockFileHandler.outputStreamPaths.first, "/tmp/archive.backup.tar.txt.lzfse")
    }

    func testExecute_HandlesFileWithoutExtension() throws {
        // Arrange
        let inputPath = "/tmp/datafile"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            "/tmp/datafile.lzfse": false,
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]
        mockFileHandler.isWritableResults = ["/tmp": true]

        let command = CompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act
        XCTAssertNoThrow(try command.execute())

        // Assert
        XCTAssertEqual(mockFileHandler.outputStreamPaths.first, "/tmp/datafile.lzfse")
    }

    // MARK: - Buffer Size Test

    func testExecute_Uses64KBBuffer() throws {
        // Arrange
        let inputPath = "/tmp/file.txt"

        mockFileHandler.fileExistsResults = [
            inputPath: true,
            "/tmp/file.txt.lzfse": false,
            "/tmp": true
        ]
        mockFileHandler.isReadableResults = [inputPath: true]
        mockFileHandler.isWritableResults = ["/tmp": true]

        let command = CompressCommand(
            inputSource: .file(path: inputPath),
            algorithmName: "lzfse",
            fileHandler: mockFileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Act
        try command.execute()

        // Assert
        XCTAssertEqual(mockAlgorithm.lastBufferSize, 65536)  // 64KB
    }
}
