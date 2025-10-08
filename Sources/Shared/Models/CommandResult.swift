import Foundation

/// Result of command execution
enum CommandResult: Equatable {
    case success(message: String?)
    case failure(error: SwiftCompressError)

    static func == (lhs: CommandResult, rhs: CommandResult) -> Bool {
        switch (lhs, rhs) {
        case (.success(let lhsMsg), .success(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.failure(let lhsErr), .failure(let rhsErr)):
            return lhsErr.errorCode == rhsErr.errorCode
        default:
            return false
        }
    }
}
