import Foundation

/// Protocol for error handling and translation
/// Maps domain and infrastructure errors to user-facing errors with appropriate messages and exit codes
protocol ErrorHandlerProtocol {
    /// Translate an error into user-facing format
    /// - Parameter error: The error to translate
    /// - Returns: User-facing error with message and exit code
    func handle(_ error: Error) -> UserFacingError
}
