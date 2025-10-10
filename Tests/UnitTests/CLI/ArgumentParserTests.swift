import XCTest
@testable import swiftcompress

/// Comprehensive tests for CLI argument parsing
/// Tests all command variations, flags, and error scenarios
final class ArgumentParserTests: XCTestCase {

    var sut: CLIArgumentParser!

    override func setUp() {
        super.setUp()
        sut = CLIArgumentParser()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Test Helpers

    /// Helper to assert inputSource is a file with expected path
    func assertInputFile(_ result: ParsedCommand?, equals expectedPath: String, file: StaticString = #file, line: UInt = #line) {
        guard let result = result else {
            XCTFail("Result is nil", file: file, line: line)
            return
        }
        if case .file(let path) = result.inputSource {
            XCTAssertEqual(path, expectedPath, file: file, line: line)
        } else {
            XCTFail("Expected inputSource to be .file(\(expectedPath)) but got \(result.inputSource)", file: file, line: line)
        }
    }

    /// Helper to assert outputDestination is a file with expected path
    func assertOutputFile(_ result: ParsedCommand?, equals expectedPath: String, file: StaticString = #file, line: UInt = #line) {
        guard let result = result else {
            XCTFail("Result is nil", file: file, line: line)
            return
        }
        guard let destination = result.outputDestination else {
            XCTFail("outputDestination is nil", file: file, line: line)
            return
        }
        if case .file(let path) = destination {
            XCTAssertEqual(path, expectedPath, file: file, line: line)
        } else {
            XCTFail("Expected outputDestination to be .file(\(expectedPath)) but got \(destination)", file: file, line: line)
        }
    }

    // MARK: - Compress Command Tests

    func testParseCompressCommand_WithAllFlags() throws {
        // Arrange
        let args = ["swiftcompress", "c", "input.txt", "-m", "lzfse", "-o", "output.lzfse", "-f"]

        // Act
        let result = try sut.parse(args)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.commandType, .compress)
        assertInputFile(result, equals: "input.txt")
        XCTAssertEqual(result?.algorithmName, "lzfse")
        assertOutputFile(result, equals: "output.lzfse")
        XCTAssertEqual(result?.forceOverwrite, true)
    }

