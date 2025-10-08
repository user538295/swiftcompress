import Foundation

/// Type of CLI command
enum CommandType: String, Equatable {
    case compress = "c"
    case decompress = "x"

    var description: String {
        switch self {
        case .compress:
            return "Compress file"
        case .decompress:
            return "Decompress file"
        }
    }
}
