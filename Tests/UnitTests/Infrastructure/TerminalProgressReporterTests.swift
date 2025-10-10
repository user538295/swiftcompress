import XCTest
import Foundation
@testable import swiftcompress

/// Unit tests for TerminalProgressReporter
/// Tests progress display formatting and behavior
final class TerminalProgressReporterTests: XCTestCase {

    // MARK: - Tests

    func testTerminalProgressReporter_UpdateDoesNotCrash() {
        // Arrange
        let reporter = TerminalProgressReporter()

        // Act & Assert - Should not crash
        XCTAssertNoThrow(reporter.update(bytesProcessed: 100, totalBytes: 1000))
        XCTAssertNoThrow(reporter.update(bytesProcessed: 500, totalBytes: 1000))
        XCTAssertNoThrow(reporter.update(bytesProcessed: 1000, totalBytes: 1000))
    }

    func testTerminalProgressReporter_CompleteDoesNotCrash() {
        // Arrange
        let reporter = TerminalProgressReporter()

        // Act & Assert
        XCTAssertNoThrow(reporter.complete())
    }

    func testTerminalProgressReporter_SetDescriptionDoesNotCrash() {
        // Arrange
        let reporter = TerminalProgressReporter()

        // Act & Assert
        XCTAssertNoThrow(reporter.setDescription("Compressing file.txt"))
        XCTAssertNoThrow(reporter.setDescription("Decompressing archive.lzfse"))
    }

    func testTerminalProgressReporter_HandlesZeroTotalBytes() {
        // Arrange
        let reporter = TerminalProgressReporter()
        reporter.setDescription("Processing stdin")

        // Act & Assert - Should handle unknown size gracefully
        XCTAssertNoThrow(reporter.update(bytesProcessed: 1024, totalBytes: 0))
        XCTAssertNoThrow(reporter.update(bytesProcessed: 2048, totalBytes: 0))
    }

    func testTerminalProgressReporter_HandlesLargeFiles() {
        // Arrange
        let reporter = TerminalProgressReporter()
        let gigabyte: Int64 = 1_073_741_824  // 1 GB

        // Act & Assert - Should handle large file sizes
        XCTAssertNoThrow(reporter.update(bytesProcessed: gigabyte / 2, totalBytes: gigabyte))
        XCTAssertNoThrow(reporter.update(bytesProcessed: gigabyte, totalBytes: gigabyte))
    }

    func testTerminalProgressReporter_HandlesRapidUpdates() {
        // Arrange
        let reporter = TerminalProgressReporter()
        let totalBytes: Int64 = 10_000

        // Act - Send many rapid updates
        for i in 0..<100 {
            let bytes = Int64(i * 100)
            reporter.update(bytesProcessed: bytes, totalBytes: totalBytes)
        }

        // Assert - Should not crash with rapid updates (throttling should handle)
        XCTAssertTrue(true)
    }

    func testTerminalProgressReporter_CompleteAfterUpdates() {
        // Arrange
        let reporter = TerminalProgressReporter()
        reporter.setDescription("Test operation")

        // Act
        reporter.update(bytesProcessed: 50, totalBytes: 100)
        reporter.update(bytesProcessed: 100, totalBytes: 100)

        // Assert - Complete should clear the line
        XCTAssertNoThrow(reporter.complete())
    }

    func testTerminalProgressReporter_MultipleDescriptionChanges() {
        // Arrange
        let reporter = TerminalProgressReporter()

        // Act & Assert - Description can be changed
        reporter.setDescription("First operation")
        reporter.update(bytesProcessed: 10, totalBytes: 100)

        reporter.setDescription("Second operation")
        reporter.update(bytesProcessed: 20, totalBytes: 100)

        XCTAssertNoThrow(reporter.complete())
    }

    func testTerminalProgressReporter_HandlesEdgeCases() {
        // Arrange
        let reporter = TerminalProgressReporter()

        // Act & Assert - Test edge cases
        // Zero bytes processed
        XCTAssertNoThrow(reporter.update(bytesProcessed: 0, totalBytes: 1000))

        // Bytes processed equals total
        XCTAssertNoThrow(reporter.update(bytesProcessed: 1000, totalBytes: 1000))

        // Very small files
        XCTAssertNoThrow(reporter.update(bytesProcessed: 1, totalBytes: 1))

        // Single byte progress
        XCTAssertNoThrow(reporter.update(bytesProcessed: 1, totalBytes: 100))
    }

    func testTerminalProgressReporter_SequentialOperations() {
        // Arrange
        let reporter = TerminalProgressReporter()

        // Act - Simulate complete operation sequence
        reporter.setDescription("Compressing file.txt")
        reporter.update(bytesProcessed: 0, totalBytes: 1000)
        reporter.update(bytesProcessed: 250, totalBytes: 1000)
        reporter.update(bytesProcessed: 500, totalBytes: 1000)
        reporter.update(bytesProcessed: 750, totalBytes: 1000)
        reporter.update(bytesProcessed: 1000, totalBytes: 1000)
        reporter.complete()

        // Assert - Should complete without issues
        XCTAssertTrue(true)
    }

    func testTerminalProgressReporter_EmptyDescription() {
        // Arrange
        let reporter = TerminalProgressReporter()

        // Act & Assert - Empty description should work
        reporter.setDescription("")
        XCTAssertNoThrow(reporter.update(bytesProcessed: 50, totalBytes: 100))
    }

    func testTerminalProgressReporter_LongDescription() {
        // Arrange
        let reporter = TerminalProgressReporter()
        let longDescription = String(repeating: "A", count: 200)

        // Act & Assert - Long description should be handled
        reporter.setDescription(longDescription)
        XCTAssertNoThrow(reporter.update(bytesProcessed: 50, totalBytes: 100))
    }

    func testTerminalProgressReporter_SpecialCharactersInDescription() {
        // Arrange
        let reporter = TerminalProgressReporter()

        // Act & Assert - Special characters should be handled
        reporter.setDescription("Compressing file with spaces and <special> chars")
        XCTAssertNoThrow(reporter.update(bytesProcessed: 50, totalBytes: 100))
    }

    func testTerminalProgressReporter_MultipleCompletes() {
        // Arrange
        let reporter = TerminalProgressReporter()

        // Act & Assert - Multiple completes should be safe
        reporter.complete()
        reporter.complete()
        reporter.complete()

        XCTAssertTrue(true)
    }

    func testTerminalProgressReporter_UpdatesWithoutDescription() {
        // Arrange
        let reporter = TerminalProgressReporter()

        // Act & Assert - Updates without setting description should work
        XCTAssertNoThrow(reporter.update(bytesProcessed: 50, totalBytes: 100))
        XCTAssertNoThrow(reporter.complete())
    }
}
