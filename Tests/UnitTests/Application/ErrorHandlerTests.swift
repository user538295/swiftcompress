import XCTest
@testable import swiftcompress

/// Comprehensive unit tests for ErrorHandler
/// Tests error translation, exit code mapping, and message formatting
final class ErrorHandlerTests: XCTestCase {

    var sut: ErrorHandler!

    override func setUp() {
        super.setUp()
        sut = ErrorHandler()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - CLI Error Tests

    func testHandleCLIError_InvalidCommand() {
        // Given
        let error = CLIError.invalidCommand(provided: "compress", expected: ["c", "x"])

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Invalid command"))
        XCTAssertTrue(result.message.contains("compress"))
        XCTAssertTrue(result.message.contains("c"))
        XCTAssertTrue(result.message.contains("x"))
        XCTAssertFalse(result.shouldPrintStackTrace)
    }

    func testHandleCLIError_MissingRequiredArgument() {
        // Given
        let error = CLIError.missingRequiredArgument(name: "-m")

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Missing required argument"))
        XCTAssertTrue(result.message.contains("-m"))
    }

    func testHandleCLIError_UnknownFlag() {
        // Given
        let error = CLIError.unknownFlag(flag: "--verbose")

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Unknown flag"))
        XCTAssertTrue(result.message.contains("--verbose"))
    }

    func testHandleCLIError_InvalidFlagValue() {
        // Given
        let error = CLIError.invalidFlagValue(
            flag: "-m",
            value: "gzip",
            expected: "lzfse, lz4, zlib, lzma"
        )

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Invalid value"))
        XCTAssertTrue(result.message.contains("gzip"))
        XCTAssertTrue(result.message.contains("-m"))
        XCTAssertTrue(result.message.contains("Expected"))
    }

    func testHandleCLIError_HelpRequested() {
        // Given
        let error = CLIError.helpRequested

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 0) // Help is not an error
        XCTAssertTrue(result.message.isEmpty)
    }

