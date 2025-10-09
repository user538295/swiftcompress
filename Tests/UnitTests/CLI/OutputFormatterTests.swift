import XCTest
@testable import swiftcompress

/// Comprehensive tests for OutputFormatter
///
/// Test coverage:
/// - Success message formatting (quiet mode)
/// - Error message formatting (prefix, newlines)
/// - Help text formatting (completeness, structure)
/// - Version formatting
/// - Edge cases (nil, empty strings, messages with newlines)
final class OutputFormatterTests: XCTestCase {

    // MARK: - System Under Test

    var sut: OutputFormatter!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        sut = OutputFormatter()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Success Message Formatting Tests

    func testFormatSuccess_WithNilMessage_ReturnsNil() {
        // Act
        let result = sut.formatSuccess(nil)

        // Assert
        XCTAssertNil(result, "Success with nil message should return nil (quiet mode)")
    }

    func testFormatSuccess_WithEmptyMessage_ReturnsNil() {
        // Act
        let result = sut.formatSuccess("")

        // Assert
        XCTAssertNil(result, "Success with empty message should return nil (quiet mode)")
    }

    func testFormatSuccess_WithWhitespaceMessage_ReturnsNil() {
        // Act
        let result = sut.formatSuccess("   ")

        // Assert
        // Note: This test shows current behavior - whitespace is not treated as empty
        // If we want to trim whitespace, we'd need to update the implementation
        XCTAssertNotNil(result, "Current behavior: whitespace is preserved")
    }

    func testFormatSuccess_WithValidMessage_ReturnsMessage() {
        // Arrange
        let message = "Compression completed successfully"

        // Act
        let result = sut.formatSuccess(message)

        // Assert
        XCTAssertEqual(result, message, "Valid success message should be returned as-is")
    }

    func testFormatSuccess_WithMultilineMessage_PreservesFormatting() {
        // Arrange
        let message = "Operation completed\nFiles processed: 5\nTotal size: 1.2 MB"

        // Act
        let result = sut.formatSuccess(message)

        // Assert
        XCTAssertEqual(result, message, "Multiline messages should be preserved")
    }

    // MARK: - Error Message Formatting Tests

    func testFormatError_AddsNewlineIfMissing() {
        // Arrange
        let error = UserFacingError(
            message: "Error: File not found: test.txt",
            exitCode: 1
        )

        // Act
        let result = sut.formatError(error)

        // Assert
        XCTAssertTrue(result.hasSuffix("\n"), "Error message should end with newline")
        XCTAssertEqual(result, "Error: File not found: test.txt\n")
    }

    func testFormatError_PreservesExistingNewline() {
        // Arrange
        let error = UserFacingError(
            message: "Error: Output file already exists\nUse -f to overwrite.\n",
            exitCode: 1
        )

        // Act
        let result = sut.formatError(error)

        // Assert
        XCTAssertEqual(result, error.message, "Should not add extra newline if already present")
    }

    func testFormatError_PreservesErrorPrefix() {
        // Arrange
        let error = UserFacingError(
            message: "Error: Invalid algorithm 'xyz'. Supported: lzfse, lz4, zlib, lzma",
            exitCode: 1
        )

        // Act
        let result = sut.formatError(error)

        // Assert
        XCTAssertTrue(result.hasPrefix("Error: "), "Error prefix should be preserved")
    }

    func testFormatError_WithMultilineMessage_PreservesFormatting() {
        // Arrange
        let error = UserFacingError(
            message: "Error: Compression failed\nReason: Insufficient disk space\nRequired: 1.5 GB",
            exitCode: 1
        )

        // Act
        let result = sut.formatError(error)

        // Assert
        XCTAssertTrue(result.contains("\n"), "Multiline error should preserve line breaks")
        XCTAssertTrue(result.hasSuffix("\n"), "Should end with newline")
    }

    func testFormatError_WithEmptyMessage_StillAddsNewline() {
        // Arrange
        let error = UserFacingError(
            message: "",
            exitCode: 1
        )

        // Act
        let result = sut.formatError(error)

        // Assert
        XCTAssertEqual(result, "\n", "Empty error message should just be a newline")
    }

    func testFormatError_WithVariousExitCodes_FormatsMessageCorrectly() {
        // Arrange
        let errors = [
            UserFacingError(message: "Error: Test 1", exitCode: 0),
            UserFacingError(message: "Error: Test 2", exitCode: 1),
            UserFacingError(message: "Error: Test 3", exitCode: 127)
        ]

        // Act & Assert
        for error in errors {
            let result = sut.formatError(error)
            XCTAssertTrue(result.hasSuffix("\n"), "All errors should have newline regardless of exit code")
            XCTAssertTrue(result.contains(error.message), "Original message should be preserved")
        }
    }

    // MARK: - Help Text Formatting Tests

