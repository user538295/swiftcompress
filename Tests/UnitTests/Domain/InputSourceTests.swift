import XCTest
@testable import swiftcompress

/// Unit tests for InputSource enum
/// Tests type safety, equality, and enum cases
final class InputSourceTests: XCTestCase {

    // MARK: - Enum Cases Tests

    func testInputSource_FileCase_StoresPath() {
        // Arrange & Act
        let source = InputSource.file(path: "/tmp/test.txt")

        // Assert
        if case .file(let path) = source {
            XCTAssertEqual(path, "/tmp/test.txt")
        } else {
            XCTFail("Expected .file case")
        }
    }

    func testInputSource_StdinCase_HasNoAssociatedValue() {
        // Arrange & Act
        let source = InputSource.stdin

        // Assert
        if case .stdin = source {
            // Expected
        } else {
            XCTFail("Expected .stdin case")
        }
    }

    // MARK: - Equatable Tests

    func testInputSource_FileEquality_SamePath() {
        // Arrange
        let source1 = InputSource.file(path: "/tmp/test.txt")
        let source2 = InputSource.file(path: "/tmp/test.txt")

        // Assert
        XCTAssertEqual(source1, source2)
    }

    func testInputSource_FileInequality_DifferentPaths() {
        // Arrange
        let source1 = InputSource.file(path: "/tmp/test1.txt")
        let source2 = InputSource.file(path: "/tmp/test2.txt")

        // Assert
        XCTAssertNotEqual(source1, source2)
    }

    func testInputSource_StdinEquality() {
        // Arrange
        let source1 = InputSource.stdin
        let source2 = InputSource.stdin

        // Assert
        XCTAssertEqual(source1, source2)
    }

    func testInputSource_FileAndStdin_NotEqual() {
        // Arrange
        let fileSource = InputSource.file(path: "/tmp/test.txt")
        let stdinSource = InputSource.stdin

        // Assert
        XCTAssertNotEqual(fileSource, stdinSource)
    }

    // MARK: - Pattern Matching Tests

    func testInputSource_SwitchStatement_HandlesAllCases() {
        // Arrange
        let sources: [InputSource] = [
            .file(path: "/tmp/test.txt"),
            .stdin
        ]

        // Act & Assert
        for source in sources {
            switch source {
            case .file(let path):
                XCTAssertFalse(path.isEmpty, "File path should not be empty")
            case .stdin:
                // Expected case
                break
            }
        }
    }

    func testInputSource_IfCasePattern_ExtractsPath() {
        // Arrange
        let source = InputSource.file(path: "/usr/local/bin/data.txt")

        // Act
        if case .file(let extractedPath) = source {
            // Assert
            XCTAssertEqual(extractedPath, "/usr/local/bin/data.txt")
        } else {
            XCTFail("Should match .file case")
        }
    }

    // MARK: - Edge Cases

    func testInputSource_FileWithEmptyPath() {
        // Arrange & Act
        let source = InputSource.file(path: "")

        // Assert
        if case .file(let path) = source {
            XCTAssertEqual(path, "")
        } else {
            XCTFail("Expected .file case even with empty path")
        }
    }

    func testInputSource_FileWithSpecialCharacters() {
        // Arrange
        let specialPath = "/tmp/file with spaces & symbols!@#.txt"
        let source = InputSource.file(path: specialPath)

        // Assert
        if case .file(let path) = source {
            XCTAssertEqual(path, specialPath)
        } else {
            XCTFail("Expected .file case")
        }
    }

    func testInputSource_FileWithUnicodePath() {
        // Arrange
        let unicodePath = "/tmp/файл_🎉_test.txt"
        let source = InputSource.file(path: unicodePath)

        // Assert
        if case .file(let path) = source {
            XCTAssertEqual(path, unicodePath)
        } else {
            XCTFail("Expected .file case")
        }
    }

    // MARK: - Usage Pattern Tests

    func testInputSource_UsageInArray() {
        // Arrange
        let sources: [InputSource] = [
            .file(path: "/tmp/file1.txt"),
            .stdin,
            .file(path: "/tmp/file2.txt")
        ]

        // Act
        let fileCount = sources.filter {
            if case .file = $0 { return true }
            return false
        }.count

        let stdinCount = sources.filter {
            if case .stdin = $0 { return true }
            return false
        }.count

        // Assert
        XCTAssertEqual(fileCount, 2)
        XCTAssertEqual(stdinCount, 1)
    }

    func testInputSource_UsageInDictionary() {
        // Arrange
        var sourceMap: [String: InputSource] = [:]
        sourceMap["compress"] = .file(path: "/tmp/input.txt")
        sourceMap["decompress"] = .stdin

        // Assert
        XCTAssertEqual(sourceMap["compress"], .file(path: "/tmp/input.txt"))
        XCTAssertEqual(sourceMap["decompress"], .stdin)
    }
}
