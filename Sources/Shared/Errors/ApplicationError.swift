import Foundation

/// Application layer errors
/// Represent workflow orchestration failures
enum ApplicationError: SwiftCompressError {
    case commandExecutionFailed(commandName: String, underlyingError: SwiftCompressError)
    case preconditionFailed(message: String)
    case postconditionFailed(message: String)
    case workflowInterrupted(stage: String, reason: String)
    case dependencyNotAvailable(dependencyName: String)

    var description: String {
        switch self {
        case .commandExecutionFailed(let commandName, let underlyingError):
            return "Command '\(commandName)' failed: \(underlyingError.description)"
        case .preconditionFailed(let message):
            return "Precondition failed: \(message)"
        case .postconditionFailed(let message):
            return "Postcondition failed: \(message)"
        case .workflowInterrupted(let stage, let reason):
            return "Workflow interrupted at \(stage): \(reason)"
        case .dependencyNotAvailable(let dependencyName):
            return "Required dependency not available: \(dependencyName)"
        }
    }

    var errorCode: String {
        switch self {
        case .commandExecutionFailed: return "APP-001"
        case .preconditionFailed: return "APP-010"
        case .postconditionFailed: return "APP-011"
        case .workflowInterrupted: return "APP-020"
        case .dependencyNotAvailable: return "APP-030"
        }
    }

    var underlyingError: Error? {
        switch self {
        case .commandExecutionFailed(_, let error):
            return error
        default:
            return nil
        }
    }
}
