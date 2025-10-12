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
        // Step 1: Validate input
        try CommandWorkflowHelpers.validateFileInput(
            source: inputSource,
            fileHandler: fileHandler,
            validationRules: validationRules
        )

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

        // Step 4: Validate output destination
        try CommandWorkflowHelpers.validateFileOutput(
            destination: resolvedOutputDestination,
            inputSource: inputSource,
            forceOverwrite: forceOverwrite,
            fileHandler: fileHandler,
            validationRules: validationRules,
            createDirectoryIfNeeded: false
        )

        // Step 5: Get algorithm from registry
        guard let algorithm = algorithmRegistry.algorithm(named: algorithmName) else {
            throw DomainError.algorithmNotRegistered(name: algorithmName)
        }

        // Step 6: Setup progress tracking
        let operationDescription = "Compressing \(inputSource.description)"
        let (progressReporter, inputStream) = try CommandWorkflowHelpers.setupProgressTracking(
            inputSource: inputSource,
            outputDestination: resolvedOutputDestination,
            progressEnabled: progressEnabled,
            operationDescription: operationDescription,
            fileHandler: fileHandler,
            progressCoordinator: progressCoordinator
        )

        // Ensure streams are closed and cleanup on exit
        var outputStreamCreated = false
        var success = false

        defer {
            inputStream.close()

            // Clean up partial output on failure
            if outputStreamCreated && !success {
                CommandWorkflowHelpers.cleanupPartialOutput(
                    destination: resolvedOutputDestination,
                    fileHandler: fileHandler
                )
            }

            // Clear progress indicator on exit (success or failure)
            progressReporter.complete()
        }

        // Step 7: Create output stream
        let outputStream = try fileHandler.outputStream(to: resolvedOutputDestination)
        outputStreamCreated = true

        defer {
            outputStream.close()
        }

        // Step 8: Execute compression
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
