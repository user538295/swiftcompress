import XCTest
@testable import swiftcompress

/// Unit tests for OutputDestination enum
/// Tests type safety, equality, and enum cases
final class OutputDestinationTests: XCTestCase {

    // MARK: - Enum Cases Tests

    func testOutputDestination_FileCase_StoresPath() {
        // Arrange & Act
        let destination = OutputDestination.file(path: "/tmp/output.lzfse")

        // Assert
        if case .file(let path) = destination {
            XCTAssertEqual(path, "/tmp/output.lzfse")
        } else {
            XCTFail("Expected .file case")
        }
    }

    func testOutputDestination_StdoutCase_HasNoAssociatedValue() {
        // Arrange & Act
        let destination = OutputDestination.stdout

        // Assert
        if case .stdout = destination {
            // Expected
        } else {
            XCTFail("Expected .stdout case")
        }
    }

    // MARK: - Equatable Tests

    func testOutputDestination_FileEquality_SamePath() {
        // Arrange
        let dest1 = OutputDestination.file(path: "/tmp/output.lzfse")
        let dest2 = OutputDestination.file(path: "/tmp/output.lzfse")

        // Assert
        XCTAssertEqual(dest1, dest2)
    }

    func testOutputDestination_FileInequality_DifferentPaths() {
        // Arrange
        let dest1 = OutputDestination.file(path: "/tmp/output1.lzfse")
        let dest2 = OutputDestination.file(path: "/tmp/output2.lzfse")

        // Assert
        XCTAssertNotEqual(dest1, dest2)
    }

    func testOutputDestination_StdoutEquality() {
        // Arrange
        let dest1 = OutputDestination.stdout
        let dest2 = OutputDestination.stdout

        // Assert
        XCTAssertEqual(dest1, dest2)
    }

    func testOutputDestination_FileAndStdout_NotEqual() {
        // Arrange
        let fileDest = OutputDestination.file(path: "/tmp/output.lzfse")
        let stdoutDest = OutputDestination.stdout

        // Assert
        XCTAssertNotEqual(fileDest, stdoutDest)
    }

    // MARK: - Pattern Matching Tests

    func testOutputDestination_SwitchStatement_HandlesAllCases() {
        // Arrange
        let destinations: [OutputDestination] = [
            .file(path: "/tmp/output.lzfse"),
            .stdout
        ]

        // Act & Assert
        for destination in destinations {
            switch destination {
            case .file(let path):
                XCTAssertFalse(path.isEmpty, "File path should not be empty")
            case .stdout:
                // Expected case
                break
            }
        }
    }

    func testOutputDestination_IfCasePattern_ExtractsPath() {
        // Arrange
        let destination = OutputDestination.file(path: "/usr/local/bin/compressed.zlib")

        // Act
        if case .file(let extractedPath) = destination {
            // Assert
            XCTAssertEqual(extractedPath, "/usr/local/bin/compressed.zlib")
        } else {
            XCTFail("Should match .file case")
        }
    }

    // MARK: - Edge Cases

    func testOutputDestination_FileWithEmptyPath() {
        // Arrange & Act
        let destination = OutputDestination.file(path: "")

        // Assert
        if case .file(let path) = destination {
            XCTAssertEqual(path, "")
        } else {
            XCTFail("Expected .file case even with empty path")
        }
    }

    func testOutputDestination_FileWithSpecialCharacters() {
        // Arrange
        let specialPath = "/tmp/output with spaces & symbols!@#.lzfse"
        let destination = OutputDestination.file(path: specialPath)

        // Assert
        if case .file(let path) = destination {
            XCTAssertEqual(path, specialPath)
        } else {
            XCTFail("Expected .file case")
        }
    }

    func testOutputDestination_FileWithUnicodePath() {
        // Arrange
        let unicodePath = "/tmp/выход_🚀_compressed.lz4"
        let destination = OutputDestination.file(path: unicodePath)

        // Assert
        if case .file(let path) = destination {
            XCTAssertEqual(path, unicodePath)
        } else {
            XCTFail("Expected .file case")
        }
    }

    // MARK: - Optional Tests

    func testOutputDestination_OptionalNil() {
        // Arrange
        let destination: OutputDestination? = nil

        // Assert
        XCTAssertNil(destination)
    }

    func testOutputDestination_OptionalWithValue() {
        // Arrange
        let destination: OutputDestination? = .file(path: "/tmp/output.lzma")

        // Assert
        XCTAssertNotNil(destination)
        if case .file(let path) = destination! {
            XCTAssertEqual(path, "/tmp/output.lzma")
        } else {
            XCTFail("Expected .file case")
        }
    }

    // MARK: - Usage Pattern Tests

    func testOutputDestination_UsageInArray() {
        // Arrange
        let destinations: [OutputDestination] = [
            .file(path: "/tmp/file1.lzfse"),
            .stdout,
            .file(path: "/tmp/file2.lz4")
        ]

        // Act
        let fileCount = destinations.filter {
            if case .file = $0 { return true }
            return false
        }.count

        let stdoutCount = destinations.filter {
            if case .stdout = $0 { return true }
            return false
        }.count

        // Assert
        XCTAssertEqual(fileCount, 2)
        XCTAssertEqual(stdoutCount, 1)
    }

    func testOutputDestination_UsageInOptionalMapping() {
        // Arrange
        let optionalDest: OutputDestination? = .file(path: "/tmp/output.zlib")

        // Act
        let path = optionalDest.flatMap { destination -> String? in
            if case .file(let p) = destination {
                return p
            }
            return nil
        }

        // Assert
        XCTAssertEqual(path, "/tmp/output.zlib")
    }

    // MARK: - Realistic Scenario Tests

    func testOutputDestination_DefaultResolution() {
        // Arrange - Simulating default output resolution
        let explicitOutput: OutputDestination? = nil
        let isStdoutPiped = false
        let inputPath = "/tmp/input.txt"

        // Act - Simulate resolution logic
        let resolvedOutput: OutputDestination
        if let output = explicitOutput {
            resolvedOutput = output
        } else if isStdoutPiped {
            resolvedOutput = .stdout
        } else {
            resolvedOutput = .file(path: "\(inputPath).lzfse")
        }

        // Assert
        XCTAssertEqual(resolvedOutput, .file(path: "/tmp/input.txt.lzfse"))
    }

    func testOutputDestination_PipedScenario() {
        // Arrange - Simulating piped output
        let explicitOutput: OutputDestination? = nil
        let isStdoutPiped = true

        // Act
        let resolvedOutput: OutputDestination
        if let output = explicitOutput {
            resolvedOutput = output
        } else if isStdoutPiped {
            resolvedOutput = .stdout
        } else {
            resolvedOutput = .file(path: "default.lzfse")
        }

        // Assert
        XCTAssertEqual(resolvedOutput, .stdout)
    }
}
