import XCTest
import Foundation
@testable import swiftcompress
import TestHelpers

/// Unit tests for ProgressTrackingInputStream
/// Tests stream wrapping and progress tracking functionality
final class ProgressTrackingInputStreamTests: XCTestCase {

    // MARK: - Tests

    func testProgressTrackingInputStream_ReportsProgressOnRead() {
        // Arrange
        let testData = "Hello, World!".data(using: .utf8)!
        let baseStream = InputStream(data: testData)
        let mockReporter = MockProgressReporter()
        let totalBytes: Int64 = Int64(testData.count)

        let stream = ProgressTrackingInputStream(
            stream: baseStream,
            totalBytes: totalBytes,
            progressReporter: mockReporter
        )

        // Act
        stream.open()
        var buffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = stream.read(&buffer, maxLength: buffer.count)
        stream.close()

        // Assert
        XCTAssertEqual(bytesRead, testData.count)
        XCTAssertEqual(mockReporter.updateCallCount, 1)
        XCTAssertEqual(mockReporter.lastBytesProcessed, Int64(bytesRead))
        XCTAssertEqual(mockReporter.lastTotalBytes, totalBytes)
    }

    func testProgressTrackingInputStream_MultipleReadsAccumulateBytes() {
        // Arrange
        let testData = "Hello, World! This is a longer test string.".data(using: .utf8)!
        let baseStream = InputStream(data: testData)
        let mockReporter = MockProgressReporter()
        let totalBytes: Int64 = Int64(testData.count)

        let stream = ProgressTrackingInputStream(
            stream: baseStream,
            totalBytes: totalBytes,
            progressReporter: mockReporter
        )

        // Act - Read in chunks
        stream.open()
        var buffer = [UInt8](repeating: 0, count: 5)

        let firstRead = stream.read(&buffer, maxLength: buffer.count)
        let bytesAfterFirstRead = mockReporter.lastBytesProcessed

        let secondRead = stream.read(&buffer, maxLength: buffer.count)
        let bytesAfterSecondRead = mockReporter.lastBytesProcessed

        stream.close()

        // Assert
        XCTAssertEqual(firstRead, 5)
        XCTAssertEqual(secondRead, 5)
        XCTAssertEqual(bytesAfterFirstRead, 5)
        XCTAssertEqual(bytesAfterSecondRead, 10)
        XCTAssertGreaterThanOrEqual(mockReporter.updateCallCount, 2)
    }

    func testProgressTrackingInputStream_HandlesZeroTotalBytes() {
        // Arrange
        let testData = "Test".data(using: .utf8)!
        let baseStream = InputStream(data: testData)
        let mockReporter = MockProgressReporter()

        let stream = ProgressTrackingInputStream(
            stream: baseStream,
            totalBytes: 0,  // Unknown size
            progressReporter: mockReporter
        )

        // Act
        stream.open()
        var buffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = stream.read(&buffer, maxLength: buffer.count)
        stream.close()

        // Assert
        XCTAssertGreaterThan(bytesRead, 0)
        XCTAssertEqual(mockReporter.lastTotalBytes, 0)
        XCTAssertEqual(mockReporter.lastBytesProcessed, Int64(bytesRead))
    }

    func testProgressTrackingInputStream_DoesNotReportOnZeroBytesRead() {
        // Arrange
        let testData = "Test".data(using: .utf8)!
        let baseStream = InputStream(data: testData)
        let mockReporter = MockProgressReporter()

        let stream = ProgressTrackingInputStream(
            stream: baseStream,
            totalBytes: Int64(testData.count),
            progressReporter: mockReporter
        )

        // Act
        stream.open()
        var buffer = [UInt8](repeating: 0, count: 1024)
        _ = stream.read(&buffer, maxLength: buffer.count)  // Read all data

        let initialCallCount = mockReporter.updateCallCount

        _ = stream.read(&buffer, maxLength: buffer.count)  // Try to read again (EOF)
        stream.close()

        // Assert - No additional progress reports for EOF reads
        XCTAssertEqual(mockReporter.updateCallCount, initialCallCount)
    }

    func testProgressTrackingInputStream_DelegatesToWrappedStream() {
        // Arrange
        let testData = "Hello".data(using: .utf8)!
        let baseStream = InputStream(data: testData)
        let mockReporter = MockProgressReporter()

        let stream = ProgressTrackingInputStream(
            stream: baseStream,
            totalBytes: Int64(testData.count),
            progressReporter: mockReporter
        )

        // Act & Assert - Stream operations work
        XCTAssertEqual(stream.streamStatus, .notOpen)

        stream.open()
        XCTAssertEqual(stream.streamStatus, .open)
        XCTAssertTrue(stream.hasBytesAvailable)

        var buffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = stream.read(&buffer, maxLength: buffer.count)
        XCTAssertEqual(bytesRead, testData.count)

        stream.close()
        XCTAssertEqual(stream.streamStatus, .closed)
    }

    func testProgressTrackingInputStream_HandlesEmptyStream() {
        // Arrange
        let emptyData = Data()
        let baseStream = InputStream(data: emptyData)
        let mockReporter = MockProgressReporter()

        let stream = ProgressTrackingInputStream(
            stream: baseStream,
            totalBytes: 0,
            progressReporter: mockReporter
        )

        // Act
        stream.open()
        var buffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = stream.read(&buffer, maxLength: buffer.count)
        stream.close()

        // Assert
        XCTAssertEqual(bytesRead, 0)
        XCTAssertEqual(mockReporter.updateCallCount, 0)  // No progress for empty read
    }

    func testProgressTrackingInputStream_StreamErrorPropagation() {
        // Arrange
        let testData = "Test".data(using: .utf8)!
        let baseStream = InputStream(data: testData)
        let mockReporter = MockProgressReporter()

        let stream = ProgressTrackingInputStream(
            stream: baseStream,
            totalBytes: Int64(testData.count),
            progressReporter: mockReporter
        )

        // Act & Assert - No error initially
        XCTAssertNil(stream.streamError)

        stream.open()
        XCTAssertNil(stream.streamError)

        stream.close()
        XCTAssertNil(stream.streamError)
    }
}
