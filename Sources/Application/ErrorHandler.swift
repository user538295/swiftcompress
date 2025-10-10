import Foundation

/// Translates domain and infrastructure errors to user-friendly messages and exit codes
///
/// The ErrorHandler is responsible for:
/// - Converting technical errors to user-friendly messages
/// - Mapping errors to appropriate exit codes
/// - Providing actionable guidance when possible
/// - Sanitizing error messages (no sensitive data)
///
/// MVP: All failures use exit code 1
/// Phase 2: Specific exit codes for different error categories
final class ErrorHandler: ErrorHandlerProtocol {

    // MARK: - Public Interface

    /// Translate an error into user-facing format with appropriate message and exit code
    /// - Parameter error: The error to translate
    /// - Returns: User-facing error with formatted message and exit code
    func handle(_ error: Error) -> UserFacingError {
        // Handle SwiftCompress error types
        if let compressError = error as? SwiftCompressError {
            return handleSwiftCompressError(compressError)
        }

        // Handle unknown/unexpected errors
        return handleUnknownError(error)
    }

    // MARK: - Private Error Translation

    private func handleSwiftCompressError(_ error: SwiftCompressError) -> UserFacingError {
        // Check specific error types and delegate to appropriate handler
        if let cliError = error as? CLIError {
            return handleCLIError(cliError)
        } else if let appError = error as? ApplicationError {
            return handleApplicationError(appError)
        } else if let domainError = error as? DomainError {
            return handleDomainError(domainError)
        } else if let infraError = error as? InfrastructureError {
            return handleInfrastructureError(infraError)
        }

        // Fallback for unknown SwiftCompressError subtypes
        return UserFacingError(
            message: "Error: \(error.description)",
            exitCode: 1,
            shouldPrintStackTrace: false
        )
    }

    private func handleCLIError(_ error: CLIError) -> UserFacingError {
        let message: String

        switch error {
        case .invalidCommand(let provided, let expected):
            message = "Error: Invalid command '\(provided)'. Expected one of: \(expected.joined(separator: ", "))"

        case .missingRequiredArgument(let name):
            message = "Error: Missing required argument: \(name)"

        case .unknownFlag(let flag):
            message = "Error: Unknown flag: \(flag)"

        case .invalidFlagValue(let flag, let value, let expected):
            message = "Error: Invalid value '\(value)' for flag \(flag). Expected: \(expected)"

        case .helpRequested:
            // Help is not an error condition
            message = "" // Will be handled by OutputFormatter
            return UserFacingError(message: message, exitCode: 0, shouldPrintStackTrace: false)

        case .versionRequested:
            // Version is not an error condition
            message = "" // Will be handled by OutputFormatter
            return UserFacingError(message: message, exitCode: 0, shouldPrintStackTrace: false)
        }

        return UserFacingError(message: message, exitCode: 1, shouldPrintStackTrace: false)
    }

    private func handleApplicationError(_ error: ApplicationError) -> UserFacingError {
        let message: String

        switch error {
        case .commandExecutionFailed(let commandName, let underlyingError):
            // Translate the underlying error for better user experience
            let underlyingMessage = handle(underlyingError).message
            message = "Error: Command '\(commandName)' failed: \(underlyingMessage)"

        case .preconditionFailed(let errorMessage):
            message = "Error: Precondition check failed: \(errorMessage)"

        case .postconditionFailed(let errorMessage):
            message = "Error: Operation completed but postcondition check failed: \(errorMessage)"

        case .workflowInterrupted(let stage, let reason):
            message = "Error: Operation interrupted at '\(stage)': \(reason)"

        case .dependencyNotAvailable(let dependencyName):
            message = "Error: Required component '\(dependencyName)' is not available"
        }

        return UserFacingError(message: message, exitCode: 1, shouldPrintStackTrace: false)
    }