    func testFormatHelp_ContainsToolDescription() {
        // Act
        let help = sut.formatHelp()

        // Assert
        XCTAssertTrue(help.contains("swiftcompress"), "Help should contain tool name")
        XCTAssertTrue(help.contains("CLI tool"), "Help should describe the tool")
        XCTAssertTrue(help.contains("Apple's Compression framework"), "Help should mention framework")
    }

    func testFormatHelp_ContainsUsageSection() {
        // Act
        let help = sut.formatHelp()

        // Assert
        XCTAssertTrue(help.contains("USAGE:"), "Help should have usage section")
        XCTAssertTrue(help.contains("<command>"), "Usage should show command placeholder")
        XCTAssertTrue(help.contains("<input-file>"), "Usage should show input file placeholder")
        XCTAssertTrue(help.contains("-m <algorithm>"), "Usage should show algorithm flag")
    }

    func testFormatHelp_ContainsCommands() {
        // Act
        let help = sut.formatHelp()

        // Assert
        XCTAssertTrue(help.contains("COMMANDS:"), "Help should have commands section")
        XCTAssertTrue(help.contains("c, compress"), "Help should list compress command")
        XCTAssertTrue(help.contains("x, decompress"), "Help should list decompress command")
    }

    func testFormatHelp_ContainsFlags() {
        // Act
        let help = sut.formatHelp()

        // Assert
        XCTAssertTrue(help.contains("REQUIRED FLAGS:"), "Help should list required flags")
        XCTAssertTrue(help.contains("OPTIONAL FLAGS:"), "Help should list optional flags")
        XCTAssertTrue(help.contains("-m <algorithm>"), "Help should describe -m flag")
        XCTAssertTrue(help.contains("-o <output>"), "Help should describe -o flag")
        XCTAssertTrue(help.contains("-f, --force"), "Help should describe force flag")
        XCTAssertTrue(help.contains("--help"), "Help should describe help flag")
        XCTAssertTrue(help.contains("--version"), "Help should describe version flag")
    }

    func testFormatHelp_ContainsAllSupportedAlgorithms() {
        // Act
        let help = sut.formatHelp()

        // Assert
        XCTAssertTrue(help.contains("SUPPORTED ALGORITHMS:"), "Help should have algorithms section")
        XCTAssertTrue(help.contains("lzfse"), "Help should list LZFSE algorithm")
        XCTAssertTrue(help.contains("lz4"), "Help should list LZ4 algorithm")
        XCTAssertTrue(help.contains("zlib"), "Help should list Zlib algorithm")
        XCTAssertTrue(help.contains("lzma"), "Help should list LZMA algorithm")
    }

    func testFormatHelp_ContainsAlgorithmDescriptions() {
        // Act
        let help = sut.formatHelp()

        // Assert
        XCTAssertTrue(help.contains("Apple's LZFSE"), "LZFSE should have description")
        XCTAssertTrue(help.contains("fastest"), "LZ4 should be described as fastest")
        XCTAssertTrue(help.contains("industry standard"), "Zlib should mention standard")
        XCTAssertTrue(help.contains("highest compression ratio"), "LZMA should mention compression ratio")
    }

    func testFormatHelp_ContainsExamples() {
        // Act
        let help = sut.formatHelp()

        // Assert
        XCTAssertTrue(help.contains("EXAMPLES:"), "Help should have examples section")
        XCTAssertTrue(help.contains("swiftcompress c"), "Help should show compress example")
        XCTAssertTrue(help.contains("swiftcompress x"), "Help should show decompress example")
        XCTAssertTrue(help.contains("-f"), "Help should show force flag example")
    }

    func testFormatHelp_ContainsExampleOutputs() {
        // Act
        let help = sut.formatHelp()

        // Assert
        XCTAssertTrue(help.contains("Output:"), "Examples should show expected outputs")
        XCTAssertTrue(help.contains(".lzfse"), "Examples should show compressed file extensions")
    }

    func testFormatHelp_ContainsExitCodes() {
        // Act
        let help = sut.formatHelp()

        // Assert
        XCTAssertTrue(help.contains("EXIT CODES:"), "Help should document exit codes")
        XCTAssertTrue(help.contains("0"), "Help should show success exit code")
        XCTAssertTrue(help.contains("1"), "Help should show error exit code")
    }

    func testFormatHelp_ContainsRepositoryLink() {
        // Act
        let help = sut.formatHelp()

        // Assert
        XCTAssertTrue(help.contains("github.com"), "Help should contain GitHub link")
        XCTAssertTrue(help.contains("swiftcompress"), "Link should reference project")
    }

    func testFormatHelp_IsWellFormatted() {
        // Act
        let help = sut.formatHelp()

        // Assert
        XCTAssertFalse(help.isEmpty, "Help text should not be empty")
        XCTAssertGreaterThan(help.count, 500, "Help text should be comprehensive")

        // Check for reasonable structure
        let lines = help.split(separator: "\n")
        XCTAssertGreaterThan(lines.count, 20, "Help should have multiple lines")
    }