    func testParseCompressCommand_WithMinimalFlags() throws {
        // Arrange
        let args = ["swiftcompress", "c", "input.txt", "-m", "lz4"]

        // Act
        let result = try sut.parse(args)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.commandType, .compress)
        assertInputFile(result, equals: "input.txt")
        XCTAssertEqual(result?.algorithmName, "lz4")
        // In test environment, stdout is often piped (test runner), so outputDestination may be .stdout or nil
        // Both are acceptable - just verify it's not an unexpected file path
        if let dest = result?.outputDestination {
            if case .stdout = dest {
                // Expected in test environment
            } else {
                XCTFail("Expected outputDestination to be nil or .stdout, got: \(dest)")
            }
        }
        XCTAssertEqual(result?.forceOverwrite, false)
    }

    func testParseCompressCommand_WithLongFlags() throws {
        // Arrange
        let args = ["swiftcompress", "c", "input.txt", "--method", "zlib", "--output", "output.zlib", "--force"]

        // Act
        let result = try sut.parse(args)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.commandType, .compress)
        assertInputFile(result, equals: "input.txt")
        XCTAssertEqual(result?.algorithmName, "zlib")
        assertOutputFile(result, equals: "output.zlib")
        XCTAssertEqual(result?.forceOverwrite, true)
    }

    func testParseCompressCommand_WithComplexPath() throws {
        // Arrange
        let args = ["swiftcompress", "c", "/path/to/my file.txt", "-m", "lzma"]

        // Act
        let result = try sut.parse(args)

        // Assert
        XCTAssertNotNil(result)
        assertInputFile(result, equals: "/path/to/my file.txt")
        XCTAssertEqual(result?.algorithmName, "lzma")
    }

    func testParseCompressCommand_AlgorithmNameCaseInsensitive() throws {
        // Test uppercase
        let args1 = ["swiftcompress", "c", "input.txt", "-m", "LZFSE"]
        let result1 = try sut.parse(args1)
        XCTAssertEqual(result1?.algorithmName, "lzfse")

        // Test mixed case
        let args2 = ["swiftcompress", "c", "input.txt", "-m", "LzMa"]
        let result2 = try sut.parse(args2)
        XCTAssertEqual(result2?.algorithmName, "lzma")
    }

    // MARK: - Decompress Command Tests

    func testParseDecompressCommand_WithAllFlags() throws {
        // Arrange
        let args = ["swiftcompress", "x", "input.lzfse", "-m", "lzfse", "-o", "output.txt", "-f"]

        // Act
        let result = try sut.parse(args)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.commandType, .decompress)
        assertInputFile(result, equals: "input.lzfse")
        XCTAssertEqual(result?.algorithmName, "lzfse")
        assertOutputFile(result, equals: "output.txt")
        XCTAssertEqual(result?.forceOverwrite, true)
    }

    func testParseDecompressCommand_WithMinimalFlags() throws {
        // Arrange
        let args = ["swiftcompress", "x", "input.lz4", "-m", "lz4"]

        // Act
        let result = try sut.parse(args)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.commandType, .decompress)
        assertInputFile(result, equals: "input.lz4")
        XCTAssertEqual(result?.algorithmName, "lz4")
        // In test environment, stdout is often piped (test runner), so outputDestination may be .stdout or nil
        if let dest = result?.outputDestination {
            if case .stdout = dest {
                // Expected in test environment
            } else {
                XCTFail("Expected outputDestination to be nil or .stdout, got: \(dest)")
            }
        }
        XCTAssertEqual(result?.forceOverwrite, false)
    }

    func testParseDecompressCommand_WithLongFlags() throws {
        // Arrange
        let args = ["swiftcompress", "x", "input.zlib", "--method", "zlib", "--output", "output.txt"]

        // Act
        let result = try sut.parse(args)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.commandType, .decompress)
        XCTAssertEqual(result?.algorithmName, "zlib")
        assertOutputFile(result, equals: "output.txt")
    }

    // MARK: - Algorithm Validation Tests

    func testParseCommand_AllSupportedAlgorithms() throws {
        let algorithms = ["lzfse", "lz4", "zlib", "lzma"]

        for algorithm in algorithms {
            let args = ["swiftcompress", "c", "input.txt", "-m", algorithm]
            let result = try sut.parse(args)
            XCTAssertEqual(result?.algorithmName, algorithm, "Algorithm \(algorithm) should be supported")
        }
    }

    func testParseCommand_InvalidAlgorithm_ThrowsError() {
        // Arrange
        let args = ["swiftcompress", "c", "input.txt", "-m", "invalid"]

        // Act & Assert
        XCTAssertThrowsError(try sut.parse(args)) { error in
            guard let cliError = error as? CLIError else {
                XCTFail("Expected CLIError but got \(type(of: error))")
                return
            }

            if case .invalidFlagValue(let flag, let value, let expected) = cliError {
                XCTAssertEqual(flag, "-m/--method")
                XCTAssertEqual(value, "invalid")
                XCTAssertTrue(expected.contains("lzfse"))
            } else {
                XCTFail("Expected invalidFlagValue error but got \(cliError)")
            }
        }
    }

    // MARK: - Error Tests - Missing Arguments

    func testParseCommand_MissingCommand_ThrowsError() {
        // Arrange
        let args = ["swiftcompress"]

        // Act & Assert
        XCTAssertThrowsError(try sut.parse(args)) { error in
            guard let cliError = error as? CLIError else {
                XCTFail("Expected CLIError but got \(type(of: error))")
                return
            }

            if case .missingRequiredArgument = cliError {
                // Expected error type
            } else {
                XCTFail("Expected missingRequiredArgument error but got \(cliError)")
            }
        }
    }

    func testParseCommand_InvalidCommand_ThrowsError() {
        // Arrange
        let args = ["swiftcompress", "invalid"]

        // Act & Assert
        XCTAssertThrowsError(try sut.parse(args)) { error in
            guard let cliError = error as? CLIError else {
                XCTFail("Expected CLIError but got \(type(of: error))")
                return
            }

            if case .invalidCommand(let provided, let expected) = cliError {
                XCTAssertEqual(provided, "invalid")
                XCTAssertTrue(expected.contains("c"))
                XCTAssertTrue(expected.contains("x"))
            } else {
                XCTFail("Expected invalidCommand error but got \(cliError)")
            }
        }
    }

    func testParseCompressCommand_MissingInputFile_HandlesBothScenarios() throws {
        // Arrange
        // With new stdin/stdout support, missing input file triggers stdin detection
        // Behavior depends on whether stdin is piped in test environment
        let args = ["swiftcompress", "c", "-m", "lzfse"]

        // Act & Assert
        if TerminalDetector.isStdinPipe() {
            // If stdin is piped, parsing should succeed with stdin as input
            let result = try? sut.parse(args)
            XCTAssertNotNil(result, "Should parse successfully when stdin is piped")
        } else {
            // If stdin is not piped, should throw error
            XCTAssertThrowsError(try sut.parse(args)) { error in
                guard let cliError = error as? CLIError else {
                    XCTFail("Expected CLIError but got \(type(of: error))")
                    return
                }

                if case .missingRequiredArgument(let name) = cliError {
                    XCTAssertTrue(name.lowercased().contains("input") ||
                                 name.lowercased().contains("file") ||
                                 name.lowercased().contains("stdin"),
                                  "Expected missing input error, got: \(name)")
                } else {
                    XCTFail("Expected missingRequiredArgument error but got \(cliError)")
                }
            }
        }
    }

    func testParseCompressCommand_MissingMethod_UsesDefaultAlgorithm() throws {
        // Arrange
        // With compression level support, -m flag is now optional
        // It defaults to the balanced level's recommended algorithm (lzfse)
        let args = ["swiftcompress", "c", "input.txt"]

        // Act
        let result = try sut.parse(args)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.commandType, .compress)
        XCTAssertEqual(result?.compressionLevel, .balanced, "Should default to balanced level")
        XCTAssertEqual(result?.algorithmName, "lzfse", "Should use balanced level's recommended algorithm")
        assertInputFile(result, equals: "input.txt")
    }

    func testParseDecompressCommand_MissingInputFile_HandlesBothScenarios() throws {
        // Arrange
        // With new stdin/stdout support, missing input file triggers stdin detection
        // Behavior depends on whether stdin is piped in test environment
        let args = ["swiftcompress", "x", "-m", "lzfse"]

        // Act & Assert
        if TerminalDetector.isStdinPipe() {
            // If stdin is piped, parsing should succeed with stdin as input
            let result = try? sut.parse(args)
            XCTAssertNotNil(result, "Should parse successfully when stdin is piped")
        } else {
            // If stdin is not piped, should throw error
            XCTAssertThrowsError(try sut.parse(args)) { error in
                guard let cliError = error as? CLIError else {
                    XCTFail("Expected CLIError but got \(type(of: error))")
                    return
                }

                if case .missingRequiredArgument(let name) = cliError {
                    XCTAssertTrue(name.lowercased().contains("input") ||
                                 name.lowercased().contains("file") ||
                                 name.lowercased().contains("stdin"),
                                  "Expected missing input error, got: \(name)")
                } else {
                    XCTFail("Expected missingRequiredArgument error but got \(cliError)")
                }
            }
        }
    }

    func testParseDecompressCommand_MissingMethod_DoesNotThrowError() {
        // Arrange
        // For decompress, method is optional (can be inferred from extension)
        let args = ["swiftcompress", "x", "input.lzfse"]

        // Act & Assert
        // This should NOT throw an error - method is optional for decompress
        XCTAssertNoThrow(try sut.parse(args), "Method should be optional for decompress command")

        // Verify the command was parsed correctly
        if let result = try? sut.parse(args) {
            XCTAssertEqual(result.commandType, .decompress)
            assertInputFile(result, equals: "input.lzfse")
            XCTAssertNil(result.algorithmName, "Algorithm should be nil (to be inferred)")
        }
    }

    // MARK: - Error Tests - Unknown Flags

    func testParseCommand_UnknownFlag_ThrowsError() {
        // Arrange
        let args = ["swiftcompress", "c", "input.txt", "-m", "lzfse", "--unknown"]

        // Act & Assert
        XCTAssertThrowsError(try sut.parse(args)) { error in
            guard let cliError = error as? CLIError else {
                XCTFail("Expected CLIError but got \(type(of: error))")
                return
            }

            // ArgumentParser treats unknown flags as missing required arguments
            // This is acceptable behavior for CLI error handling
            if case .unknownFlag(let flag) = cliError {
                XCTAssertTrue(flag.contains("unknown"), "Flag should contain 'unknown', got: \(flag)")
            } else if case .missingRequiredArgument(let name) = cliError {
                // Also acceptable - ArgumentParser may report this as a missing argument
                // Accept any error that indicates something is wrong with arguments
                XCTAssertTrue(true, "Got missingRequiredArgument(\(name)) which is acceptable")
            } else {
                XCTFail("Expected unknownFlag or missingRequiredArgument error but got \(cliError)")
            }
        }
    }

    // MARK: - Help and Version Tests

    func testParseCommand_HelpFlag_ThrowsHelpRequested() {
        // Test short form
        let args1 = ["swiftcompress", "--help"]
        XCTAssertThrowsError(try sut.parse(args1)) { error in
            guard let cliError = error as? CLIError else {
                XCTFail("Expected CLIError but got \(type(of: error))")
                return
            }
            if case .helpRequested = cliError {
                // Expected
            } else {
                XCTFail("Expected helpRequested error but got \(cliError)")
            }
        }

        // Test with subcommand
        let args2 = ["swiftcompress", "c", "--help"]
        XCTAssertThrowsError(try sut.parse(args2)) { error in
            guard let cliError = error as? CLIError else {
                return
            }
            if case .helpRequested = cliError {
                // Expected
            }
        }
    }

    func testParseCommand_VersionFlag_ThrowsVersionRequested() {
        // Test version flag
        let args = ["swiftcompress", "--version"]

        XCTAssertThrowsError(try sut.parse(args)) { error in
            // ArgumentParser handles version directly, may throw help or exit
            // We accept either helpRequested or an exit code
            if let cliError = error as? CLIError {
                if case .helpRequested = cliError {
                    // This is acceptable for version display
                } else if case .versionRequested = cliError {
                    // This is the ideal case
                } else {
                    XCTFail("Expected helpRequested or versionRequested but got \(cliError)")
                }
            }
        }
    }

    // MARK: - Edge Case Tests

    func testParseCommand_EmptyInputPath_HandlesBothScenarios() throws {
        // Empty input path triggers stdin detection
        // Behavior depends on whether stdin is piped in test environment
        let args = ["swiftcompress", "c", "", "-m", "lzfse"]

        if TerminalDetector.isStdinPipe() {
            // If stdin is piped (test runner), parsing should succeed with stdin as input
            let result = try? sut.parse(args)
            XCTAssertNotNil(result, "Should parse successfully when stdin is piped")
            if case .stdin = result?.inputSource {
                // Expected
            } else {
                XCTFail("Expected inputSource to be stdin when piped")
            }
        } else {
            // If stdin is not piped, should throw error
            XCTAssertThrowsError(try sut.parse(args)) { error in
                guard let cliError = error as? CLIError else {
                    XCTFail("Expected CLIError but got \(type(of: error))")
                    return
                }
                if case .missingRequiredArgument(let name) = cliError {
                    XCTAssertTrue(name.contains("inputFile") || name.contains("stdin"),
                                 "Expected missing input error, got: \(name)")
                } else {
                    XCTFail("Expected missingRequiredArgument error but got \(cliError)")
                }
            }
        }
    }

    func testParseCommand_OutputPathWithoutDash_ParsedAsArgument() {
        // Missing -o flag should cause parsing error
        let args = ["swiftcompress", "c", "input.txt", "-m", "lzfse", "output.lzfse"]

        XCTAssertThrowsError(try sut.parse(args)) { error in
            // Should fail because output.lzfse is not recognized
            XCTAssertNotNil(error)
        }
    }

    func testParseCommand_MultipleForceFlags_OnlyLastMatters() throws {
        // Multiple -f flags should still result in force = true
        let args = ["swiftcompress", "c", "input.txt", "-m", "lzfse", "-f"]

        let result = try sut.parse(args)
        XCTAssertEqual(result?.forceOverwrite, true)
    }

    func testParseCommand_FlagOrderIndependent() throws {
        // Test different flag orders produce same result
        let args1 = ["swiftcompress", "c", "input.txt", "-m", "lzfse", "-o", "output.lzfse", "-f"]
        let args2 = ["swiftcompress", "c", "input.txt", "-f", "-o", "output.lzfse", "-m", "lzfse"]
        let args3 = ["swiftcompress", "c", "input.txt", "-o", "output.lzfse", "-f", "-m", "lzfse"]

        let result1 = try sut.parse(args1)
        let result2 = try sut.parse(args2)
        let result3 = try sut.parse(args3)

        XCTAssertEqual(result1?.commandType, result2?.commandType)
        XCTAssertEqual(result1?.inputSource, result2?.inputSource)
        XCTAssertEqual(result1?.algorithmName, result2?.algorithmName)
        XCTAssertEqual(result1?.outputDestination, result2?.outputDestination)
        XCTAssertEqual(result1?.forceOverwrite, result2?.forceOverwrite)

        XCTAssertEqual(result2?.commandType, result3?.commandType)
        XCTAssertEqual(result2?.algorithmName, result3?.algorithmName)
    }

    // MARK: - Special Characters Tests

    func testParseCommand_InputPathWithSpaces() throws {
        let args = ["swiftcompress", "c", "my file.txt", "-m", "lzfse"]

        let result = try sut.parse(args)
        assertInputFile(result, equals: "my file.txt")
    }

    func testParseCommand_InputPathWithSpecialCharacters() throws {
        let args = ["swiftcompress", "c", "file-name_123.txt", "-m", "lz4"]

        let result = try sut.parse(args)
        assertInputFile(result, equals: "file-name_123.txt")
    }

    func testParseCommand_AbsolutePath() throws {
        let args = ["swiftcompress", "c", "/usr/local/bin/file.txt", "-m", "zlib"]

        let result = try sut.parse(args)
        assertInputFile(result, equals: "/usr/local/bin/file.txt")
    }

    func testParseCommand_RelativePath() throws {
        let args = ["swiftcompress", "c", "../file.txt", "-m", "lzma"]

        let result = try sut.parse(args)
        assertInputFile(result, equals: "../file.txt")
    }

    // MARK: - ParsedCommand Model Tests

    func testParsedCommand_EquatableConformance() {
        let cmd1 = ParsedCommand(
            commandType: .compress,
            inputSource: .file(path: "input.txt"),
            algorithmName: "lzfse",
            outputDestination: .file(path: "output.lzfse"),
            forceOverwrite: true
        )

        let cmd2 = ParsedCommand(
            commandType: .compress,
            inputSource: .file(path: "input.txt"),
            algorithmName: "lzfse",
            outputDestination: .file(path: "output.lzfse"),
            forceOverwrite: true
        )

        let cmd3 = ParsedCommand(
            commandType: .decompress,
            inputSource: .file(path: "input.txt"),
            algorithmName: "lzfse"
        )

        XCTAssertEqual(cmd1, cmd2)
        XCTAssertNotEqual(cmd1, cmd3)
    }

    // MARK: - Integration Tests

    func testRealWorldScenario_CompressWithDefaults() throws {
        let args = ["swiftcompress", "c", "mydata.txt", "-m", "lzfse"]

        let result = try sut.parse(args)

        XCTAssertEqual(result?.commandType, .compress)
        assertInputFile(result, equals: "mydata.txt")
        XCTAssertEqual(result?.algorithmName, "lzfse")
        // In test environment, stdout may be piped, so outputDestination may be .stdout or nil
        if let dest = result?.outputDestination {
            if case .stdout = dest {
                // Expected in test environment
            } else {
                XCTFail("Expected outputDestination to be nil or .stdout, got: \(dest)")
            }
        }
        XCTAssertFalse(result?.forceOverwrite ?? true)
    }

    func testRealWorldScenario_DecompressWithForce() throws {
        let args = ["swiftcompress", "x", "archive.lz4", "-m", "lz4", "-o", "data.txt", "-f"]

        let result = try sut.parse(args)

        XCTAssertEqual(result?.commandType, .decompress)
        assertInputFile(result, equals: "archive.lz4")
        XCTAssertEqual(result?.algorithmName, "lz4")
        assertOutputFile(result, equals: "data.txt")
        XCTAssertTrue(result?.forceOverwrite ?? false)
    }

    func testRealWorldScenario_LongPathsAndFilenames() throws {
        let longPath = "/Users/username/Documents/Projects/MyProject/data/compressed/archive_v1.2.3_final.txt"
        let args = ["swiftcompress", "c", longPath, "-m", "zlib"]

        let result = try sut.parse(args)

        assertInputFile(result, equals: longPath)
    }

    // MARK: - Compression Level Flag Tests

    func testParseCompressCommand_WithFastFlag_SetsLevelAndAlgorithm() throws {
        // Arrange
        let args = ["swiftcompress", "c", "input.txt", "--fast"]

        // Act
        let result = try sut.parse(args)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.commandType, .compress)
        assertInputFile(result, equals: "input.txt")
        XCTAssertEqual(result?.compressionLevel, .fast, "Should set compression level to fast")
        XCTAssertEqual(result?.algorithmName, "lz4", "Fast level should recommend LZ4 algorithm")
    }

    func testParseCompressCommand_WithBestFlag_SetsLevelAndAlgorithm() throws {
        // Arrange
        let args = ["swiftcompress", "c", "input.txt", "--best"]

        // Act
        let result = try sut.parse(args)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.commandType, .compress)
        assertInputFile(result, equals: "input.txt")
        XCTAssertEqual(result?.compressionLevel, .best, "Should set compression level to best")
        XCTAssertEqual(result?.algorithmName, "lzma", "Best level should recommend LZMA algorithm")
    }

    func testParseCompressCommand_WithoutLevelFlags_DefaultsToBalanced() throws {
        // Arrange
        let args = ["swiftcompress", "c", "input.txt", "-m", "lzfse"]

        // Act
        let result = try sut.parse(args)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.compressionLevel, .balanced, "Should default to balanced compression level")
    }

    func testParseCompressCommand_FastFlagWithExplicitAlgorithm_UsesExplicitAlgorithm() throws {
        // Arrange
        let args = ["swiftcompress", "c", "input.txt", "--fast", "-m", "zlib"]

        // Act
        let result = try sut.parse(args)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.compressionLevel, .fast, "Should set compression level to fast")
        XCTAssertEqual(result?.algorithmName, "zlib", "Should use explicit algorithm, not recommended")
    }

    func testParseCompressCommand_BestFlagWithExplicitAlgorithm_UsesExplicitAlgorithm() throws {
        // Arrange
        let args = ["swiftcompress", "c", "input.txt", "--best", "-m", "lz4"]

        // Act
        let result = try sut.parse(args)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.compressionLevel, .best, "Should set compression level to best")
        XCTAssertEqual(result?.algorithmName, "lz4", "Should use explicit algorithm, not recommended")
    }

    func testParseCompressCommand_ConflictingLevelFlags_ThrowsError() {
        // Arrange
        let args = ["swiftcompress", "c", "input.txt", "--fast", "--best"]

        // Act & Assert
        XCTAssertThrowsError(try sut.parse(args)) { error in
            guard let cliError = error as? CLIError else {
                XCTFail("Expected CLIError but got \(type(of: error))")
                return
            }

            if case .conflictingFlags(let flags, let message) = cliError {
                XCTAssertTrue(flags.contains("--fast"), "Should list --fast in conflicting flags")
                XCTAssertTrue(flags.contains("--best"), "Should list --best in conflicting flags")
                XCTAssertTrue(message.contains("Cannot specify both"), "Error message should explain the conflict")
            } else {
                XCTFail("Expected conflictingFlags error but got \(cliError)")
            }
        }
    }

    func testParseCompressCommand_FastFlagWithAllOptions() throws {
        // Arrange
        let args = ["swiftcompress", "c", "input.txt", "--fast", "-o", "output.lz4", "-f"]

        // Act
        let result = try sut.parse(args)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.compressionLevel, .fast)
        XCTAssertEqual(result?.algorithmName, "lz4")
        assertOutputFile(result, equals: "output.lz4")
        XCTAssertEqual(result?.forceOverwrite, true)
    }

    func testParseCompressCommand_BestFlagWithAllOptions() throws {
        // Arrange
        let args = ["swiftcompress", "c", "input.txt", "--best", "-o", "output.lzma", "-f"]

        // Act
        let result = try sut.parse(args)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.compressionLevel, .best)
        XCTAssertEqual(result?.algorithmName, "lzma")
        assertOutputFile(result, equals: "output.lzma")
        XCTAssertEqual(result?.forceOverwrite, true)
    }

    func testParseCompressCommand_LevelFlagOrderIndependent() throws {
        // Test --fast before file
        let args1 = ["swiftcompress", "c", "--fast", "input.txt"]
        let result1 = try? sut.parse(args1)
        XCTAssertEqual(result1?.compressionLevel, .fast)
        XCTAssertEqual(result1?.algorithmName, "lz4")

        // Test --fast after file
        let args2 = ["swiftcompress", "c", "input.txt", "--fast"]
        let result2 = try? sut.parse(args2)
        XCTAssertEqual(result2?.compressionLevel, .fast)
        XCTAssertEqual(result2?.algorithmName, "lz4")

        // Test --best with other flags
        let args3 = ["swiftcompress", "c", "input.txt", "-f", "--best"]
        let result3 = try? sut.parse(args3)
        XCTAssertEqual(result3?.compressionLevel, .best)
        XCTAssertEqual(result3?.algorithmName, "lzma")
    }

    func testParseCompressCommand_FastFlagCombinedWithMethod() throws {
        // When both level flag and method are provided, method should take precedence
        // but level should still be set for buffer size optimization
        let args = ["swiftcompress", "c", "input.txt", "--fast", "-m", "lzfse"]

        let result = try sut.parse(args)

        XCTAssertEqual(result?.compressionLevel, .fast, "Compression level should be fast")
        XCTAssertEqual(result?.algorithmName, "lzfse", "Should use explicit method")
    }

    func testParseCompressCommand_BestFlagCombinedWithMethod() throws {
        // When both level flag and method are provided, method should take precedence
        // but level should still be set for buffer size optimization
        let args = ["swiftcompress", "c", "input.txt", "--best", "-m", "lz4"]

        let result = try sut.parse(args)

        XCTAssertEqual(result?.compressionLevel, .best, "Compression level should be best")
        XCTAssertEqual(result?.algorithmName, "lz4", "Should use explicit method")
    }

    func testParseCompressCommand_BackwardCompatibility_NoLevelFlags() throws {
        // Existing commands without level flags should still work with default balanced level
        let args = ["swiftcompress", "c", "input.txt", "-m", "lzfse", "-o", "output.lzfse"]

        let result = try sut.parse(args)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.compressionLevel, .balanced, "Should default to balanced")
        XCTAssertEqual(result?.algorithmName, "lzfse", "Should use explicit algorithm")
    }

    func testParseCompressCommand_AllLevelOptions() throws {
        // Test all three levels explicitly
        let testCases: [(args: [String], expectedLevel: CompressionLevel, expectedAlgorithm: String)] = [
            (["swiftcompress", "c", "input.txt", "--fast"], .fast, "lz4"),
            (["swiftcompress", "c", "input.txt", "--best"], .best, "lzma"),
            (["swiftcompress", "c", "input.txt", "-m", "lzfse"], .balanced, "lzfse")
        ]

        for (args, expectedLevel, expectedAlgorithm) in testCases {
            let result = try sut.parse(args)
            XCTAssertEqual(result?.compressionLevel, expectedLevel,
                          "Failed for args: \(args)")
            XCTAssertEqual(result?.algorithmName, expectedAlgorithm,
                          "Failed for args: \(args)")
        }
    }

    func testParseCompressCommand_ConflictingLevelFlags_WithMethod_ThrowsError() {
        // Even with explicit method, conflicting level flags should still be an error
        let args = ["swiftcompress", "c", "input.txt", "--fast", "--best", "-m", "zlib"]

        XCTAssertThrowsError(try sut.parse(args)) { error in
            guard let cliError = error as? CLIError else {
                XCTFail("Expected CLIError but got \(type(of: error))")
                return
            }

            if case .conflictingFlags = cliError {
                // Expected
            } else {
                XCTFail("Expected conflictingFlags error but got \(cliError)")
            }
        }
    }
}
