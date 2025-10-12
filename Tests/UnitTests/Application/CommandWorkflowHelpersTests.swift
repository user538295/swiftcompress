import XCTest
@testable import swiftcompress
import TestHelpers

/// Comprehensive unit tests for CommandWorkflowHelpers
/// Tests shared validation, setup, and cleanup logic used by command classes
final class CommandWorkflowHelpersTests: XCTestCase {

    // MARK: - Test Fixtures

    private var mockFileHandler: MockFileHandler!
    private var validationRules: ValidationRules!
    private var progressCoordinator: ProgressCoordinator!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockFileHandler = MockFileHandler()
        validationRules = ValidationRules()
        progressCoordinator = ProgressCoordinator()
    }

    override func tearDown() {
        mockFileHandler = nil
        validationRules = nil
        progressCoordinator = nil
        super.tearDown()
    }

    // MARK: - validateFileInput Tests

    func testValidateFileInput_WithValidFile_Succeeds() throws {
        // Arrange
        let inputPath = "/tmp/test.txt"
        mockFileHandler.fileExistsResults = [inputPath: true]
        mockFileHandler.isReadableResults = [inputPath: true]

        // Act & Assert
        XCTAssertNoThrow(
            try CommandWorkflowHelpers.validateFileInput(
                source: .file(path: inputPath),
                fileHandler: mockFileHandler,
                validationRules: validationRules
            )
        )
    }

    func testValidateFileInput_WithStdin_Succeeds() throws {
        // Arrange - stdin doesn't need file system validation

        // Act & Assert
        XCTAssertNoThrow(
            try CommandWorkflowHelpers.validateFileInput(
                source: .stdin,
                fileHandler: mockFileHandler,
                validationRules: validationRules
            )
        )
    }

    func testValidateFileInput_FileNotFound_Throws() {
        // Arrange
        let inputPath = "/tmp/missing.txt"
        mockFileHandler.fileExistsResults = [inputPath: false]

        // Act & Assert
        XCTAssertThrowsError(
            try CommandWorkflowHelpers.validateFileInput(
                source: .file(path: inputPath),
                fileHandler: mockFileHandler,
                validationRules: validationRules
            )
        ) { error in
            XCTAssertTrue(error is InfrastructureError)
            if case InfrastructureError.fileNotFound(let path) = error {
                XCTAssertEqual(path, inputPath)
            } else {
                XCTFail("Expected fileNotFound error")
            }
        }
    }

    func testValidateFileInput_FileNotReadable_Throws() {
        // Arrange
        let inputPath = "/tmp/test.txt"
        mockFileHandler.fileExistsResults = [inputPath: true]
        mockFileHandler.isReadableResults = [inputPath: false]

        // Act & Assert
        XCTAssertThrowsError(
            try CommandWorkflowHelpers.validateFileInput(
                source: .file(path: inputPath),
                fileHandler: mockFileHandler,
                validationRules: validationRules
            )
        ) { error in
            XCTAssertTrue(error is InfrastructureError)
            if case InfrastructureError.fileNotReadable(let path, let reason) = error {
                XCTAssertEqual(path, inputPath)
                XCTAssertEqual(reason, "Permission denied")
            } else {
                XCTFail("Expected fileNotReadable error")
            }
        }
    }

    func testValidateFileInput_InvalidPath_Throws() {
        // Arrange - empty path is invalid

        // Act & Assert
        XCTAssertThrowsError(
            try CommandWorkflowHelpers.validateFileInput(
                source: .file(path: ""),
                fileHandler: mockFileHandler,
                validationRules: validationRules
            )
        ) { error in
            XCTAssertTrue(error is DomainError)
            if case DomainError.invalidInputPath = error {
                // Expected
            } else {
                XCTFail("Expected invalidInputPath error")
            }
        }
    }

    // MARK: - validateFileOutput Tests

    func testValidateFileOutput_ValidPath_Succeeds() throws {
        // Arrange
        let outputPath = "/tmp/output.txt"
        mockFileHandler.fileExistsResults = [outputPath: false]
        mockFileHandler.isWritableResults = ["/tmp": true]

        // Act & Assert
        XCTAssertNoThrow(
            try CommandWorkflowHelpers.validateFileOutput(
                destination: .file(path: outputPath),
                inputSource: .file(path: "/tmp/input.txt"),
                forceOverwrite: false,
                fileHandler: mockFileHandler,
                validationRules: validationRules,
                createDirectoryIfNeeded: false
            )
        )
    }

    func testValidateFileOutput_WithStdout_Succeeds() throws {
        // Arrange - stdout doesn't need validation

        // Act & Assert
        XCTAssertNoThrow(
            try CommandWorkflowHelpers.validateFileOutput(
                destination: .stdout,
                inputSource: .file(path: "/tmp/input.txt"),
                forceOverwrite: false,
                fileHandler: mockFileHandler,
                validationRules: validationRules,
                createDirectoryIfNeeded: false
            )
        )
    }

    func testValidateFileOutput_FileExists_WithoutForce_Throws() {
        // Arrange
        let outputPath = "/tmp/exists.txt"
        mockFileHandler.fileExistsResults = [outputPath: true]

        // Act & Assert
        XCTAssertThrowsError(
            try CommandWorkflowHelpers.validateFileOutput(
                destination: .file(path: outputPath),
                inputSource: .file(path: "/tmp/input.txt"),
                forceOverwrite: false,
                fileHandler: mockFileHandler,
                validationRules: validationRules,
                createDirectoryIfNeeded: false
            )
        ) { error in
            XCTAssertTrue(error is DomainError)
            if case DomainError.outputFileExists(let path) = error {
                XCTAssertEqual(path, outputPath)
            } else {
                XCTFail("Expected outputFileExists error")
            }
        }
    }

    func testValidateFileOutput_FileExists_WithForce_Succeeds() throws {
        // Arrange
        let outputPath = "/tmp/exists.txt"
        mockFileHandler.fileExistsResults = [outputPath: true]
        mockFileHandler.isWritableResults = ["/tmp": true]

        // Act & Assert
        XCTAssertNoThrow(
            try CommandWorkflowHelpers.validateFileOutput(
                destination: .file(path: outputPath),
                inputSource: .file(path: "/tmp/input.txt"),
                forceOverwrite: true,
                fileHandler: mockFileHandler,
                validationRules: validationRules,
                createDirectoryIfNeeded: false
            )
        )
    }

    func testValidateFileOutput_CreatesDirectory_WhenNeeded() throws {
        // Arrange
        let outputPath = "/tmp/newdir/output.txt"
        mockFileHandler.fileExistsResults = [
            outputPath: false,
            "/tmp/newdir": false  // Directory doesn't exist
        ]

        // Act
        try CommandWorkflowHelpers.validateFileOutput(
            destination: .file(path: outputPath),
            inputSource: .file(path: "/tmp/input.txt"),
            forceOverwrite: false,
            fileHandler: mockFileHandler,
            validationRules: validationRules,
            createDirectoryIfNeeded: true
        )

        // Assert - directory creation was called
        XCTAssertTrue(mockFileHandler.createDirectoryPaths.contains("/tmp/newdir"))
    }

    func testValidateFileOutput_DoesNotCreateDirectory_WhenNotNeeded() throws {
        // Arrange
        let outputPath = "/tmp/output.txt"
        mockFileHandler.fileExistsResults = [outputPath: false]
        mockFileHandler.isWritableResults = ["/tmp": true]

        // Act
        try CommandWorkflowHelpers.validateFileOutput(
            destination: .file(path: outputPath),
            inputSource: .file(path: "/tmp/input.txt"),
            forceOverwrite: false,
            fileHandler: mockFileHandler,
            validationRules: validationRules,
            createDirectoryIfNeeded: false
        )

        // Assert - no directory creation
        XCTAssertEqual(mockFileHandler.createDirectoryPaths.count, 0)
    }

    func testValidateFileOutput_DirectoryNotWritable_Throws() {
        // Arrange
        let outputPath = "/readonly/output.txt"
        mockFileHandler.fileExistsResults = [outputPath: false]
        mockFileHandler.isWritableResults = ["/readonly": false]

        // Act & Assert
        XCTAssertThrowsError(
            try CommandWorkflowHelpers.validateFileOutput(
                destination: .file(path: outputPath),
                inputSource: .file(path: "/tmp/input.txt"),
                forceOverwrite: false,
                fileHandler: mockFileHandler,
                validationRules: validationRules,
                createDirectoryIfNeeded: false
            )
        ) { error in
            XCTAssertTrue(error is InfrastructureError)
            if case InfrastructureError.directoryNotWritable(let path) = error {
                XCTAssertEqual(path, "/readonly")
            } else {
                XCTFail("Expected directoryNotWritable error")
            }
        }
    }

    func testValidateFileOutput_SameAsInput_Throws() {
        // Arrange
        let path = "/tmp/file.txt"
        mockFileHandler.fileExistsResults = [path: true]

        // Act & Assert
        XCTAssertThrowsError(
            try CommandWorkflowHelpers.validateFileOutput(
                destination: .file(path: path),
                inputSource: .file(path: path),
                forceOverwrite: false,
                fileHandler: mockFileHandler,
                validationRules: validationRules,
                createDirectoryIfNeeded: false
            )
        ) { error in
            XCTAssertTrue(error is DomainError)
            if case DomainError.inputOutputSame = error {
                // Expected
            } else {
                XCTFail("Expected inputOutputSame error")
            }
        }
    }

    // MARK: - setupProgressTracking Tests

    func testSetupProgressTracking_WithFileInput_ReturnsConfiguredStream() throws {
        // Arrange
        let inputPath = "/tmp/test.txt"
        let fileSize: Int64 = 1024
        mockFileHandler.fileSizeResults = [inputPath: fileSize]

        // Act
        let result = try CommandWorkflowHelpers.setupProgressTracking(
            inputSource: .file(path: inputPath),
            outputDestination: .file(path: "/tmp/output.txt"),
            progressEnabled: true,
            operationDescription: "Testing",
            fileHandler: mockFileHandler,
            progressCoordinator: progressCoordinator
        )

        // Assert
        XCTAssertNotNil(result.reporter)
        XCTAssertNotNil(result.inputStream)
        XCTAssertTrue(mockFileHandler.inputStreamPaths.contains(inputPath))
    }

    func testSetupProgressTracking_WithStdin_ReturnsConfiguredStream() throws {
        // Arrange - stdin has unknown size (0)

        // Act
        let result = try CommandWorkflowHelpers.setupProgressTracking(
            inputSource: .stdin,
            outputDestination: .stdout,
            progressEnabled: true,
            operationDescription: "Testing stdin",
            fileHandler: mockFileHandler,
            progressCoordinator: progressCoordinator
        )

        // Assert
        XCTAssertNotNil(result.reporter)
        XCTAssertNotNil(result.inputStream)
    }

    func testSetupProgressTracking_WithProgressDisabled_StillReturnsStream() throws {
        // Arrange
        let inputPath = "/tmp/test.txt"
        mockFileHandler.fileSizeResults = [inputPath: 1024]

        // Act
        let result = try CommandWorkflowHelpers.setupProgressTracking(
            inputSource: .file(path: inputPath),
            outputDestination: .file(path: "/tmp/output.txt"),
            progressEnabled: false,
            operationDescription: "Testing",
            fileHandler: mockFileHandler,
            progressCoordinator: progressCoordinator
        )

        // Assert
        XCTAssertNotNil(result.reporter)
        XCTAssertNotNil(result.inputStream)
    }

    func testSetupProgressTracking_StreamCreationFails_Throws() {
        // Arrange
        let inputPath = "/tmp/test.txt"
        mockFileHandler.inputStreamError = InfrastructureError.streamCreationFailed(path: inputPath)

        // Act & Assert
        XCTAssertThrowsError(
            try CommandWorkflowHelpers.setupProgressTracking(
                inputSource: .file(path: inputPath),
                outputDestination: .file(path: "/tmp/output.txt"),
                progressEnabled: true,
                operationDescription: "Testing",
                fileHandler: mockFileHandler,
                progressCoordinator: progressCoordinator
            )
        ) { error in
            XCTAssertTrue(error is InfrastructureError)
            if case InfrastructureError.streamCreationFailed = error {
                // Expected
            } else {
                XCTFail("Expected streamCreationFailed error")
            }
        }
    }

    // MARK: - cleanupPartialOutput Tests

    func testCleanupPartialOutput_WithFile_DeletesFile() {
        // Arrange
        let outputPath = "/tmp/partial.txt"

        // Act
        CommandWorkflowHelpers.cleanupPartialOutput(
            destination: .file(path: outputPath),
            fileHandler: mockFileHandler
        )

        // Assert
        XCTAssertTrue(mockFileHandler.deleteFilePaths.contains(outputPath))
    }

    func testCleanupPartialOutput_WithStdout_DoesNothing() {
        // Arrange - stdout doesn't need cleanup

        // Act
        CommandWorkflowHelpers.cleanupPartialOutput(
            destination: .stdout,
            fileHandler: mockFileHandler
        )

        // Assert
        XCTAssertEqual(mockFileHandler.deleteFilePaths.count, 0)
    }

    func testCleanupPartialOutput_MultipleFiles_DeletesAll() {
        // Arrange
        let path1 = "/tmp/file1.txt"
        let path2 = "/tmp/file2.txt"

        // Act
        CommandWorkflowHelpers.cleanupPartialOutput(
            destination: .file(path: path1),
            fileHandler: mockFileHandler
        )
        CommandWorkflowHelpers.cleanupPartialOutput(
            destination: .file(path: path2),
            fileHandler: mockFileHandler
        )

        // Assert
        XCTAssertEqual(mockFileHandler.deleteFilePaths.count, 2)
        XCTAssertTrue(mockFileHandler.deleteFilePaths.contains(path1))
        XCTAssertTrue(mockFileHandler.deleteFilePaths.contains(path2))
    }

    // MARK: - Integration Tests

    func testValidateFileOutput_WithStdinInput_ValidatesCorrectly() throws {
        // Arrange
        let outputPath = "/tmp/output.txt"
        mockFileHandler.fileExistsResults = [outputPath: false]
        mockFileHandler.isWritableResults = ["/tmp": true]

        // Act & Assert
        XCTAssertNoThrow(
            try CommandWorkflowHelpers.validateFileOutput(
                destination: .file(path: outputPath),
                inputSource: .stdin,
                forceOverwrite: false,
                fileHandler: mockFileHandler,
                validationRules: validationRules,
                createDirectoryIfNeeded: false
            )
        )
    }

    func testSetupProgressTracking_WithFileAndProgress_ConfiguresCorrectly() throws {
        // Arrange
        let inputPath = "/tmp/large.txt"
        let fileSize: Int64 = 10_000_000  // 10 MB
        mockFileHandler.fileSizeResults = [inputPath: fileSize]

        // Act
        let result = try CommandWorkflowHelpers.setupProgressTracking(
            inputSource: .file(path: inputPath),
            outputDestination: .file(path: "/tmp/output.txt"),
            progressEnabled: true,
            operationDescription: "Compressing large.txt",
            fileHandler: mockFileHandler,
            progressCoordinator: progressCoordinator
        )

        // Assert
        XCTAssertNotNil(result.reporter)
        XCTAssertNotNil(result.inputStream)
        XCTAssertEqual(mockFileHandler.inputStreamPaths.count, 1)
        XCTAssertEqual(mockFileHandler.inputStreamPaths.first, inputPath)
    }
}