    private func handleDomainError(_ error: DomainError) -> UserFacingError {
        let message: String

        switch error {
        case .invalidAlgorithmName(let name, let supported):
            message = "Error: Unknown algorithm '\(name)'. Supported algorithms: \(supported.joined(separator: ", "))"

        case .algorithmNotRegistered(let name):
            message = "Error: Algorithm '\(name)' is not registered"

        case .invalidInputPath(let path, let reason):
            message = "Error: Invalid input path '\(path)': \(reason)"

        case .invalidOutputPath(let path, let reason):
            message = "Error: Invalid output path '\(path)': \(reason)"

        case .inputOutputSame(let path):
            message = "Error: Input and output paths cannot be the same: \(path)"

        case .pathTraversalAttempt(let path):
            message = "Error: Path contains invalid characters: \(path)"

        case .outputFileExists(let path):
            message = "Error: Output file already exists: \(path)\nUse -f flag to force overwrite."

        case .inputFileEmpty(let path):
            message = "Error: Cannot compress empty file: \(path)"

        case .fileTooLarge(let path, let size, let limit):
            let sizeStr = formatBytes(size)
            let limitStr = formatBytes(limit)
            message = "Error: File too large: \(path) (\(sizeStr)). Maximum size: \(limitStr)"

        case .missingRequiredArgument(let argumentName):
            message = "Error: Missing required argument: \(argumentName)"

        case .invalidFlagCombination(let flags, let reason):
            message = "Error: Invalid flag combination [\(flags.joined(separator: ", "))]: \(reason)"

        case .algorithmCannotBeInferred(let path, let fileExtension, let supportedExtensions):
            var errorMessage = "Error: Cannot infer compression algorithm for file: \(path)\n"

            if let ext = fileExtension, !ext.isEmpty {
                errorMessage += "File extension '.\(ext)' is not recognized.\n"
            } else {
                errorMessage += "File has no extension.\n"
            }

            errorMessage += "Supported extensions: \(supportedExtensions.map { ".\($0)" }.joined(separator: ", "))\n"
            errorMessage += "Please specify the algorithm explicitly using: -m <algorithm>"

            message = errorMessage
        }

        return UserFacingError(message: message, exitCode: 1, shouldPrintStackTrace: false)
    }

    private func handleInfrastructureError(_ error: InfrastructureError) -> UserFacingError {
        let message: String

        switch error {
        case .fileNotFound(let path):
            message = "Error: File not found: \(path)"

        case .fileNotReadable(let path, let reason):
            if let reason = reason {
                message = "Error: Cannot read file '\(path)': \(reason)"
            } else {
                message = "Error: Cannot read file: \(path)\nCheck file permissions."
            }

        case .fileNotWritable(let path, let reason):
            if let reason = reason {
                message = "Error: Cannot write file '\(path)': \(reason)"
            } else {
                message = "Error: Cannot write file: \(path)\nCheck directory permissions."
            }

        case .directoryNotFound(let path):
            message = "Error: Directory not found: \(path)"

        case .directoryNotWritable(let path):
            message = "Error: Directory is not writable: \(path)\nCheck permissions."

        case .insufficientDiskSpace(let required, let available):
            let requiredStr = formatBytes(required)
            let availableStr = formatBytes(available)
            message = "Error: Insufficient disk space. Required: \(requiredStr), Available: \(availableStr)"

        case .readFailed(let path, _):
            message = "Error: Failed to read file: \(path)"

        case .writeFailed(let path, _):
            message = "Error: Failed to write file: \(path)\nCheck disk space and permissions."

        case .streamCreationFailed(let path):
            message = "Error: Failed to open file: \(path)"

        case .streamReadFailed:
            message = "Error: Failed to read data from file stream"

        case .streamWriteFailed:
            message = "Error: Failed to write data to file stream\nCheck disk space."

        case .compressionInitFailed(let algorithm, _):
            message = "Error: Failed to initialize \(algorithm) compression"

        case .compressionFailed(let algorithm, let reason):
            if let reason = reason {
                message = "Error: Compression failed using \(algorithm): \(reason)"
            } else {
                message = "Error: Compression failed using \(algorithm)"
            }

        case .decompressionFailed(let algorithm, let reason):
            if let reason = reason {
                message = "Error: Decompression failed using \(algorithm): \(reason)"
            } else {
                message = "Error: Decompression failed using \(algorithm)"
            }

        case .corruptedData(let algorithm):
            message = "Error: File appears to be corrupted or was not compressed with \(algorithm)"

        case .unsupportedFormat(let algorithm):
            message = "Error: Unsupported file format for \(algorithm)"
        }

        return UserFacingError(message: message, exitCode: 1, shouldPrintStackTrace: false)
    }

    private func handleUnknownError(_ error: Error) -> UserFacingError {
        // Log unexpected errors for debugging (in production, this would go to a log file)
        let message = "Error: An unexpected error occurred"

        // In debug mode, we might want stack traces
        #if DEBUG
        return UserFacingError(
            message: "\(message): \(error.localizedDescription)",
            exitCode: 1,
            shouldPrintStackTrace: true
        )
        #else
        return UserFacingError(
            message: message,
            exitCode: 1,
            shouldPrintStackTrace: false
        )
        #endif
    }

    // MARK: - Helper Methods

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
