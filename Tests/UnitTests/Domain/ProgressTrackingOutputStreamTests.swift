import XCTest
import Foundation
@testable import swiftcompress
import TestHelpers

/// Unit tests for ProgressTrackingOutputStream
/// Tests stream wrapping and progress tracking functionality for output
final class ProgressTrackingOutputStreamTests: XCTestCase {

    // MARK: - Tests

    func testProgressTrackingOutputStream_ReportsProgressOnWrite() {
        // Arrange
        let mockReporter = MockProgressReporter()
        let totalBytes: Int64 = 100

        let baseStream = OutputStream(toMemory: ())
        let stream = ProgressTrackingOutputStream(
            stream: baseStream,
            totalBytes: totalBytes,
            progressReporter: mockReporter
        )

        // Act
        stream.open()
        let testData = "Hello, World!".data(using: .utf8)!
        let bytesWritten = testData.withUnsafeBytes { bufferPointer in
            stream.write(bufferPointer.bindMemory(to: UInt8.self).baseAddress!, maxLength: testData.count)
        }
        stream.close()

        // Assert
        XCTAssertEqual(bytesWritten, testData.count)
        XCTAssertEqual(mockReporter.updateCallCount, 1)
        XCTAssertEqual(mockReporter.lastBytesProcessed, Int64(bytesWritten))
        XCTAssertEqual(mockReporter.lastTotalBytes, totalBytes)
    }

    func testProgressTrackingOutputStream_MultipleWritesAccumulateBytes() {
        // Arrange
        let mockReporter = MockProgressReporter()
        let totalBytes: Int64 = 100

        let baseStream = OutputStream(toMemory: ())
        let stream = ProgressTrackingOutputStream(
            stream: baseStream,
            totalBytes: totalBytes,
            progressReporter: mockReporter
        )

        // Act
        stream.open()

        let firstData = "Hello".data(using: .utf8)!
        let firstWrite = firstData.withUnsafeBytes { bufferPointer in
            stream.write(bufferPointer.bindMemory(to: UInt8.self).baseAddress!, maxLength: firstData.count)
        }
        let bytesAfterFirstWrite = mockReporter.lastBytesProcessed

        let secondData = "World".data(using: .utf8)!
        let secondWrite = secondData.withUnsafeBytes { bufferPointer in
            stream.write(bufferPointer.bindMemory(to: UInt8.self).baseAddress!, maxLength: secondData.count)
        }
        let bytesAfterSecondWrite = mockReporter.lastBytesProcessed

        stream.close()

        // Assert
        XCTAssertEqual(firstWrite, firstData.count)
        XCTAssertEqual(secondWrite, secondData.count)
        XCTAssertEqual(bytesAfterFirstWrite, Int64(firstData.count))
        XCTAssertEqual(bytesAfterSecondWrite, Int64(firstData.count + secondData.count))
        XCTAssertGreaterThanOrEqual(mockReporter.updateCallCount, 2)
    }

    func testProgressTrackingOutputStream_HandlesZeroTotalBytes() {
        // Arrange
        let mockReporter = MockProgressReporter()

        let baseStream = OutputStream(toMemory: ())
        let stream = ProgressTrackingOutputStream(
            stream: baseStream,
            totalBytes: 0,  // Unknown size
            progressReporter: mockReporter
        )

        // Act
        stream.open()
        let testData = "Test".data(using: .utf8)!
        let bytesWritten = testData.withUnsafeBytes { bufferPointer in
            stream.write(bufferPointer.bindMemory(to: UInt8.self).baseAddress!, maxLength: testData.count)
        }
        stream.close()

        // Assert
        XCTAssertGreaterThan(bytesWritten, 0)
        XCTAssertEqual(mockReporter.lastTotalBytes, 0)
        XCTAssertEqual(mockReporter.lastBytesProcessed, Int64(bytesWritten))
    }

    func testProgressTrackingOutputStream_DelegatesToWrappedStream() {
        // Arrange
        let mockReporter = MockProgressReporter()
        let baseStream = OutputStream(toMemory: ())
        let stream = ProgressTrackingOutputStream(
            stream: baseStream,
            totalBytes: 100,
            progressReporter: mockReporter
        )

        // Act & Assert - Stream operations work
        XCTAssertEqual(stream.streamStatus, .notOpen)

        stream.open()
        XCTAssertEqual(stream.streamStatus, .open)
        XCTAssertTrue(stream.hasSpaceAvailable)

        let testData = "Hello".data(using: .utf8)!
        let bytesWritten = testData.withUnsafeBytes { bufferPointer in
            stream.write(bufferPointer.bindMemory(to: UInt8.self).baseAddress!, maxLength: testData.count)
        }
        XCTAssertEqual(bytesWritten, testData.count)

        stream.close()
        XCTAssertEqual(stream.streamStatus, .closed)
    }

    func testProgressTrackingOutputStream_StreamErrorPropagation() {
        // Arrange
        let mockReporter = MockProgressReporter()
        let baseStream = OutputStream(toMemory: ())
        let stream = ProgressTrackingOutputStream(
            stream: baseStream,
            totalBytes: 100,
            progressReporter: mockReporter
        )

        // Act & Assert - No error initially
        XCTAssertNil(stream.streamError)

        stream.open()
        XCTAssertNil(stream.streamError)

        stream.close()
        XCTAssertNil(stream.streamError)
    }

    func testProgressTrackingOutputStream_DoesNotReportOnFailedWrite() {
        // Arrange
        let mockReporter = MockProgressReporter()
        let baseStream = OutputStream(toMemory: ())
        let stream = ProgressTrackingOutputStream(
            stream: baseStream,
            totalBytes: 100,
            progressReporter: mockReporter
        )

        // Act - Don't open stream (write will fail)
        let testData = "Test".data(using: .utf8)!
        let bytesWritten = testData.withUnsafeBytes { bufferPointer in
            stream.write(bufferPointer.bindMemory(to: UInt8.self).baseAddress!, maxLength: testData.count)
        }

        // Assert - Failed write should not report progress
        XCTAssertEqual(bytesWritten, -1)  // Error condition
        XCTAssertEqual(mockReporter.updateCallCount, 0)
    }

    func testProgressTrackingOutputStream_WritesDataCorrectly() {
        // Arrange
        let mockReporter = MockProgressReporter()
        let baseStream = OutputStream(toMemory: ())
        let stream = ProgressTrackingOutputStream(
            stream: baseStream,
            totalBytes: 100,
            progressReporter: mockReporter
        )

        // Act
        stream.open()
        let testData = "Hello, World!".data(using: .utf8)!
        let bytesWritten = testData.withUnsafeBytes { bufferPointer in
            stream.write(bufferPointer.bindMemory(to: UInt8.self).baseAddress!, maxLength: testData.count)
        }
        stream.close()

        // Retrieve written data from base stream
        let writtenData = baseStream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data

        // Assert
        XCTAssertEqual(bytesWritten, testData.count)
        XCTAssertEqual(writtenData, testData)
    }
}
