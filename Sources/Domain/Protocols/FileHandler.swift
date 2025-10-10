import Foundation

/// Protocol for file system operations
/// Abstraction over FileManager for testability
protocol FileHandlerProtocol {
    /// Check if file exists at path
    /// - Parameter path: File path
    /// - Returns: true if file exists
    func fileExists(at path: String) -> Bool

    /// Check if file is readable
    /// - Parameter path: File path
    /// - Returns: true if file is readable
    func isReadable(at path: String) -> Bool

    /// Check if path is writable (file or directory)
    /// - Parameter path: File or directory path
    /// - Returns: true if writable
    func isWritable(at path: String) -> Bool

    /// Get file size in bytes
    /// - Parameter path: File path
    /// - Returns: File size in bytes
    /// - Throws: InfrastructureError if file not found or not accessible
    func fileSize(at path: String) throws -> Int64

    /// Create input stream for reading file
    /// - Parameter path: File path
    /// - Returns: Configured input stream
    /// - Throws: InfrastructureError if stream creation fails
    func inputStream(at path: String) throws -> InputStream

    /// Create output stream for writing file
    /// - Parameter path: File path
    /// - Returns: Configured output stream
    /// - Throws: InfrastructureError if stream creation fails
    func outputStream(at path: String) throws -> OutputStream

    /// Delete file at path
    /// - Parameter path: File path
    /// - Throws: InfrastructureError if deletion fails
    func deleteFile(at path: String) throws

    /// Create directory at path if it doesn't exist
    /// - Parameter path: Directory path
    /// - Throws: InfrastructureError if creation fails
    func createDirectory(at path: String) throws

    /// Create input stream from source (file or stdin)
    /// - Parameter source: Input source (file path or stdin)
    /// - Returns: Configured input stream ready for reading
    /// - Throws: InfrastructureError if stream creation fails
    func inputStream(from source: InputSource) throws -> InputStream

    /// Create output stream to destination (file or stdout)
    /// - Parameter destination: Output destination (file path or stdout)
    /// - Returns: Configured output stream ready for writing
    /// - Throws: InfrastructureError if stream creation fails
    func outputStream(to destination: OutputDestination) throws -> OutputStream
}
