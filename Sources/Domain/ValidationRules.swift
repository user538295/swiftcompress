import Foundation

/// Business validation rules
/// Pure logic component with no I/O operations
final class ValidationRules {

    // MARK: - Initialization

    init() {}

    // MARK: - Path Validation

    /// Validate input file path
    /// - Parameter path: Input file path
    /// - Throws: DomainError if validation fails
    func validateInputPath(_ path: String) throws {
        // Path must not be empty
        guard !path.isEmpty else {
            throw DomainError.invalidInputPath(path: path, reason: "Path is empty")
        }

        // Path must not contain null bytes
        guard !path.contains("\0") else {
            throw DomainError.invalidInputPath(path: path, reason: "Path contains null bytes")
        }

        // Check for path traversal attempts
        let normalizedPath = (path as NSString).standardizingPath
        if normalizedPath.contains("../") || normalizedPath.hasPrefix("..") {
            throw DomainError.pathTraversalAttempt(path: path)
        }
    }

    /// Validate output file path
    /// - Parameters:
    ///   - path: Output file path
    ///   - inputPath: Input file path (to ensure they're different)
    /// - Throws: DomainError if validation fails
    func validateOutputPath(_ path: String, inputPath: String) throws {
        // Path must not be empty
        guard !path.isEmpty else {
            throw DomainError.invalidOutputPath(path: path, reason: "Path is empty")
        }

        // Path must not contain null bytes
        guard !path.contains("\0") else {
            throw DomainError.invalidOutputPath(path: path, reason: "Path contains null bytes")
        }

        // Output must be different from input
        let normalizedInput = (inputPath as NSString).standardizingPath
        let normalizedOutput = (path as NSString).standardizingPath

        if normalizedInput == normalizedOutput {
            throw DomainError.inputOutputSame(path: path)
        }

        // Check for path traversal attempts
        if normalizedOutput.contains("../") || normalizedOutput.hasPrefix("..") {
            throw DomainError.pathTraversalAttempt(path: path)
        }
    }

    // MARK: - Algorithm Validation

    /// Validate algorithm name against registry
    /// - Parameters:
    ///   - name: Algorithm name
    ///   - supportedAlgorithms: List of supported algorithm names
    /// - Throws: DomainError if algorithm not supported
    func validateAlgorithmName(_ name: String, supportedAlgorithms: [String]) throws {
        guard !name.isEmpty else {
            throw DomainError.invalidAlgorithmName(name: name, supported: supportedAlgorithms)
        }

        let normalizedName = name.lowercased()
        let normalizedSupported = supportedAlgorithms.map { $0.lowercased() }

        guard normalizedSupported.contains(normalizedName) else {
            throw DomainError.invalidAlgorithmName(name: name, supported: supportedAlgorithms)
        }
    }

    // MARK: - File Size Validation (Future)

    /// Validate file size constraints
    /// - Parameter size: File size in bytes
    /// - Throws: DomainError if file too large
    func validateFileSize(_ size: Int64, limit: Int64 = Int64.max) throws {
        guard size > 0 else {
            throw DomainError.inputFileEmpty(path: "<unknown>")
        }

        guard size <= limit else {
            throw DomainError.fileTooLarge(path: "<unknown>", size: size, limit: limit)
        }
    }
}
