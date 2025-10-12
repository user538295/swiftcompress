import Foundation

/// Shared workflow helpers for compression commands
/// Extracts common validation, setup, and cleanup logic used by both
/// CompressCommand and DecompressCommand to reduce code duplication
enum CommandWorkflowHelpers {

    /// Validates file input source
    /// - Parameters:
    ///   - source: Input source (file or stdin)
    ///   - fileHandler: File system operations handler
    ///   - validationRules: Business validation rules
    /// - Throws: DomainError or InfrastructureError if validation fails
    static func validateFileInput(
        source: InputSource,
        fileHandler: FileHandlerProtocol,
        validationRules: ValidationRules
    ) throws {
        // Only validate file sources (stdin is always valid)
        if case .file(let path) = source {
            try validationRules.validateInputPath(path)

            // Check input file exists and is readable
            guard fileHandler.fileExists(at: path) else {
                throw InfrastructureError.fileNotFound(path: path)
            }

            guard fileHandler.isReadable(at: path) else {
                throw InfrastructureError.fileNotReadable(path: path, reason: "Permission denied")
            }
        }
    }

    /// Validates and prepares output destination
    /// - Parameters:
    ///   - destination: Output destination (file or stdout)
    ///   - inputSource: Input source (used for path validation)
    ///   - forceOverwrite: Whether to allow overwriting existing files
    ///   - fileHandler: File system operations handler
    ///   - validationRules: Business validation rules
    ///   - createDirectoryIfNeeded: Whether to create output directory if missing (true for decompress, false for compress)
    /// - Throws: DomainError or InfrastructureError if validation fails
    static func validateFileOutput(
        destination: OutputDestination,
        inputSource: InputSource,
        forceOverwrite: Bool,
        fileHandler: FileHandlerProtocol,
        validationRules: ValidationRules,
        createDirectoryIfNeeded: Bool = false
    ) throws {
        // Only validate file destinations (stdout is always valid)
        if case .file(let outputPath) = destination {
            // Validate output path
            if case .file(let inputPath) = inputSource {
                try validationRules.validateOutputPath(outputPath, inputPath: inputPath)
            } else {
                // For stdin input, just validate the output path format
                try validationRules.validateOutputPath(outputPath, inputPath: "")
            }

            // Check if output exists and handle force flag
            if fileHandler.fileExists(at: outputPath) && !forceOverwrite {
                throw DomainError.outputFileExists(path: outputPath)
            }

            // Handle directory creation or validation
            let outputDirectory = (outputPath as NSString).deletingLastPathComponent
            if !outputDirectory.isEmpty {
                if createDirectoryIfNeeded {
                    // Create directory if it doesn't exist (decompress behavior)
                    if !fileHandler.fileExists(at: outputDirectory) {
                        try fileHandler.createDirectory(at: outputDirectory)
                    }
                } else {
                    // Just check if directory is writable (compress behavior)
                    if !fileHandler.isWritable(at: outputDirectory) {
                        throw InfrastructureError.directoryNotWritable(path: outputDirectory)
                    }
                }
            }
        }
    }

    /// Sets up progress tracking for an operation
    /// - Parameters:
    ///   - inputSource: Input source (file or stdin)
    ///   - outputDestination: Output destination (file or stdout)
    ///   - progressEnabled: Whether progress tracking is enabled
    ///   - operationDescription: Description of the operation (e.g., "Compressing file.txt")
    ///   - fileHandler: File system operations handler
    ///   - progressCoordinator: Progress coordination service
    /// - Returns: Tuple containing the progress reporter and configured input stream
    /// - Throws: InfrastructureError if stream creation fails
    static func setupProgressTracking(
        inputSource: InputSource,
        outputDestination: OutputDestination,
        progressEnabled: Bool,
        operationDescription: String,
        fileHandler: FileHandlerProtocol,
        progressCoordinator: ProgressCoordinator
    ) throws -> (reporter: ProgressReporterProtocol, inputStream: InputStream) {
        // Get file size for progress tracking (0 if stdin or unknown)
        let totalBytes: Int64
        if case .file(let path) = inputSource {
            totalBytes = (try? fileHandler.fileSize(at: path)) ?? 0
        } else {
            totalBytes = 0  // stdin - unknown size
        }

        // Create progress reporter
        let progressReporter = progressCoordinator.createReporter(
            progressEnabled: progressEnabled,
            outputDestination: outputDestination
        )

        // Set operation description
        progressReporter.setDescription(operationDescription)

        // Create input stream
        let rawInputStream = try fileHandler.inputStream(from: inputSource)

        // Wrap with progress tracking
        let inputStream = progressCoordinator.wrapInputStream(
            rawInputStream,
            totalBytes: totalBytes,
            reporter: progressReporter
        )

        return (reporter: progressReporter, inputStream: inputStream)
    }

    /// Cleans up partial output file on failure
    /// - Parameters:
    ///   - destination: Output destination (file or stdout)
    ///   - fileHandler: File system operations handler
    /// - Note: Only cleans up file destinations; stdout cleanup is not needed
    static func cleanupPartialOutput(
        destination: OutputDestination,
        fileHandler: FileHandlerProtocol
    ) {
        // Only clean up file destinations (stdout doesn't need cleanup)
        if case .file(let outputPath) = destination {
            try? fileHandler.deleteFile(at: outputPath)
        }
    }
}
