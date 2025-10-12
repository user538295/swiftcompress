import Foundation

/// Infrastructure layer errors
/// Represent system-level and framework integration failures
enum InfrastructureError: SwiftCompressError {
    // File System Errors
    case fileNotFound(path: String)
    case fileNotReadable(path: String, reason: String?)
    case fileNotWritable(path: String, reason: String?)
    case directoryNotFound(path: String)
    case directoryNotWritable(path: String)
    case insufficientDiskSpace(required: Int64, available: Int64)

    // I/O Errors
    case readFailed(path: String, underlyingError: Error)
    case writeFailed(path: String, underlyingError: Error)
    case streamCreationFailed(path: String)
    case streamReadFailed(underlyingError: Error)
    case streamWriteFailed(underlyingError: Error)

    // Compression Framework Errors
    case compressionInitFailed(algorithm: String, underlyingError: Error?)
    case compressionFailed(algorithm: String, reason: String?)
    case decompressionFailed(algorithm: String, reason: String?)
    case corruptedData(algorithm: String)
    case unsupportedFormat(algorithm: String)

    var description: String {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .fileNotReadable(let path, let reason):
            if let reason = reason {
                return "Cannot read file: \(path) - \(reason)"
            }
            return "Cannot read file: \(path)"
        case .fileNotWritable(let path, let reason):
            if let reason = reason {
                return "Cannot write file: \(path) - \(reason)"
            }
            return "Cannot write file: \(path)"
        case .directoryNotFound(let path):
            return "Directory not found: \(path)"
        case .directoryNotWritable(let path):
            return "Directory not writable: \(path)"
        case .insufficientDiskSpace(let required, let available):
            return "Insufficient disk space. Required: \(required.formattedByteCount()), Available: \(available.formattedByteCount())"
        case .readFailed(let path, _):
            return "Failed to read file: \(path)"
        case .writeFailed(let path, _):
            return "Failed to write file: \(path)"
        case .streamCreationFailed(let path):
            return "Failed to create stream for: \(path)"
        case .streamReadFailed:
            return "Failed to read from stream"
        case .streamWriteFailed:
            return "Failed to write to stream"
        case .compressionInitFailed(let algorithm, _):
            return "Failed to initialize compression with \(algorithm)"
        case .compressionFailed(let algorithm, let reason):
            if let reason = reason {
                return "Compression failed using \(algorithm): \(reason)"
            }
            return "Compression failed using \(algorithm)"
        case .decompressionFailed(let algorithm, let reason):
            if let reason = reason {
                return "Decompression failed using \(algorithm): \(reason)"
            }
            return "Decompression failed using \(algorithm)"
        case .corruptedData(let algorithm):
            return "File appears to be corrupted or not compressed with \(algorithm)"
        case .unsupportedFormat(let algorithm):
            return "Unsupported format for \(algorithm)"
        }
    }

    var errorCode: String {
        switch self {
        case .fileNotFound: return "INFRA-001"
        case .fileNotReadable: return "INFRA-002"
        case .fileNotWritable: return "INFRA-003"
        case .directoryNotFound: return "INFRA-004"
        case .directoryNotWritable: return "INFRA-005"
        case .insufficientDiskSpace: return "INFRA-006"
        case .readFailed: return "INFRA-010"
        case .writeFailed: return "INFRA-011"
        case .streamCreationFailed: return "INFRA-012"
        case .streamReadFailed: return "INFRA-013"
        case .streamWriteFailed: return "INFRA-014"
        case .compressionInitFailed: return "INFRA-020"
        case .compressionFailed: return "INFRA-021"
        case .decompressionFailed: return "INFRA-022"
        case .corruptedData: return "INFRA-023"
        case .unsupportedFormat: return "INFRA-024"
        }
    }

    var underlyingError: Error? {
        switch self {
        case .readFailed(_, let error),
             .writeFailed(_, let error),
             .streamReadFailed(let error),
             .streamWriteFailed(let error):
            return error
        case .compressionInitFailed(_, let error):
            return error
        default:
            return nil
        }
    }
}
