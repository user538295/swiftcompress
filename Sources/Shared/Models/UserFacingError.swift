import Foundation

/// User-facing error representation
/// Output of ErrorHandler, displayed to user via OutputFormatter
struct UserFacingError: Equatable {
    let message: String
    let exitCode: Int32
    let shouldPrintStackTrace: Bool  // Debug mode only

    init(message: String, exitCode: Int32 = 1, shouldPrintStackTrace: Bool = false) {
        self.message = message
        self.exitCode = exitCode
        self.shouldPrintStackTrace = shouldPrintStackTrace
    }
}
