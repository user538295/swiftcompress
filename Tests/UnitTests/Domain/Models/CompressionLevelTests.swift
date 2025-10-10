import XCTest
@testable import swiftcompress

final class CompressionLevelTests: XCTestCase {

    // MARK: - Default Level Tests

    func testDefaultLevel_IsBalanced() {
        // Given & When
        let defaultLevel = CompressionLevel.default

        // Then
        XCTAssertEqual(defaultLevel, .balanced, "Default compression level should be balanced")
    }

    // MARK: - Recommended Algorithm Tests

    func testRecommendedAlgorithm_Fast_ReturnsLZ4() {
        // Given
        let level = CompressionLevel.fast

        // When
        let algorithm = level.recommendedAlgorithm()

        // Then
        XCTAssertEqual(algorithm, "lz4", "Fast level should recommend LZ4 algorithm")
    }

    func testRecommendedAlgorithm_Balanced_ReturnsLZFSE() {
        // Given
        let level = CompressionLevel.balanced

        // When
        let algorithm = level.recommendedAlgorithm()

        // Then
        XCTAssertEqual(algorithm, "lzfse", "Balanced level should recommend LZFSE algorithm")
    }

    func testRecommendedAlgorithm_Best_ReturnsLZMA() {
        // Given
        let level = CompressionLevel.best

        // When
        let algorithm = level.recommendedAlgorithm()

        // Then
        XCTAssertEqual(algorithm, "lzma", "Best level should recommend LZMA algorithm")
    }

    // MARK: - Buffer Size Tests

    func testBufferSize_Fast_Returns256KB() {
        // Given
        let level = CompressionLevel.fast

        // When
        let bufferSize = level.bufferSize

        // Then
        XCTAssertEqual(bufferSize, 262_144, "Fast level should use 256 KB buffer (262,144 bytes)")
    }

    func testBufferSize_Balanced_Returns64KB() {
        // Given
        let level = CompressionLevel.balanced

        // When
        let bufferSize = level.bufferSize

        // Then
        XCTAssertEqual(bufferSize, 65_536, "Balanced level should use 64 KB buffer (65,536 bytes)")
    }

    func testBufferSize_Best_Returns64KB() {
        // Given
        let level = CompressionLevel.best

        // When
        let bufferSize = level.bufferSize

        // Then
        XCTAssertEqual(bufferSize, 65_536, "Best level should use 64 KB buffer (65,536 bytes)")
    }

    // MARK: - Description Tests

    func testDescription_Fast_ContainsPrioritizesSpeed() {
        // Given
        let level = CompressionLevel.fast

        // When
        let description = level.description

        // Then
        XCTAssertTrue(description.contains("Fast"), "Fast level description should contain 'Fast'")
        XCTAssertTrue(description.contains("speed"), "Fast level description should mention speed")
    }

    func testDescription_Balanced_ContainsDefault() {
        // Given
        let level = CompressionLevel.balanced

        // When
        let description = level.description

        // Then
        XCTAssertTrue(description.contains("Balanced"), "Balanced level description should contain 'Balanced'")
        XCTAssertTrue(description.contains("default"), "Balanced level description should mention it's the default")
    }

    func testDescription_Best_ContainsCompressionRatio() {
        // Given
        let level = CompressionLevel.best

        // When
        let description = level.description

        // Then
        XCTAssertTrue(description.contains("Best"), "Best level description should contain 'Best'")
        XCTAssertTrue(description.contains("ratio"), "Best level description should mention compression ratio")
    }

    // MARK: - Raw Value Tests

    func testRawValue_Fast() {
        // Given
        let level = CompressionLevel.fast

        // When
        let rawValue = level.rawValue

        // Then
        XCTAssertEqual(rawValue, "fast", "Fast level raw value should be 'fast'")
    }

    func testRawValue_Balanced() {
        // Given
        let level = CompressionLevel.balanced

        // When
        let rawValue = level.rawValue

        // Then
        XCTAssertEqual(rawValue, "balanced", "Balanced level raw value should be 'balanced'")
    }

    func testRawValue_Best() {
        // Given
        let level = CompressionLevel.best

        // When
        let rawValue = level.rawValue

        // Then
        XCTAssertEqual(rawValue, "best", "Best level raw value should be 'best'")
    }

    // MARK: - Initialization from Raw Value Tests

    func testInitFromRawValue_Fast() {
        // Given
        let rawValue = "fast"

        // When
        let level = CompressionLevel(rawValue: rawValue)

        // Then
        XCTAssertEqual(level, .fast, "Should initialize fast level from 'fast' raw value")
    }

    func testInitFromRawValue_Balanced() {
        // Given
        let rawValue = "balanced"

        // When
        let level = CompressionLevel(rawValue: rawValue)

        // Then
        XCTAssertEqual(level, .balanced, "Should initialize balanced level from 'balanced' raw value")
    }

    func testInitFromRawValue_Best() {
        // Given
        let rawValue = "best"

        // When
        let level = CompressionLevel(rawValue: rawValue)

        // Then
        XCTAssertEqual(level, .best, "Should initialize best level from 'best' raw value")
    }

    func testInitFromRawValue_Invalid_ReturnsNil() {
        // Given
        let rawValue = "invalid"

        // When
        let level = CompressionLevel(rawValue: rawValue)

        // Then
        XCTAssertNil(level, "Should return nil for invalid raw value")
    }

    // MARK: - All Cases Tests

    func testAllCases_ContainsAllThreeLevels() {
        // Given & When
        let allCases = CompressionLevel.allCases

        // Then
        XCTAssertEqual(allCases.count, 3, "Should have exactly 3 compression levels")
        XCTAssertTrue(allCases.contains(.fast), "All cases should include fast")
        XCTAssertTrue(allCases.contains(.balanced), "All cases should include balanced")
        XCTAssertTrue(allCases.contains(.best), "All cases should include best")
    }

    func testAllCases_OrderIsConsistent() {
        // Given & When
        let allCases = CompressionLevel.allCases

        // Then
        XCTAssertEqual(allCases[0], .fast, "First case should be fast")
        XCTAssertEqual(allCases[1], .balanced, "Second case should be balanced")
        XCTAssertEqual(allCases[2], .best, "Third case should be best")
    }

    // MARK: - Equatable Tests

    func testEquality_SameLevels() {
        // Given
        let level1 = CompressionLevel.fast
        let level2 = CompressionLevel.fast

        // When & Then
        XCTAssertEqual(level1, level2, "Same levels should be equal")
    }

    func testEquality_DifferentLevels() {
        // Given
        let level1 = CompressionLevel.fast
        let level2 = CompressionLevel.best

        // When & Then
        XCTAssertNotEqual(level1, level2, "Different levels should not be equal")
    }

    // MARK: - Buffer Size Optimization Tests

    func testBufferSize_FastIsLargest() {
        // Given
        let fastBuffer = CompressionLevel.fast.bufferSize
        let balancedBuffer = CompressionLevel.balanced.bufferSize
        let bestBuffer = CompressionLevel.best.bufferSize

        // Then
        XCTAssertGreaterThan(fastBuffer, balancedBuffer, "Fast should have larger buffer than balanced")
        XCTAssertGreaterThan(fastBuffer, bestBuffer, "Fast should have larger buffer than best")
    }

    func testBufferSize_AllArePositive() {
        // Given & When
        let levels = CompressionLevel.allCases

        // Then
        for level in levels {
            XCTAssertGreaterThan(level.bufferSize, 0, "\(level) should have positive buffer size")
        }
    }
}