    func testHandleCLIError_VersionRequested() {
        // Given
        let error = CLIError.versionRequested

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 0) // Version is not an error
        XCTAssertTrue(result.message.isEmpty)
    }

    // MARK: - Application Error Tests

    func testHandleApplicationError_CommandExecutionFailed() {
        // Given
        let underlyingError = DomainError.outputFileExists(path: "/tmp/test.txt")
        let error = ApplicationError.commandExecutionFailed(
            commandName: "compress",
            underlyingError: underlyingError
        )

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Command 'compress' failed"))
        XCTAssertTrue(result.message.contains("Output file already exists"))
    }

    func testHandleApplicationError_PreconditionFailed() {
        // Given
        let error = ApplicationError.preconditionFailed(message: "Input file must exist")

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Precondition check failed"))
        XCTAssertTrue(result.message.contains("Input file must exist"))
    }

    func testHandleApplicationError_PostconditionFailed() {
        // Given
        let error = ApplicationError.postconditionFailed(message: "Output file size mismatch")

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("postcondition check failed"))
        XCTAssertTrue(result.message.contains("Output file size mismatch"))
    }

    func testHandleApplicationError_WorkflowInterrupted() {
        // Given
        let error = ApplicationError.workflowInterrupted(
            stage: "compression",
            reason: "user cancellation"
        )

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Operation interrupted"))
        XCTAssertTrue(result.message.contains("compression"))
        XCTAssertTrue(result.message.contains("user cancellation"))
    }

    func testHandleApplicationError_DependencyNotAvailable() {
        // Given
        let error = ApplicationError.dependencyNotAvailable(dependencyName: "CompressionEngine")

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Required component"))
        XCTAssertTrue(result.message.contains("CompressionEngine"))
        XCTAssertTrue(result.message.contains("not available"))
    }

    // MARK: - Domain Error Tests

    func testHandleDomainError_InvalidAlgorithmName() {
        // Given
        let error = DomainError.invalidAlgorithmName(
            name: "gzip",
            supported: ["lzfse", "lz4", "zlib", "lzma"]
        )

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Unknown algorithm"))
        XCTAssertTrue(result.message.contains("gzip"))
        XCTAssertTrue(result.message.contains("lzfse"))
        XCTAssertTrue(result.message.contains("lz4"))
        XCTAssertTrue(result.message.contains("zlib"))
        XCTAssertTrue(result.message.contains("lzma"))
    }

    func testHandleDomainError_AlgorithmNotRegistered() {
        // Given
        let error = DomainError.algorithmNotRegistered(name: "bzip2")

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("not registered"))
        XCTAssertTrue(result.message.contains("bzip2"))
    }

    func testHandleDomainError_InvalidInputPath() {
        // Given
        let error = DomainError.invalidInputPath(path: "", reason: "path is empty")

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Invalid input path"))
        XCTAssertTrue(result.message.contains("path is empty"))
    }

    func testHandleDomainError_InvalidOutputPath() {
        // Given
        let error = DomainError.invalidOutputPath(
            path: "/invalid\0path",
            reason: "contains null bytes"
        )

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Invalid output path"))
        XCTAssertTrue(result.message.contains("contains null bytes"))
    }

    func testHandleDomainError_InputOutputSame() {
        // Given
        let error = DomainError.inputOutputSame(path: "/tmp/test.txt")

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("cannot be the same"))
        XCTAssertTrue(result.message.contains("/tmp/test.txt"))
    }

    func testHandleDomainError_PathTraversalAttempt() {
        // Given
        let error = DomainError.pathTraversalAttempt(path: "../../../etc/passwd")

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("invalid characters"))
        XCTAssertTrue(result.message.contains("../../../etc/passwd"))
    }

    func testHandleDomainError_OutputFileExists() {
        // Given
        let error = DomainError.outputFileExists(path: "/tmp/output.lzfse")

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Output file already exists"))
        XCTAssertTrue(result.message.contains("/tmp/output.lzfse"))
        XCTAssertTrue(result.message.contains("Use -f"))
        XCTAssertTrue(result.message.contains("overwrite"))
    }

    func testHandleDomainError_InputFileEmpty() {
        // Given
        let error = DomainError.inputFileEmpty(path: "/tmp/empty.txt")

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Cannot compress empty file"))
        XCTAssertTrue(result.message.contains("/tmp/empty.txt"))
    }

    func testHandleDomainError_FileTooLarge() {
        // Given
        let error = DomainError.fileTooLarge(
            path: "/tmp/huge.bin",
            size: 10_000_000_000,
            limit: 1_000_000_000
        )

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("File too large"))
        XCTAssertTrue(result.message.contains("/tmp/huge.bin"))
        XCTAssertTrue(result.message.contains("GB")) // Should format bytes
        XCTAssertTrue(result.message.contains("Maximum size"))
    }

    func testHandleDomainError_MissingRequiredArgument() {
        // Given
        let error = DomainError.missingRequiredArgument(argumentName: "--algorithm")

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Missing required argument"))
        XCTAssertTrue(result.message.contains("--algorithm"))
    }

    func testHandleDomainError_InvalidFlagCombination() {
        // Given
        let error = DomainError.invalidFlagCombination(
            flags: ["-m", "-a"],
            reason: "cannot use both together"
        )

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Invalid flag combination"))
        XCTAssertTrue(result.message.contains("-m"))
        XCTAssertTrue(result.message.contains("-a"))
        XCTAssertTrue(result.message.contains("cannot use both together"))
    }

    // MARK: - Infrastructure Error Tests

    func testHandleInfrastructureError_FileNotFound() {
        // Given
        let error = InfrastructureError.fileNotFound(path: "/tmp/missing.txt")

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("File not found"))
        XCTAssertTrue(result.message.contains("/tmp/missing.txt"))
    }

    func testHandleInfrastructureError_FileNotReadable_WithReason() {
        // Given
        let error = InfrastructureError.fileNotReadable(
            path: "/tmp/locked.txt",
            reason: "permission denied"
        )

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Cannot read file"))
        XCTAssertTrue(result.message.contains("/tmp/locked.txt"))
        XCTAssertTrue(result.message.contains("permission denied"))
    }

    func testHandleInfrastructureError_FileNotReadable_WithoutReason() {
        // Given
        let error = InfrastructureError.fileNotReadable(path: "/tmp/locked.txt", reason: nil)

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Cannot read file"))
        XCTAssertTrue(result.message.contains("/tmp/locked.txt"))
        XCTAssertTrue(result.message.contains("permissions"))
    }

    func testHandleInfrastructureError_FileNotWritable_WithReason() {
        // Given
        let error = InfrastructureError.fileNotWritable(
            path: "/tmp/readonly.txt",
            reason: "file is read-only"
        )

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Cannot write file"))
        XCTAssertTrue(result.message.contains("/tmp/readonly.txt"))
        XCTAssertTrue(result.message.contains("file is read-only"))
    }

    func testHandleInfrastructureError_FileNotWritable_WithoutReason() {
        // Given
        let error = InfrastructureError.fileNotWritable(path: "/tmp/readonly.txt", reason: nil)

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Cannot write file"))
        XCTAssertTrue(result.message.contains("/tmp/readonly.txt"))
        XCTAssertTrue(result.message.contains("permissions"))
    }

    func testHandleInfrastructureError_DirectoryNotFound() {
        // Given
        let error = InfrastructureError.directoryNotFound(path: "/tmp/missing/")

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Directory not found"))
        XCTAssertTrue(result.message.contains("/tmp/missing/"))
    }

    func testHandleInfrastructureError_DirectoryNotWritable() {
        // Given
        let error = InfrastructureError.directoryNotWritable(path: "/tmp/readonly/")

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Directory is not writable"))
        XCTAssertTrue(result.message.contains("/tmp/readonly/"))
        XCTAssertTrue(result.message.contains("permissions"))
    }

    func testHandleInfrastructureError_InsufficientDiskSpace() {
        // Given
        let error = InfrastructureError.insufficientDiskSpace(
            required: 5_000_000_000,
            available: 1_000_000_000
        )

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Insufficient disk space"))
        XCTAssertTrue(result.message.contains("Required"))
        XCTAssertTrue(result.message.contains("Available"))
        XCTAssertTrue(result.message.contains("GB")) // Should format bytes
    }

    func testHandleInfrastructureError_ReadFailed() {
        // Given
        let nsError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        let error = InfrastructureError.readFailed(path: "/tmp/test.txt", underlyingError: nsError)

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Failed to read file"))
        XCTAssertTrue(result.message.contains("/tmp/test.txt"))
    }

    func testHandleInfrastructureError_WriteFailed() {
        // Given
        let nsError = NSError(domain: "TestDomain", code: 2, userInfo: nil)
        let error = InfrastructureError.writeFailed(path: "/tmp/test.txt", underlyingError: nsError)

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Failed to write file"))
        XCTAssertTrue(result.message.contains("/tmp/test.txt"))
        XCTAssertTrue(result.message.contains("disk space"))
    }

    func testHandleInfrastructureError_StreamCreationFailed() {
        // Given
        let error = InfrastructureError.streamCreationFailed(path: "/tmp/test.txt")

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Failed to open file"))
        XCTAssertTrue(result.message.contains("/tmp/test.txt"))
    }

    func testHandleInfrastructureError_StreamReadFailed() {
        // Given
        let nsError = NSError(domain: "TestDomain", code: 3, userInfo: nil)
        let error = InfrastructureError.streamReadFailed(underlyingError: nsError)

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Failed to read data from file stream"))
    }

    func testHandleInfrastructureError_StreamWriteFailed() {
        // Given
        let nsError = NSError(domain: "TestDomain", code: 4, userInfo: nil)
        let error = InfrastructureError.streamWriteFailed(underlyingError: nsError)

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Failed to write data to file stream"))
        XCTAssertTrue(result.message.contains("disk space"))
    }

    func testHandleInfrastructureError_CompressionInitFailed() {
        // Given
        let nsError = NSError(domain: "TestDomain", code: 5, userInfo: nil)
        let error = InfrastructureError.compressionInitFailed(
            algorithm: "lzfse",
            underlyingError: nsError
        )

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Failed to initialize"))
        XCTAssertTrue(result.message.contains("lzfse"))
        XCTAssertTrue(result.message.contains("compression"))
    }

    func testHandleInfrastructureError_CompressionFailed_WithReason() {
        // Given
        let error = InfrastructureError.compressionFailed(
            algorithm: "lz4",
            reason: "invalid data format"
        )

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Compression failed"))
        XCTAssertTrue(result.message.contains("lz4"))
        XCTAssertTrue(result.message.contains("invalid data format"))
    }

    func testHandleInfrastructureError_CompressionFailed_WithoutReason() {
        // Given
        let error = InfrastructureError.compressionFailed(algorithm: "lz4", reason: nil)

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Compression failed"))
        XCTAssertTrue(result.message.contains("lz4"))
    }

    func testHandleInfrastructureError_DecompressionFailed_WithReason() {
        // Given
        let error = InfrastructureError.decompressionFailed(
            algorithm: "zlib",
            reason: "corrupted header"
        )

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Decompression failed"))
        XCTAssertTrue(result.message.contains("zlib"))
        XCTAssertTrue(result.message.contains("corrupted header"))
    }

    func testHandleInfrastructureError_DecompressionFailed_WithoutReason() {
        // Given
        let error = InfrastructureError.decompressionFailed(algorithm: "zlib", reason: nil)

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Decompression failed"))
        XCTAssertTrue(result.message.contains("zlib"))
    }

    func testHandleInfrastructureError_CorruptedData() {
        // Given
        let error = InfrastructureError.corruptedData(algorithm: "lzma")

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("corrupted"))
        XCTAssertTrue(result.message.contains("lzma"))
    }

    func testHandleInfrastructureError_UnsupportedFormat() {
        // Given
        let error = InfrastructureError.unsupportedFormat(algorithm: "lzfse")

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Unsupported file format"))
        XCTAssertTrue(result.message.contains("lzfse"))
    }

    // MARK: - Unknown Error Tests

    func testHandleUnknownError_GenericError() {
        // Given
        struct UnknownError: Error {}
        let error = UnknownError()

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("unexpected error"))
    }

    func testHandleUnknownError_NSError() {
        // Given
        let error = NSError(
            domain: "TestDomain",
            code: 999,
            userInfo: [NSLocalizedDescriptionKey: "Test error"]
        )

        // When
        let result = sut.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("unexpected error"))
    }

    // MARK: - Message Quality Tests

    func testErrorMessages_ContainNoSensitiveData() {
        // Test a sampling of errors to ensure no stack traces or internal details leak
        let errors: [Error] = [
            CLIError.invalidCommand(provided: "bad", expected: ["c", "x"]),
            DomainError.pathTraversalAttempt(path: "/../../etc/passwd"),
            InfrastructureError.fileNotFound(path: "/tmp/test.txt")
        ]

        for error in errors {
            let result = sut.handle(error)
            // Should not contain technical details
            XCTAssertFalse(result.message.contains("swift"))
            XCTAssertFalse(result.message.contains("function"))
            XCTAssertFalse(result.message.contains("line"))
        }
    }

    func testErrorMessages_StartWithError() {
        // Given
        let errors: [Error] = [
            CLIError.invalidCommand(provided: "bad", expected: ["c", "x"]),
            DomainError.fileNotFound(path: "/tmp/test.txt"),
            InfrastructureError.fileNotFound(path: "/tmp/test.txt")
        ]

        // When/Then
        for error in errors {
            let result = sut.handle(error)
            if result.exitCode != 0 && !result.message.isEmpty {
                XCTAssertTrue(
                    result.message.hasPrefix("Error:"),
                    "Error message should start with 'Error:'. Got: \(result.message)"
                )
            }
        }
    }

    func testErrorMessages_AreActionable() {
        // Test that important errors provide actionable guidance
        let outputExistsError = DomainError.outputFileExists(path: "/tmp/test.txt")
        let result = sut.handle(outputExistsError)

        XCTAssertTrue(result.message.contains("-f"))
        XCTAssertTrue(result.message.contains("overwrite"))
    }

    // MARK: - Exit Code Tests

    func testExitCodes_AllFailuresReturnOne() {
        // Given - MVP requirement: all failures return exit code 1
        let errors: [Error] = [
            CLIError.invalidCommand(provided: "bad", expected: ["c", "x"]),
            ApplicationError.preconditionFailed(message: "test"),
            DomainError.outputFileExists(path: "/tmp/test.txt"),
            InfrastructureError.fileNotFound(path: "/tmp/test.txt")
        ]

        // When/Then
        for error in errors {
            let result = sut.handle(error)
            XCTAssertEqual(
                result.exitCode,
                1,
                "All failures should return exit code 1 in MVP. Error: \(error)"
            )
        }
    }

    func testExitCodes_HelpAndVersionReturnZero() {
        // Given
        let helpError = CLIError.helpRequested
        let versionError = CLIError.versionRequested

        // When
        let helpResult = sut.handle(helpError)
        let versionResult = sut.handle(versionError)

        // Then
        XCTAssertEqual(helpResult.exitCode, 0)
        XCTAssertEqual(versionResult.exitCode, 0)
    }

    // MARK: - Integration Tests

    func testNestedErrorTranslation() {
        // Given - Application error wrapping a domain error
        let domainError = DomainError.outputFileExists(path: "/tmp/test.txt")
        let appError = ApplicationError.commandExecutionFailed(
            commandName: "compress",
            underlyingError: domainError
        )

        // When
        let result = sut.handle(appError)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.message.contains("Command 'compress' failed"))
        XCTAssertTrue(result.message.contains("Output file already exists"))
        XCTAssertTrue(result.message.contains("-f"))
    }

    func testProtocolConformance() {
        // Given
        let handler: ErrorHandlerProtocol = ErrorHandler()
        let error = DomainError.outputFileExists(path: "/tmp/test.txt")

        // When
        let result = handler.handle(error)

        // Then
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertFalse(result.message.isEmpty)
    }
}

// MARK: - Test Extension for DomainError

// Note: This extension is for testing purposes only
extension DomainError {
    static func fileNotFound(path: String) -> DomainError {
        return .invalidInputPath(path: path, reason: "file not found")
    }
}
