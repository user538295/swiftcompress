import Foundation
@testable import swiftcompress

/// Consolidated mock progress reporter for testing
/// Used by ProgressTrackingInputStream and ProgressTrackingOutputStream tests
public class MockProgressReporter: ProgressReporterProtocol {

    // MARK: - Tracking Properties

    public var updateCallCount = 0
    public var lastBytesProcessed: Int64 = 0
    public var lastTotalBytes: Int64 = 0
    public var completeCallCount = 0
    public var lastDescription: String?

    // MARK: - Initialization

    public init() {}

    // MARK: - ProgressReporterProtocol Implementation

    public func update(bytesProcessed: Int64, totalBytes: Int64) {
        updateCallCount += 1
        lastBytesProcessed = bytesProcessed
        lastTotalBytes = totalBytes
    }

    public func complete() {
        completeCallCount += 1
    }

    public func setDescription(_ description: String) {
        lastDescription = description
    }
}
