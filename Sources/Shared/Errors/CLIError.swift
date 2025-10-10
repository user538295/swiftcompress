import Foundation

/// CLI layer errors
/// Represent command-line interface and argument parsing failures
enum CLIError: SwiftCompressError {
    case invalidCommand(provided: String, expected: [String])
    case missingRequiredArgument(name: String)
    case unknownFlag(flag: String)
    case invalidFlagValue(flag: String, value: String, expected: String)
    case conflictingFlags(flags: [String], message: String)
    case helpRequested
    case versionRequested

    var description: String {
        switch self {
        case .invalidCommand(let provided, let expected):
            return "Invalid command '\(provided)'. Expected one of: \(expected.joined(separator: ", "))"
        case .missingRequiredArgument(let name):
            return "Missing required argument: \(name)"
        case .unknownFlag(let flag):
            return "Unknown flag: \(flag)"
        case .invalidFlagValue(let flag, let value, let expected):
            return "Invalid value '\(value)' for flag \(flag). Expected: \(expected)"
        case .conflictingFlags(let flags, let message):
            return "Conflicting flags: \(flags.joined(separator: ", ")). \(message)"
        case .helpRequested:
            return "Help requested"
        case .versionRequested:
            return "Version requested"
        }
    }

    var errorCode: String {
        switch self {
        case .invalidCommand: return "CLI-001"
        case .missingRequiredArgument: return "CLI-002"
        case .unknownFlag: return "CLI-003"
        case .invalidFlagValue: return "CLI-004"
        case .conflictingFlags: return "CLI-005"
        case .helpRequested: return "CLI-100"
        case .versionRequested: return "CLI-101"
        }
    }

    var underlyingError: Error? {
        return nil
    }
}
