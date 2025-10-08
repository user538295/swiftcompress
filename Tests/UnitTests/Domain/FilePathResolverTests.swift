import XCTest
@testable import swiftcompress

final class FilePathResolverTests: XCTestCase {

    // MARK: - Properties

    var resolver: FilePathResolver!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        resolver = FilePathResolver()
    }

    override func tearDown() {
        resolver = nil
        super.tearDown()
    }

    // MARK: - Compress Output Path Tests

    func testResolveCompressOutputPath_NoOutputPath_AppendsAlgorithmExtension() {
        // Act
        let result = resolver.resolveCompressOutputPath(
            inputPath: "/path/to/file.txt",
            algorithmName: "lzfse",
            outputPath: nil
        )

        // Assert
        XCTAssertEqual(result, "/path/to/file.txt.lzfse")
    }

    func testResolveCompressOutputPath_WithOutputPath_ReturnsProvidedPath() {
        // Act
        let result = resolver.resolveCompressOutputPath(
            inputPath: "/path/to/file.txt",
            algorithmName: "lzfse",
            outputPath: "/custom/output.dat"
        )

        // Assert
        XCTAssertEqual(result, "/custom/output.dat")
    }

    func testResolveCompressOutputPath_FileWithoutExtension_AppendsAlgorithm() {
        // Act
        let result = resolver.resolveCompressOutputPath(
            inputPath: "/path/to/myfile",
            algorithmName: "lz4",
            outputPath: nil
        )

        // Assert
        XCTAssertEqual(result, "/path/to/myfile.lz4")
    }

    func testResolveCompressOutputPath_FileWithMultipleDots_AppendsCorrectly() {
        // Act
        let result = resolver.resolveCompressOutputPath(
            inputPath: "/path/to/file.tar.gz",
            algorithmName: "lzfse",
            outputPath: nil
        )

        // Assert
        XCTAssertEqual(result, "/path/to/file.tar.gz.lzfse")
    }

    // MARK: - Decompress Output Path Tests

    func testResolveDecompressOutputPath_NoOutputPath_StripsExtension() {
        // Arrange
        let fileExists: (String) -> Bool = { _ in false }

        // Act
        let result = resolver.resolveDecompressOutputPath(
            inputPath: "/path/to/file.txt.lzfse",
            algorithmName: "lzfse",
            outputPath: nil,
            fileExists: fileExists
        )

        // Assert
        XCTAssertEqual(result, "/path/to/file.txt")
    }

    func testResolveDecompressOutputPath_OutputExists_AppendsOutSuffix() {
        // Arrange
        let fileExists: (String) -> Bool = { path in
            return path == "/path/to/file.txt"
        }

        // Act
        let result = resolver.resolveDecompressOutputPath(
            inputPath: "/path/to/file.txt.lzfse",
            algorithmName: "lzfse",
            outputPath: nil,
            fileExists: fileExists
        )

        // Assert
        XCTAssertEqual(result, "/path/to/file.txt.out")
    }

    func testResolveDecompressOutputPath_WithOutputPath_ReturnsProvidedPath() {
        // Arrange
        let fileExists: (String) -> Bool = { _ in false }

        // Act
        let result = resolver.resolveDecompressOutputPath(
            inputPath: "/path/to/file.txt.lzfse",
            algorithmName: "lzfse",
            outputPath: "/custom/decompressed.txt",
            fileExists: fileExists
        )

        // Assert
        XCTAssertEqual(result, "/custom/decompressed.txt")
    }

    func testResolveDecompressOutputPath_ExtensionDoesntMatchAlgorithm_KeepsOriginal() {
        // Arrange
        let fileExists: (String) -> Bool = { _ in false }

        // Act
        let result = resolver.resolveDecompressOutputPath(
            inputPath: "/path/to/file.txt.wrongext",
            algorithmName: "lzfse",
            outputPath: nil,
            fileExists: fileExists
        )

        // Assert
        XCTAssertEqual(result, "/path/to/file.txt.wrongext")
    }

    // MARK: - Algorithm Inference Tests

    func testInferAlgorithm_LZFSEExtension_ReturnsLZFSE() {
        // Act
        let result = resolver.inferAlgorithm(from: "/path/to/file.txt.lzfse")

        // Assert
        XCTAssertEqual(result, "lzfse")
    }

    func testInferAlgorithm_LZ4Extension_ReturnsLZ4() {
        // Act
        let result = resolver.inferAlgorithm(from: "/path/to/file.dat.lz4")

        // Assert
        XCTAssertEqual(result, "lz4")
    }

    func testInferAlgorithm_ZlibExtension_ReturnsZlib() {
        // Act
        let result = resolver.inferAlgorithm(from: "/path/to/file.zlib")

        // Assert
        XCTAssertEqual(result, "zlib")
    }

    func testInferAlgorithm_LZMAExtension_ReturnsLZMA() {
        // Act
        let result = resolver.inferAlgorithm(from: "/path/to/file.lzma")

        // Assert
        XCTAssertEqual(result, "lzma")
    }

    func testInferAlgorithm_UnknownExtension_ReturnsNil() {
        // Act
        let result = resolver.inferAlgorithm(from: "/path/to/file.txt")

        // Assert
        XCTAssertNil(result)
    }

    func testInferAlgorithm_NoExtension_ReturnsNil() {
        // Act
        let result = resolver.inferAlgorithm(from: "/path/to/myfile")

        // Assert
        XCTAssertNil(result)
    }

    func testInferAlgorithm_CaseInsensitive_ReturnsLowercase() {
        // Act
        let result = resolver.inferAlgorithm(from: "/path/to/file.LZFSE")

        // Assert
        XCTAssertEqual(result, "lzfse")
    }

    // MARK: - Edge Cases

    func testResolveDecompressOutputPath_HiddenFile_HandlesCorrectly() {
        // Arrange
        let fileExists: (String) -> Bool = { _ in false }

        // Act
        let result = resolver.resolveDecompressOutputPath(
            inputPath: "/path/to/.hidden.lz4",
            algorithmName: "lz4",
            outputPath: nil,
            fileExists: fileExists
        )

        // Assert
        XCTAssertEqual(result, "/path/to/.hidden")
    }

    func testResolveCompressOutputPath_HiddenFile_AppendsExtension() {
        // Act
        let result = resolver.resolveCompressOutputPath(
            inputPath: ".bashrc",
            algorithmName: "lzfse",
            outputPath: nil
        )

        // Assert
        XCTAssertEqual(result, ".bashrc.lzfse")
    }
}
