import Foundation

/// Protocol for all command implementations
/// Commands represent executable operations in the application layer
/// that orchestrate business logic through domain services
protocol Command {
    /// Execute the command
    /// - Throws: SwiftCompressError on failure
    func execute() throws
}
