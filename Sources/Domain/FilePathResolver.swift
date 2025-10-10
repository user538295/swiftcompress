import Foundation

/// Resolves file paths with default naming conventions
/// Pure logic component with no I/O operations
final class FilePathResolver {

    // MARK: - Initialization

    init() {}

    // MARK: - Compression Output Path Resolution

    /// Resolve output path for compression
    /// - Parameters:
    ///   - inputPath: Input file path
    ///   - algorithmName: Compression algorithm name
    ///   - outputPath: Optional explicit output path
    /// - Returns: Resolved output path
    func resolveCompressOutputPath(
        inputPath: String,
        algorithmName: String,
        outputPath: String?
    ) -> String {
        // If explicit output path provided, use it
        if let outputPath = outputPath {
            return outputPath
        }

        // Default: append algorithm extension
        return "\(inputPath).\(algorithmName)"
    }

    // MARK: - Decompression Output Path Resolution

    /// Resolve output path for decompression
    /// - Parameters:
    ///   - inputPath: Input file path (compressed)
    ///   - algorithmName: Decompression algorithm name
    ///   - outputPath: Optional explicit output path
    ///   - fileExists: Closure to check if file exists (dependency injection for testability)
    /// - Returns: Resolved output path
    func resolveDecompressOutputPath(
        inputPath: String,
        algorithmName: String,
        outputPath: String?,
        fileExists: (String) -> Bool
    ) -> String {
        // If explicit output path provided, use it
        if let outputPath = outputPath {
            return outputPath
        }

        // Strip algorithm extension from input path
        let strippedPath = stripAlgorithmExtension(from: inputPath, algorithm: algorithmName)

        // If stripped path exists, append .out suffix to avoid collision
        if fileExists(strippedPath) {
            return "\(strippedPath).out"
        }

        return strippedPath
    }

    // MARK: - stdin/stdout Path Resolution

    /// Resolve output destination for compression with InputSource/OutputDestination support
    /// - Parameters:
    ///   - inputSource: Input source (file or stdin)
    ///   - algorithmName: Compression algorithm name
    ///   - outputDestination: Optional explicit output destination
    /// - Returns: Resolved output destination
    /// - Throws: DomainError if output destination cannot be determined
    func resolveCompressOutputDestination(
        inputSource: InputSource,
        algorithmName: String,
        outputDestination: OutputDestination?
    ) throws -> OutputDestination {
        // If explicit output destination provided, use it
        if let destination = outputDestination {
            return destination
        }

        // For stdin input, we cannot generate a default file path
        // Must have explicit output or use stdout
        switch inputSource {
        case .stdin:
            throw DomainError.outputDestinationRequired(
                reason: "Cannot generate default output path when reading from stdin. Use -o flag to specify output file."
            )
        case .file(let path):
            // Generate default: inputPath.algorithmName
            let outputPath = "\(path).\(algorithmName)"
            return .file(path: outputPath)
        }
    }

    /// Resolve output destination for decompression with InputSource/OutputDestination support
    /// - Parameters:
    ///   - inputSource: Input source (file or stdin)
    ///   - algorithmName: Decompression algorithm name
    ///   - outputDestination: Optional explicit output destination
    ///   - fileExists: Closure to check if file exists (dependency injection for testability)
    /// - Returns: Resolved output destination
    /// - Throws: DomainError if output destination cannot be determined
    func resolveDecompressOutputDestination(
        inputSource: InputSource,
        algorithmName: String,
        outputDestination: OutputDestination?,
        fileExists: (String) -> Bool
    ) throws -> OutputDestination {
        // If explicit output destination provided, use it
        if let destination = outputDestination {
            return destination
        }

        // For stdin input, we cannot generate a default file path
        // Must have explicit output or use stdout
        switch inputSource {
        case .stdin:
            throw DomainError.outputDestinationRequired(
                reason: "Cannot generate default output path when reading from stdin. Use -o flag to specify output file."
            )
        case .file(let path):
            // Strip algorithm extension and check for collisions
            let strippedPath = stripAlgorithmExtension(from: path, algorithm: algorithmName)

            // If stripped path exists, append .out suffix to avoid collision
            let finalPath = fileExists(strippedPath) ? "\(strippedPath).out" : strippedPath
            return .file(path: finalPath)
        }
    }

    // MARK: - Algorithm Inference (Phase 2 feature)

    /// Infer compression algorithm from file extension
    /// - Parameter filePath: File path
    /// - Returns: Algorithm name if inferrable, nil otherwise
    func inferAlgorithm(from filePath: String) -> String? {
        let url = URL(fileURLWithPath: filePath)
        let fileExtension = url.pathExtension.lowercased()

        // Map known extensions to algorithms
        let extensionMap: [String: String] = [
            "lzfse": "lzfse",
            "lz4": "lz4",
            "zlib": "zlib",
            "lzma": "lzma"
        ]

        return extensionMap[fileExtension]
    }

    // MARK: - Private Helpers

    /// Strip algorithm extension from path
    /// - Parameters:
    ///   - path: File path
    ///   - algorithm: Algorithm name
    /// - Returns: Path with extension stripped
    private func stripAlgorithmExtension(from path: String, algorithm: String) -> String {
        let url = URL(fileURLWithPath: path)
        let pathExtension = url.pathExtension.lowercased()

        // Only strip if extension matches algorithm
        if pathExtension == algorithm.lowercased() {
            return url.deletingPathExtension().path
        }

        // If extension doesn't match, return original
        return path
    }
}
