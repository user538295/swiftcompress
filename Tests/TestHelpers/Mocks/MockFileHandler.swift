import Foundation
@testable import swiftcompress

/// Consolidated mock file handler for testing
/// Merges CompressMockFileHandler and DecompressMockFileHandler
public class MockFileHandler: FileHandlerProtocol {

    // MARK: - Configuration Properties

    public var fileExistsResults: [String: Bool] = [:]
    public var isReadableResults: [String: Bool] = [:]
    public var isWritableResults: [String: Bool] = [:]
    public var fileSizeResults: [String: Int64] = [:]

    // MARK: - Tracking Properties

    public var inputStreamPaths: [String] = []
    public var outputStreamPaths: [String] = []
    public var deleteFilePaths: [String] = []
    public var createDirectoryPaths: [String] = []

    // MARK: - Error Injection

    public var inputStreamError: Error?
    public var outputStreamError: Error?
    public var fileSizeError: Error?

    // MARK: - Initialization

    public init() {}

    // MARK: - FileHandlerProtocol Implementation

    public func fileExists(at path: String) -> Bool {
        return fileExistsResults[path] ?? false
    }

    public func isReadable(at path: String) -> Bool {
        return isReadableResults[path] ?? false
    }

    public func isWritable(at path: String) -> Bool {
        return isWritableResults[path] ?? false
    }

    public func fileSize(at path: String) throws -> Int64 {
        if let error = fileSizeError {
            throw error
        }
        return fileSizeResults[path] ?? 1024
    }

    public func deleteFile(at path: String) throws {
        deleteFilePaths.append(path)
    }

    public func createDirectory(at path: String) throws {
        createDirectoryPaths.append(path)
    }

    public func inputStream(at path: String) throws -> InputStream {
        inputStreamPaths.append(path)
        if let error = inputStreamError {
            throw error
        }
        return InputStream(data: Data())
    }

    public func outputStream(at path: String) throws -> OutputStream {
        outputStreamPaths.append(path)
        if let error = outputStreamError {
            throw error
        }
        return OutputStream(toMemory: ())
    }

    // MARK: - stdin/stdout Support

    public func inputStream(from source: InputSource) throws -> InputStream {
        switch source {
        case .file(let path):
            return try inputStream(at: path)
        case .stdin:
            // For testing, return empty stream
            return InputStream(data: Data())
        }
    }

    public func outputStream(to destination: OutputDestination) throws -> OutputStream {
        switch destination {
        case .file(let path):
            return try outputStream(at: path)
        case .stdout:
            // For testing, return memory stream
            return OutputStream(toMemory: ())
        }
    }
}
