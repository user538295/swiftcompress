import XCTest
@testable import swiftcompress

final class ValidationRulesTests: XCTestCase {

    // MARK: - Properties

    var validationRules: ValidationRules!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        validationRules = ValidationRules()
    }

    override func tearDown() {
        validationRules = nil
        super.tearDown()
    }

    // MARK: - Input Path Validation Tests

    func testValidateInputPath_ValidPath_DoesNotThrow() {
        // Act & Assert
        XCTAssertNoThrow(try validationRules.validateInputPath("/path/to/file.txt"))
    }

    func testValidateInputPath_EmptyPath_ThrowsError() {
        // Act & Assert
        XCTAssertThrowsError(try validationRules.validateInputPath("")) { error in
            guard case DomainError.invalidInputPath(let path, let reason) = error else {
                XCTFail("Expected invalidInputPath error")
                return
            }
            XCTAssertEqual(path, "")
            XCTAssertEqual(reason, "Path is empty")
        }
    }

    func testValidateInputPath_NullByte_ThrowsError() {
        // Arrange
        let pathWithNull = "/path/to/file\0.txt"

        // Act & Assert
        XCTAssertThrowsError(try validationRules.validateInputPath(pathWithNull)) { error in
            guard case DomainError.invalidInputPath = error else {
                XCTFail("Expected invalidInputPath error")
                return
            }
        }
    }

    func testValidateInputPath_PathTraversal_ThrowsError() {
        // Act & Assert
        XCTAssertThrowsError(try validationRules.validateInputPath("../etc/passwd")) { error in
            guard case DomainError.pathTraversalAttempt = error else {
                XCTFail("Expected pathTraversalAttempt error")
                return
            }
        }
    }

    func testValidateInputPath_RelativePath_DoesNotThrow() {
        // Act & Assert
        XCTAssertNoThrow(try validationRules.validateInputPath("file.txt"))
        XCTAssertNoThrow(try validationRules.validateInputPath("dir/file.txt"))
    }

    func testValidateInputPath_PathWithSpaces_DoesNotThrow() {
        // Act & Assert
        XCTAssertNoThrow(try validationRules.validateInputPath("/path/to/my file.txt"))
    }

    // MARK: - Output Path Validation Tests

    func testValidateOutputPath_ValidPath_DoesNotThrow() {
        // Act & Assert
        XCTAssertNoThrow(try validationRules.validateOutputPath("/path/to/output.txt", inputPath: "/path/to/input.txt"))
    }

    func testValidateOutputPath_EmptyPath_ThrowsError() {
        // Act & Assert
        XCTAssertThrowsError(try validationRules.validateOutputPath("", inputPath: "/path/to/input.txt")) { error in
            guard case DomainError.invalidOutputPath(let path, let reason) = error else {
                XCTFail("Expected invalidOutputPath error")
                return
            }
            XCTAssertEqual(path, "")
            XCTAssertEqual(reason, "Path is empty")
        }
    }

    func testValidateOutputPath_SameAsInput_ThrowsError() {
        // Act & Assert
        XCTAssertThrowsError(try validationRules.validateOutputPath("/path/to/file.txt", inputPath: "/path/to/file.txt")) { error in
            guard case DomainError.inputOutputSame = error else {
                XCTFail("Expected inputOutputSame error")
                return
            }
        }
    }

    func testValidateOutputPath_SameAsInputNormalized_ThrowsError() {
        // Act & Assert
        XCTAssertThrowsError(try validationRules.validateOutputPath("/path/to/./file.txt", inputPath: "/path/to/file.txt")) { error in
            guard case DomainError.inputOutputSame = error else {
                XCTFail("Expected inputOutputSame error")
                return
            }
        }
    }

    func testValidateOutputPath_PathTraversal_ThrowsError() {
        // Act & Assert
        XCTAssertThrowsError(try validationRules.validateOutputPath("../../etc/passwd", inputPath: "/path/to/input.txt")) { error in
            guard case DomainError.pathTraversalAttempt = error else {
                XCTFail("Expected pathTraversalAttempt error")
                return
            }
        }
    }

    func testValidateOutputPath_NullByte_ThrowsError() {
        // Arrange
        let pathWithNull = "/path/to/file\0.txt"

        // Act & Assert
        XCTAssertThrowsError(try validationRules.validateOutputPath(pathWithNull, inputPath: "/path/to/input.txt")) { error in
            guard case DomainError.invalidOutputPath = error else {
                XCTFail("Expected invalidOutputPath error")
                return
            }
        }
    }

    // MARK: - Algorithm Validation Tests

    func testValidateAlgorithmName_ValidAlgorithm_DoesNotThrow() {
        // Arrange
        let supportedAlgorithms = ["lzfse", "lz4", "zlib", "lzma"]

        // Act & Assert
        XCTAssertNoThrow(try validationRules.validateAlgorithmName("lzfse", supportedAlgorithms: supportedAlgorithms))
    }

    func testValidateAlgorithmName_CaseInsensitive_DoesNotThrow() {
        // Arrange
        let supportedAlgorithms = ["lzfse", "lz4", "zlib", "lzma"]

        // Act & Assert
        XCTAssertNoThrow(try validationRules.validateAlgorithmName("LZFSE", supportedAlgorithms: supportedAlgorithms))
        XCTAssertNoThrow(try validationRules.validateAlgorithmName("LzFsE", supportedAlgorithms: supportedAlgorithms))
    }

    func testValidateAlgorithmName_EmptyName_ThrowsError() {
        // Arrange
        let supportedAlgorithms = ["lzfse", "lz4", "zlib", "lzma"]

        // Act & Assert
        XCTAssertThrowsError(try validationRules.validateAlgorithmName("", supportedAlgorithms: supportedAlgorithms)) { error in
            guard case DomainError.invalidAlgorithmName = error else {
                XCTFail("Expected invalidAlgorithmName error")
                return
            }
        }
    }

    func testValidateAlgorithmName_UnsupportedAlgorithm_ThrowsError() {
        // Arrange
        let supportedAlgorithms = ["lzfse", "lz4", "zlib", "lzma"]

        // Act & Assert
        XCTAssertThrowsError(try validationRules.validateAlgorithmName("gzip", supportedAlgorithms: supportedAlgorithms)) { error in
            guard case DomainError.invalidAlgorithmName(let name, let supported) = error else {
                XCTFail("Expected invalidAlgorithmName error")
                return
            }
            XCTAssertEqual(name, "gzip")
            XCTAssertEqual(supported, supportedAlgorithms)
        }
    }

    // MARK: - File Size Validation Tests

    func testValidateFileSize_ValidSize_DoesNotThrow() {
        // Act & Assert
        XCTAssertNoThrow(try validationRules.validateFileSize(1024))
    }

    func testValidateFileSize_ZeroSize_ThrowsError() {
        // Act & Assert
        XCTAssertThrowsError(try validationRules.validateFileSize(0)) { error in
            guard case DomainError.inputFileEmpty = error else {
                XCTFail("Expected inputFileEmpty error")
                return
            }
        }
    }

    func testValidateFileSize_ExceedsLimit_ThrowsError() {
        // Arrange
        let size: Int64 = 1000
        let limit: Int64 = 100

        // Act & Assert
        XCTAssertThrowsError(try validationRules.validateFileSize(size, limit: limit)) { error in
            guard case DomainError.fileTooLarge(_, let fileSize, let fileLimit) = error else {
                XCTFail("Expected fileTooLarge error")
                return
            }
            XCTAssertEqual(fileSize, size)
            XCTAssertEqual(fileLimit, limit)
        }
    }
}
