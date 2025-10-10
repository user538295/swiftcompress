import Foundation

/// Command for orchestrating file compression workflow
/// Application layer component that coordinates domain and infrastructure services
final class CompressCommand: Command {

    // MARK: - Properties

    let inputSource: InputSource
    let algorithmName: String
    let outputDestination: OutputDestination?
    let forceOverwrite: Bool
    let compressionLevel: CompressionLevel
    let progressEnabled: Bool

    // Injected dependencies
    private let fileHandler: FileHandlerProtocol
    private let pathResolver: FilePathResolver
    private let validationRules: ValidationRules
    private let algorithmRegistry: AlgorithmRegistry
    private let progressCoordinator: ProgressCoordinator

    // MARK: - Initialization

    /// Initialize compress command with dependencies
    /// - Parameters:
    ///   - inputSource: Input source (file or stdin)
    ///   - algorithmName: Name of compression algorithm (lzfse, lz4, zlib, lzma)
    ///   - outputDestination: Optional output destination (defaults based on input source)
    ///   - forceOverwrite: Whether to overwrite existing output file
    ///   - compressionLevel: Compression level (fast, balanced, best)
    ///   - progressEnabled: Whether to show progress indicator
    ///   - fileHandler: File system operations handler
    ///   - pathResolver: Path resolution service
    ///   - validationRules: Business validation rules
    ///   - algorithmRegistry: Algorithm registry for lookup
    ///   - progressCoordinator: Progress coordination service
    init(
        inputSource: InputSource,
        algorithmName: String,
        outputDestination: OutputDestination? = nil,
        forceOverwrite: Bool = false,
        compressionLevel: CompressionLevel = .balanced,
        progressEnabled: Bool = false,
        fileHandler: FileHandlerProtocol,
        pathResolver: FilePathResolver,
        validationRules: ValidationRules,
        algorithmRegistry: AlgorithmRegistry,
        progressCoordinator: ProgressCoordinator = ProgressCoordinator()
    ) {
        self.inputSource = inputSource
        self.algorithmName = algorithmName
        self.outputDestination = outputDestination
        self.forceOverwrite = forceOverwrite
        self.compressionLevel = compressionLevel
        self.progressEnabled = progressEnabled
        self.fileHandler = fileHandler
        self.pathResolver = pathResolver
        self.validationRules = validationRules
        self.algorithmRegistry = algorithmRegistry
        self.progressCoordinator = progressCoordinator
    }

    // MARK: - Execution

    /// Execute compression workflow
    /// - Throws: DomainError or InfrastructureError on failure
    func execute() throws {
        // Step 1: Validate input (only for file sources)
        if case .file(let path) = inputSource {
            try validationRules.validateInputPath(path)

            // Check input file exists and is readable
            guard fileHandler.fileExists(at: path) else {
                throw InfrastructureError.fileNotFound(path: path)
            }

            guard fileHandler.isReadable(at: path) else {
                throw InfrastructureError.fileNotReadable(path: path, reason: "Permission denied")
            }
        }

        // Step 2: Validate algorithm name
        try validationRules.validateAlgorithmName(
            algorithmName,
            supportedAlgorithms: algorithmRegistry.supportedAlgorithms
        )

        // Step 3: Resolve output destination
        let resolvedOutputDestination = try pathResolver.resolveCompressOutputDestination(
            inputSource: inputSource,
            algorithmName: algorithmName,
            outputDestination: outputDestination
        )

        // Step 4: Validate output destination (only for file destinations)
        if case .file(let outputPath) = resolvedOutputDestination {
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

            // Check output directory is writable
            let outputDirectory = (outputPath as NSString).deletingLastPathComponent
            if !outputDirectory.isEmpty && !fileHandler.isWritable(at: outputDirectory) {
                throw InfrastructureError.directoryNotWritable(path: outputDirectory)
            }
        }

        // Step 5: Get algorithm from registry
        guard let algorithm = algorithmRegistry.algorithm(named: algorithmName) else {
            throw DomainError.algorithmNotRegistered(name: algorithmName)
        }

        // Step 6: Setup progress tracking
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
            outputDestination: resolvedOutputDestination
        )

        // Set operation description
        let operationDescription = "Compressing \(inputSource.description)"
        progressReporter.setDescription(operationDescription)

        // Step 7: Create input stream
        let rawInputStream = try fileHandler.inputStream(from: inputSource)

        // Wrap with progress tracking
        let inputStream = progressCoordinator.wrapInputStream(
            rawInputStream,
            totalBytes: totalBytes,
            reporter: progressReporter
        )

        // Ensure streams are closed on exit
        var outputStreamCreated = false
        var success = false

        defer {
            inputStream.close()

            // Clean up partial output on failure (only for file outputs)
            if outputStreamCreated && !success {
                if case .file(let outputPath) = resolvedOutputDestination {
                    try? fileHandler.deleteFile(at: outputPath)
                }
            }

            // Clear progress indicator on exit (success or failure)
            progressReporter.complete()
        }

        // Step 8: Create output stream
        let outputStream = try fileHandler.outputStream(to: resolvedOutputDestination)
        outputStreamCreated = true

        defer {
            outputStream.close()
        }

        // Step 9: Execute compression
        // Use buffer size from compression level for optimal performance
        let bufferSize = compressionLevel.bufferSize
        try algorithm.compressStream(
            input: inputStream,
            output: outputStream,
            bufferSize: bufferSize,
            compressionLevel: compressionLevel
        )

        // Mark success
        success = true
    }
}
