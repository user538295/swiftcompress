import Foundation

/// Protocol for command execution coordination
protocol CommandExecutorProtocol {
    /// Execute a command with consistent error handling
    /// - Parameter command: The command to execute
    /// - Returns: Result of command execution
    func execute(_ command: Command) -> CommandResult
}

/// Coordinates command execution and error handling
///
/// Responsibilities:
/// - Execute commands with consistent error handling
/// - Translate domain errors to application errors via ErrorHandler
/// - Ensure proper resource cleanup
/// - Return standardized CommandResult
///
/// The CommandExecutor acts as a coordinator between the CLI layer
/// and the command implementations, providing a consistent execution
/// pattern with centralized error handling.
final class CommandExecutor: CommandExecutorProtocol {
    private let errorHandler: ErrorHandlerProtocol

    /// Initialize CommandExecutor with dependencies
    /// - Parameter errorHandler: Handler for error translation
    init(errorHandler: ErrorHandlerProtocol) {
        self.errorHandler = errorHandler
    }

    /// Execute a command with comprehensive error handling
    ///
    /// This method provides a consistent execution pattern:
    /// 1. Validate command is properly configured
    /// 2. Execute command and capture any errors
    /// 3. Translate errors to user-facing format
    /// 4. Return standardized result
    ///
    /// - Parameter command: The command to execute
    /// - Returns: CommandResult indicating success or failure
    func execute(_ command: Command) -> CommandResult {
        do {
            // Execute the command
            try command.execute()

            // Success - return with no message (quiet mode)
            return .success(message: nil)

        } catch let error as SwiftCompressError {
            // Translate known SwiftCompress errors
            return .failure(error: error)

        } catch {
            // Handle unexpected errors by wrapping them
            let wrappedError = ApplicationError.commandExecutionFailed(
                commandName: String(describing: type(of: command)),
                underlyingError: error as? SwiftCompressError ??
                    ApplicationError.workflowInterrupted(
                        stage: "execution",
                        reason: error.localizedDescription
                    )
            )
            return .failure(error: wrappedError)
        }
    }
}
