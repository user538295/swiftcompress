import XCTest
import Foundation
@testable import swiftcompress

/// Unit tests for ProgressCoordinator
/// Tests progress reporter factory and stream wrapping logic
final class ProgressCoordinatorTests: XCTestCase {

    // MARK: - Tests

    func testProgressCoordinator_CreatesTerminalReporter_WhenEnabled() {
        // Note: In test environment, stderr may not be a terminal
        // This test verifies the factory method works without crashing

        // Arrange
        let coordinator = ProgressCoordinator()

        // Act
        let reporter = coordinator.createReporter(
            progressEnabled: true,
            outputDestination: .file(path: "/tmp/output.lzfse")
        )

        // Assert - Should return some reporter
        XCTAssertNotNil(reporter)

        // Verify reporter methods work
        XCTAssertNoThrow(reporter.setDescription("Test"))
        XCTAssertNoThrow(reporter.update(bytesProcessed: 100, totalBytes: 1000))
        XCTAssertNoThrow(reporter.complete())
    }

    func testProgressCoordinator_CreatesSilentReporter_WhenDisabled() {
        // Arrange
        let coordinator = ProgressCoordinator()

        // Act
        let reporter = coordinator.createReporter(
            progressEnabled: false,
            outputDestination: .file(path: "/tmp/output.lzfse")
        )

        // Assert - Should return silent reporter
        XCTAssertTrue(reporter is SilentProgressReporter)
    }

    func testProgressCoordinator_CreatesSilentReporter_WhenOutputIsStdout() {
        // Arrange
        let coordinator = ProgressCoordinator()

        // Act
        let reporter = coordinator.createReporter(
            progressEnabled: true,
            outputDestination: .stdout
        )

        // Assert - Should return silent reporter (progress would interfere with stdout)
        XCTAssertTrue(reporter is SilentProgressReporter)
    }

    func testProgressCoordinator_WrapInputStream_CreatesWrapper() {
        // Arrange
        let coordinator = ProgressCoordinator()
        let testData = "Hello, World!".data(using: .utf8)!
        let baseStream = InputStream(data: testData)
        let reporter = SilentProgressReporter()

        // Act
        let wrappedStream = coordinator.wrapInputStream(
            baseStream,
            totalBytes: Int64(testData.count),
            reporter: reporter
        )

        // Assert - Should return wrapped stream
        XCTAssertTrue(wrappedStream is ProgressTrackingInputStream)

        // Verify stream works
        wrappedStream.open()
        var buffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = wrappedStream.read(&buffer, maxLength: buffer.count)
        wrappedStream.close()

        XCTAssertEqual(bytesRead, testData.count)
    }

    func testProgressCoordinator_WrapOutputStream_CreatesWrapper() {
        // Arrange
        let coordinator = ProgressCoordinator()
        let baseStream = OutputStream(toMemory: ())
        let reporter = SilentProgressReporter()

        // Act
        let wrappedStream = coordinator.wrapOutputStream(
            baseStream,
            totalBytes: 100,
            reporter: reporter
        )

        // Assert - Should return wrapped stream
        XCTAssertTrue(wrappedStream is ProgressTrackingOutputStream)

        // Verify stream works
        wrappedStream.open()
        let testData = "Test".data(using: .utf8)!
        let bytesWritten = testData.withUnsafeBytes { bufferPointer in
            wrappedStream.write(bufferPointer.bindMemory(to: UInt8.self).baseAddress!, maxLength: testData.count)
        }
        wrappedStream.close()

        XCTAssertGreaterThan(bytesWritten, 0)
    }

    func testProgressCoordinator_HandlesUnknownTotalBytes() {
        // Arrange
        let coordinator = ProgressCoordinator()
        let testData = "Test".data(using: .utf8)!
        let baseStream = InputStream(data: testData)
        let reporter = SilentProgressReporter()

        // Act - Wrap with unknown size
        let wrappedStream = coordinator.wrapInputStream(
            baseStream,
            totalBytes: 0,  // Unknown
            reporter: reporter
        )

        // Assert - Should work with zero total bytes
        wrappedStream.open()
        var buffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = wrappedStream.read(&buffer, maxLength: buffer.count)
        wrappedStream.close()

        XCTAssertGreaterThan(bytesRead, 0)
    }

    func testProgressCoordinator_ReporterFactory_ConsistentBehavior() {
        // Arrange
        let coordinator = ProgressCoordinator()

        // Act - Create multiple reporters with same settings
        let reporter1 = coordinator.createReporter(
            progressEnabled: false,
            outputDestination: .file(path: "/tmp/test1.lzfse")
        )

        let reporter2 = coordinator.createReporter(
            progressEnabled: false,
            outputDestination: .file(path: "/tmp/test2.lzfse")
        )

        // Assert - Both should be silent reporters
        XCTAssertTrue(reporter1 is SilentProgressReporter)
        XCTAssertTrue(reporter2 is SilentProgressReporter)
    }

    func testProgressCoordinator_WrappedStream_PreservesData() {
        // Arrange
        let coordinator = ProgressCoordinator()
        let testString = "Hello, World! This is a test."
        let testData = testString.data(using: .utf8)!
        let baseStream = InputStream(data: testData)
        let reporter = SilentProgressReporter()

        // Act
        let wrappedStream = coordinator.wrapInputStream(
            baseStream,
            totalBytes: Int64(testData.count),
            reporter: reporter
        )

        wrappedStream.open()
        var buffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = wrappedStream.read(&buffer, maxLength: buffer.count)
        wrappedStream.close()

        let readData = Data(bytes: buffer, count: bytesRead)
        let readString = String(data: readData, encoding: .utf8)

        // Assert - Data should be preserved
        XCTAssertEqual(bytesRead, testData.count)
        XCTAssertEqual(readString, testString)
    }

    func testProgressCoordinator_MultipleWrappersIndependent() {
        // Arrange
        let coordinator = ProgressCoordinator()
        let data1 = "First".data(using: .utf8)!
        let data2 = "Second".data(using: .utf8)!

        let stream1 = InputStream(data: data1)
        let stream2 = InputStream(data: data2)

        let reporter = SilentProgressReporter()

        // Act - Create multiple wrappers
        let wrapped1 = coordinator.wrapInputStream(stream1, totalBytes: Int64(data1.count), reporter: reporter)
        let wrapped2 = coordinator.wrapInputStream(stream2, totalBytes: Int64(data2.count), reporter: reporter)

        // Assert - Both wrappers should work independently
        wrapped1.open()
        wrapped2.open()

        var buffer1 = [UInt8](repeating: 0, count: 1024)
        var buffer2 = [UInt8](repeating: 0, count: 1024)

        let read1 = wrapped1.read(&buffer1, maxLength: buffer1.count)
        let read2 = wrapped2.read(&buffer2, maxLength: buffer2.count)

        wrapped1.close()
        wrapped2.close()

        XCTAssertEqual(read1, data1.count)
        XCTAssertEqual(read2, data2.count)
    }

    func testProgressCoordinator_ReporterCreation_ThreadSafe() {
        // Arrange
        let coordinator = ProgressCoordinator()
        let expectation = self.expectation(description: "Concurrent reporter creation")
        expectation.expectedFulfillmentCount = 10

        // Act - Create reporters concurrently
        DispatchQueue.concurrentPerform(iterations: 10) { _ in
            let reporter = coordinator.createReporter(
                progressEnabled: false,
                outputDestination: .file(path: "/tmp/test.lzfse")
            )

            XCTAssertNotNil(reporter)
            expectation.fulfill()
        }

        // Assert
        waitForExpectations(timeout: 5.0)
    }
}