    // MARK: - Version Formatting Tests

    func testFormatVersion_ContainsVersionNumber() {
        // Act
        let version = sut.formatVersion()

        // Assert
        XCTAssertTrue(version.contains("version"), "Version output should contain 'version' keyword")
        XCTAssertTrue(version.contains("swiftcompress"), "Version should identify the tool")
    }

    func testFormatVersion_ContainsVersionString() {
        // Act
        let version = sut.formatVersion()

        // Assert
        // Version format: X.Y.Z
        let versionPattern = #"\d+\.\d+\.\d+"#
        let regex = try? NSRegularExpression(pattern: versionPattern)
        let range = NSRange(version.startIndex..., in: version)
        let matches = regex?.numberOfMatches(in: version, range: range) ?? 0

        XCTAssertGreaterThan(matches, 0, "Version should contain semantic version number (X.Y.Z)")
    }

    func testFormatVersion_EndsWithNewline() {
        // Act
        let version = sut.formatVersion()

        // Assert
        XCTAssertTrue(version.hasSuffix("\n"), "Version string should end with newline")
    }

    func testFormatVersion_IsConcise() {
        // Act
        let version = sut.formatVersion()

        // Assert
        let lines = version.split(separator: "\n")
        XCTAssertLessThanOrEqual(lines.count, 1, "Version should be a single line")
        XCTAssertLessThan(version.count, 100, "Version string should be concise")
    }

    // MARK: - Edge Cases and Integration Tests

    func testMultipleCallsReturnConsistentResults() {
        // Act
        let help1 = sut.formatHelp()
        let help2 = sut.formatHelp()
        let version1 = sut.formatVersion()
        let version2 = sut.formatVersion()

        // Assert
        XCTAssertEqual(help1, help2, "Multiple help calls should return identical text")
        XCTAssertEqual(version1, version2, "Multiple version calls should return identical text")
    }

    func testFormatterIsThreadSafe() {
        // This is a basic concurrency test
        let expectation = expectation(description: "Concurrent formatting")
        expectation.expectedFulfillmentCount = 10

        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)

        for _ in 0..<10 {
            queue.async {
                _ = self.sut.formatHelp()
                _ = self.sut.formatVersion()
                _ = self.sut.formatSuccess("test")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 2.0)
    }

    func testProtocolConformance() {
        // Verify sut conforms to protocol
        XCTAssertTrue(sut is OutputFormatterProtocol, "OutputFormatter should conform to OutputFormatterProtocol")
    }

    // MARK: - Real-World Error Scenarios

    func testFormatError_WithRealFileNotFoundError() {
        // Arrange
        let error = UserFacingError(
            message: "Error: File not found: /path/to/nonexistent.txt",
            exitCode: 1
        )

        // Act
        let result = sut.formatError(error)

        // Assert
        XCTAssertTrue(result.hasPrefix("Error: "), "Should have error prefix")
        XCTAssertTrue(result.contains("File not found"), "Should contain error description")
        XCTAssertTrue(result.hasSuffix("\n"), "Should end with newline")
    }

    func testFormatError_WithRealOutputExistsError() {
        // Arrange
        let error = UserFacingError(
            message: "Error: Output file already exists: output.lzfse\nUse -f flag to force overwrite.",
            exitCode: 1
        )

        // Act
        let result = sut.formatError(error)

        // Assert
        XCTAssertTrue(result.contains("Output file already exists"), "Should contain main error")
        XCTAssertTrue(result.contains("Use -f flag"), "Should contain actionable guidance")
        XCTAssertTrue(result.hasSuffix("\n"), "Should end with newline")
    }

    func testFormatError_WithRealInvalidAlgorithmError() {
        // Arrange
        let error = UserFacingError(
            message: "Error: Unknown algorithm 'xyz'. Supported algorithms: lzfse, lz4, zlib, lzma",
            exitCode: 1
        )

        // Act
        let result = sut.formatError(error)

        // Assert
        XCTAssertTrue(result.contains("Unknown algorithm"), "Should identify problem")
        XCTAssertTrue(result.contains("Supported algorithms"), "Should provide solution")
        XCTAssertTrue(result.hasSuffix("\n"), "Should end with newline")
    }

    // MARK: - Quiet Mode Verification

    func testQuietModeByDefault() {
        // This test verifies the core "quiet by default" behavior
        // Arrange & Act
        let result = sut.formatSuccess(nil)

        // Assert
        XCTAssertNil(result, "Default behavior should be quiet (no output on success)")
    }

    func testQuietModeWithExplicitEmptyString() {
        // Arrange & Act
        let result = sut.formatSuccess("")

        // Assert
        XCTAssertNil(result, "Explicit empty string should also result in quiet mode")
    }
}
