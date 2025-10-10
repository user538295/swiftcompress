import Foundation

/// Command for orchestrating file compression workflow
/// Application layer component that coordinates domain and infrastructure services
final class CompressCommand: Command {

    // MARK: - Properties

    let inputSource: InputSource
    let algorithmName: String
    let outputDestination: OutputDestination?
    let forceOverwrite: Bool

    // Injected dependencies
    private let fileHandler: FileHandlerProtocol
    private let pathResolver: FilePathResolver
    private let validationRules: ValidationRules
    private let algorithmRegistry: AlgorithmRegistry

    // MARK: - Initialization

    /// Initialize compress command with dependencies
    /// - Parameters:
    ///   - inputSource: Input source (file or stdin)
    ///   - algorithmName: Name of compression algorithm (lzfse, lz4, zlib, lzma)
    ///   - outputDestination: Optional output destination (defaults based on input source)
    ///   - forceOverwrite: Whether to overwrite existing output file
    ///   - fileHandler: File system operations handler
    ///   - pathResolver: Path resolution service
    ///   - validationRules: Business validation rules
    ///   - algorithmRegistry: Algorithm registry for lookup
    init(
        inputSource: InputSource,
        algorithmName: String,
        outputDestination: OutputDestination? = nil,
        forceOverwrite: Bool = false,
        fileHandler: FileHandlerProtocol,
        pathResolver: FilePathResolver,
        validationRules: ValidationRules,
        algorithmRegistry: AlgorithmRegistry
    ) {
        self.inputSource = inputSource
        self.algorithmName = algorithmName
        self.outputDestination = outputDestination
        self.forceOverwrite = forceOverwrite
        self.fileHandler = fileHandler
        self.pathResolver = pathResolver
        self.validationRules = validationRules
        self.algorithmRegistry = algorithmRegistry
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

        // Step 6: Create input stream
        let inputStream = try fileHandler.inputStream(from: inputSource)

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
        }

        // Step 7: Create output stream
        let outputStream = try fileHandler.outputStream(to: resolvedOutputDestination)
        outputStreamCreated = true

        defer {
            outputStream.close()
        }

        // Step 8: Execute compression
        try algorithm.compressStream(
            input: inputStream,
            output: outputStream,
            bufferSize: 65536  // 64 KB buffer
        )

        // Mark success
        success = true
    }
}
