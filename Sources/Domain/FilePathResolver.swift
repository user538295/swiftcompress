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
