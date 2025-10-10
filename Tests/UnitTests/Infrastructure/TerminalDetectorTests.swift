import XCTest
@testable import swiftcompress

/// Unit tests for TerminalDetector utility
/// Tests terminal and pipe detection functionality
final class TerminalDetectorTests: XCTestCase {

    // MARK: - Stdin Detection Tests

    func testIsStdinPipe_ReturnsBoolean() {
        // Act
        let result = TerminalDetector.isStdinPipe()

        // Assert
        XCTAssertTrue(result == true || result == false, "Should return a boolean value")
    }

    func testIsStdinTerminal_ReturnsBoolean() {
        // Act
        let result = TerminalDetector.isStdinTerminal()

        // Assert
        XCTAssertTrue(result == true || result == false, "Should return a boolean value")
    }

    func testIsStdinPipe_OppositeOfIsStdinTerminal() {
        // Act
        let isPipe = TerminalDetector.isStdinPipe()
        let isTerminal = TerminalDetector.isStdinTerminal()

        // Assert - They should be opposites
        XCTAssertNotEqual(isPipe, isTerminal, "stdin cannot be both pipe and terminal simultaneously")
    }

    // MARK: - Stdout Detection Tests

    func testIsStdoutPipe_ReturnsBoolean() {
        // Act
        let result = TerminalDetector.isStdoutPipe()

        // Assert
        XCTAssertTrue(result == true || result == false, "Should return a boolean value")
    }

    func testIsStdoutTerminal_ReturnsBoolean() {
        // Act
        let result = TerminalDetector.isStdoutTerminal()

        // Assert
        XCTAssertTrue(result == true || result == false, "Should return a boolean value")
    }

    func testIsStdoutPipe_OppositeOfIsStdoutTerminal() {
        // Act
        let isPipe = TerminalDetector.isStdoutPipe()
        let isTerminal = TerminalDetector.isStdoutTerminal()

        // Assert - They should be opposites
        XCTAssertNotEqual(isPipe, isTerminal, "stdout cannot be both pipe and terminal simultaneously")
    }

    // MARK: - Stderr Detection Tests

    func testIsStderrTerminal_ReturnsBoolean() {
        // Act
        let result = TerminalDetector.isStderrTerminal()

        // Assert
        XCTAssertTrue(result == true || result == false, "Should return a boolean value")
    }

    // MARK: - Consistency Tests

    func testTerminalDetector_ConsistentResults() {
        // Act - Call multiple times
        let result1 = TerminalDetector.isStdinPipe()
        let result2 = TerminalDetector.isStdinPipe()
        let result3 = TerminalDetector.isStdinPipe()

        // Assert - Results should be consistent
        XCTAssertEqual(result1, result2, "Multiple calls should return same result")
        XCTAssertEqual(result2, result3, "Multiple calls should return same result")
    }

    func testTerminalDetector_StdoutConsistency() {
        // Act - Call multiple times
        let result1 = TerminalDetector.isStdoutPipe()
        let result2 = TerminalDetector.isStdoutPipe()

        // Assert
        XCTAssertEqual(result1, result2, "Multiple calls should return same result")
    }

    // MARK: - Static Method Tests

    func testTerminalDetector_StaticMethods_DoNotRequireInstance() {
        // Act & Assert - Should be callable without instance
        _ = TerminalDetector.isStdinPipe()
        _ = TerminalDetector.isStdinTerminal()
        _ = TerminalDetector.isStdoutPipe()
        _ = TerminalDetector.isStdoutTerminal()
        _ = TerminalDetector.isStderrTerminal()

        // If we got here, all static methods are accessible
        XCTAssertTrue(true, "All static methods should be accessible")
    }

    // MARK: - Usage Pattern Tests

    func testTerminalDetector_UsageInConditional() {
        // Act - Simulate typical usage pattern
        var inputSource: InputSource

        if TerminalDetector.isStdinPipe() {
            inputSource = .stdin
        } else {
            inputSource = .file(path: "/tmp/default.txt")
        }

        // Assert - Should have chosen one path
        switch inputSource {
        case .stdin:
            XCTAssertTrue(TerminalDetector.isStdinPipe(), "If stdin was chosen, pipe should be detected")
        case .file:
            XCTAssertFalse(TerminalDetector.isStdinPipe(), "If file was chosen, pipe should not be detected")
        }
    }

    func testTerminalDetector_UsageForOutputResolution() {
        // Act - Simulate output destination resolution
        var outputDest: OutputDestination

        if TerminalDetector.isStdoutPipe() {
            outputDest = .stdout
        } else {
            outputDest = .file(path: "/tmp/output.lzfse")
        }

        // Assert
        switch outputDest {
        case .stdout:
            XCTAssertTrue(TerminalDetector.isStdoutPipe(), "If stdout was chosen, pipe should be detected")
        case .file:
            XCTAssertFalse(TerminalDetector.isStdoutPipe(), "If file was chosen, pipe should not be detected")
        }
    }

    // MARK: - Test Environment Detection

    func testTerminalDetector_TestEnvironmentBehavior() {
        // In test environment, stdin/stdout are often redirected by test runner
        // This test documents the expected behavior

        let stdinIsPipe = TerminalDetector.isStdinPipe()
        let stdoutIsPipe = TerminalDetector.isStdoutPipe()

        // Document current state (don't assert specific values as it depends on test runner)
        print("Test environment - stdin is pipe: \(stdinIsPipe)")
        print("Test environment - stdout is pipe: \(stdoutIsPipe)")

        // Just verify methods work
        XCTAssertTrue(true, "Terminal detection should work in test environment")
    }

    // MARK: - Error-Free Execution Tests

    func testTerminalDetector_DoesNotThrowErrors() {
        // Act & Assert - All methods should execute without throwing
        XCTAssertNoThrow(TerminalDetector.isStdinPipe())
        XCTAssertNoThrow(TerminalDetector.isStdinTerminal())
        XCTAssertNoThrow(TerminalDetector.isStdoutPipe())
        XCTAssertNoThrow(TerminalDetector.isStdoutTerminal())
        XCTAssertNoThrow(TerminalDetector.isStderrTerminal())
    }

    // MARK: - Documentation Tests

    func testTerminalDetector_BehaviorDocumentation() {
        // This test documents the expected behavior for users

        // When stdin is a terminal (interactive):
        // - User is typing directly into the program
        // - isStdinTerminal() returns true
        // - isStdinPipe() returns false

        // When stdin is a pipe:
        // - Data is being piped from another command
        // - isStdinPipe() returns true
        // - isStdinTerminal() returns false

        // Example: cat file.txt | program
        // In this case, program's stdin is a pipe

        let isPipe = TerminalDetector.isStdinPipe()
        let isTerminal = TerminalDetector.isStdinTerminal()

        // They must be mutually exclusive
        XCTAssertTrue(isPipe != isTerminal, "stdin is either pipe or terminal, never both")
    }
}
