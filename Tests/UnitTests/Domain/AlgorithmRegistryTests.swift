import XCTest
@testable import swiftcompress
import TestHelpers

final class AlgorithmRegistryTests: XCTestCase {

    // MARK: - Properties

    var registry: AlgorithmRegistry!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        registry = AlgorithmRegistry()
    }

    override func tearDown() {
        registry = nil
        super.tearDown()
    }

    // MARK: - Registration Tests

    func testRegister_Algorithm_StoresInRegistry() {
        // Arrange
        let algorithm = MockCompressionAlgorithm(name: "lzfse")

        // Act
        registry.register(algorithm)

        // Assert
        XCTAssertNotNil(registry.algorithm(named: "lzfse"))
    }

    func testRegister_MultipleAlgorithms_AllStored() {
        // Arrange
        let lzfse = MockCompressionAlgorithm(name: "lzfse")
        let lz4 = MockCompressionAlgorithm(name: "lz4")
        let zlib = MockCompressionAlgorithm(name: "zlib")

        // Act
        registry.register(lzfse)
        registry.register(lz4)
        registry.register(zlib)

        // Assert
        XCTAssertNotNil(registry.algorithm(named: "lzfse"))
        XCTAssertNotNil(registry.algorithm(named: "lz4"))
        XCTAssertNotNil(registry.algorithm(named: "zlib"))
    }

    // MARK: - Lookup Tests

    func testAlgorithm_RegisteredName_ReturnsAlgorithm() {
        // Arrange
        let algorithm = MockCompressionAlgorithm(name: "lzfse")
        registry.register(algorithm)

        // Act
        let result = registry.algorithm(named: "lzfse")

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "lzfse")
    }

    func testAlgorithm_UnregisteredName_ReturnsNil() {
        // Act
        let result = registry.algorithm(named: "unknown")

        // Assert
        XCTAssertNil(result)
    }

    func testAlgorithm_CaseInsensitive_ReturnsAlgorithm() {
        // Arrange
        let algorithm = MockCompressionAlgorithm(name: "lzfse")
        registry.register(algorithm)

        // Act & Assert
        XCTAssertNotNil(registry.algorithm(named: "LZFSE"))
        XCTAssertNotNil(registry.algorithm(named: "LzFsE"))
        XCTAssertNotNil(registry.algorithm(named: "lzfse"))
    }

    // MARK: - Supported Algorithms Tests

    func testSupportedAlgorithms_EmptyRegistry_ReturnsEmptyArray() {
        // Act
        let result = registry.supportedAlgorithms

        // Assert
        XCTAssertTrue(result.isEmpty)
    }

    func testSupportedAlgorithms_WithAlgorithms_ReturnsAllNames() {
        // Arrange
        registry.register(MockCompressionAlgorithm(name: "lzfse"))
        registry.register(MockCompressionAlgorithm(name: "lz4"))
        registry.register(MockCompressionAlgorithm(name: "zlib"))

        // Act
        let result = registry.supportedAlgorithms

        // Assert
        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.contains("lzfse"))
        XCTAssertTrue(result.contains("lz4"))
        XCTAssertTrue(result.contains("zlib"))
    }

    func testSupportedAlgorithms_ReturnsSorted() {
        // Arrange
        registry.register(MockCompressionAlgorithm(name: "zlib"))
        registry.register(MockCompressionAlgorithm(name: "lzfse"))
        registry.register(MockCompressionAlgorithm(name: "lz4"))

        // Act
        let result = registry.supportedAlgorithms

        // Assert
        XCTAssertEqual(result, ["lz4", "lzfse", "zlib"])
    }

    // MARK: - IsRegistered Tests

    func testIsRegistered_RegisteredAlgorithm_ReturnsTrue() {
        // Arrange
        let algorithm = MockCompressionAlgorithm(name: "lzfse")
        registry.register(algorithm)

        // Act
        let result = registry.isRegistered("lzfse")

        // Assert
        XCTAssertTrue(result)
    }

    func testIsRegistered_UnregisteredAlgorithm_ReturnsFalse() {
        // Act
        let result = registry.isRegistered("unknown")

        // Assert
        XCTAssertFalse(result)
    }

    func testIsRegistered_CaseInsensitive_ReturnsTrue() {
        // Arrange
        let algorithm = MockCompressionAlgorithm(name: "lzfse")
        registry.register(algorithm)

        // Act & Assert
        XCTAssertTrue(registry.isRegistered("LZFSE"))
        XCTAssertTrue(registry.isRegistered("LzFsE"))
        XCTAssertTrue(registry.isRegistered("lzfse"))
    }

    // MARK: - Duplicate Registration Tests

    func testRegister_DuplicateName_OverwritesPrevious() {
        // Arrange
        let algorithm1 = MockCompressionAlgorithm(name: "lzfse")
        algorithm1.compressResult = Data([1, 2, 3])

        let algorithm2 = MockCompressionAlgorithm(name: "lzfse")
        algorithm2.compressResult = Data([4, 5, 6])

        // Act
        registry.register(algorithm1)
        registry.register(algorithm2)

        // Assert
        let result = registry.algorithm(named: "lzfse")
        XCTAssertEqual(try? result?.compress(input: Data()), Data([4, 5, 6]))
    }
}
