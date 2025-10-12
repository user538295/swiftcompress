import Foundation

/// Domain layer errors
/// Represent business logic violations and validation failures
enum DomainError: SwiftCompressError {
    // Algorithm Errors
    case invalidAlgorithmName(name: String, supported: [String])
    case algorithmNotRegistered(name: String)

    // Path Errors
    case invalidInputPath(path: String, reason: String)
    case invalidOutputPath(path: String, reason: String)
    case inputOutputSame(path: String)
    case pathTraversalAttempt(path: String)

    // File State Errors
    case outputFileExists(path: String)
    case inputFileEmpty(path: String)
    case fileTooLarge(path: String, size: Int64, limit: Int64)

    // Validation Errors
    case missingRequiredArgument(argumentName: String)
    case invalidFlagCombination(flags: [String], reason: String)
    case algorithmCannotBeInferred(path: String, extension: String?, supportedExtensions: [String])

    // stdin/stdout Errors
    case outputDestinationRequired(reason: String)
    case stdinNotAvailable(reason: String)
    case stdoutNotAvailable(reason: String)

    var description: String {
        switch self {
        case .invalidAlgorithmName(let name, let supported):
            return "Unknown algorithm '\(name)'. Supported: \(supported.joined(separator: ", "))"
        case .algorithmNotRegistered(let name):
            return "Algorithm '\(name)' is not registered"
        case .invalidInputPath(let path, let reason):
            return "Invalid input path '\(path)': \(reason)"
        case .invalidOutputPath(let path, let reason):
            return "Invalid output path '\(path)': \(reason)"
        case .inputOutputSame(let path):
            return "Input and output paths are the same: \(path)"
        case .pathTraversalAttempt(let path):
            return "Path traversal attempt detected: \(path)"
        case .outputFileExists(let path):
            return "Output file already exists: \(path). Use -f to overwrite."
        case .inputFileEmpty(let path):
            return "Cannot compress empty file: \(path)"
        case .fileTooLarge(let path, let size, let limit):
            return "File too large: \(path) (\(size.formattedByteCount())), limit is \(limit.formattedByteCount())"
        case .missingRequiredArgument(let argumentName):
            return "Missing required argument: \(argumentName)"
        case .invalidFlagCombination(let flags, let reason):
            return "Invalid flag combination [\(flags.joined(separator: ", "))]: \(reason)"
        case .algorithmCannotBeInferred(let path, let fileExtension, let supportedExtensions):
            var message = "Cannot infer compression algorithm for file: \(path)\n"

            if let ext = fileExtension, !ext.isEmpty {
                message += "File extension '.\(ext)' is not recognized.\n"
            } else {
                message += "File has no extension.\n"
            }

            message += "Supported extensions: \(supportedExtensions.map { ".\($0)" }.joined(separator: ", "))\n"
            message += "Please specify the algorithm explicitly using: -m <algorithm>"

            return message

        case .outputDestinationRequired(let reason):
            return "Output destination cannot be determined. \(reason)"

        case .stdinNotAvailable(let reason):
            return "stdin is not available. \(reason)"

        case .stdoutNotAvailable(let reason):
            return "stdout is not available. \(reason)"
        }
    }

    var errorCode: String {
        switch self {
        case .invalidAlgorithmName: return "DOMAIN-001"
        case .algorithmNotRegistered: return "DOMAIN-002"
        case .invalidInputPath: return "DOMAIN-010"
        case .invalidOutputPath: return "DOMAIN-011"
        case .inputOutputSame: return "DOMAIN-012"
        case .pathTraversalAttempt: return "DOMAIN-013"
        case .outputFileExists: return "DOMAIN-020"
        case .inputFileEmpty: return "DOMAIN-021"
        case .fileTooLarge: return "DOMAIN-022"
        case .missingRequiredArgument: return "DOMAIN-030"
        case .invalidFlagCombination: return "DOMAIN-031"
        case .algorithmCannotBeInferred: return "DOMAIN-032"
        case .outputDestinationRequired: return "DOMAIN-040"
        case .stdinNotAvailable: return "DOMAIN-041"
        case .stdoutNotAvailable: return "DOMAIN-042"
        }
    }

    var underlyingError: Error? {
        return nil  // Domain errors have no underlying system errors
    }
}
