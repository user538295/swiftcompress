import Foundation

/// Command for orchestrating file compression workflow
/// Application layer component that coordinates domain and infrastructure services
final class CompressCommand {

    // MARK: - Properties

    let inputPath: String
    let algorithmName: String
    let outputPath: String?
    let forceOverwrite: Bool

    // Injected dependencies
    private let fileHandler: FileHandlerProtocol
    private let pathResolver: FilePathResolver
    private let validationRules: ValidationRules
    private let algorithmRegistry: AlgorithmRegistry

    // MARK: - Initialization

    /// Initialize compress command with dependencies
    /// - Parameters:
    ///   - inputPath: Path to input file
    ///   - algorithmName: Name of compression algorithm (lzfse, lz4, zlib, lzma)
    ///   - outputPath: Optional output path (defaults to inputPath.algorithmName)
    ///   - forceOverwrite: Whether to overwrite existing output file
    ///   - fileHandler: File system operations handler
    ///   - pathResolver: Path resolution service
    ///   - validationRules: Business validation rules
    ///   - algorithmRegistry: Algorithm registry for lookup
    init(
        inputPath: String,
        algorithmName: String,
        outputPath: String? = nil,
        forceOverwrite: Bool = false,
        fileHandler: FileHandlerProtocol,
        pathResolver: FilePathResolver,
        validationRules: ValidationRules,
        algorithmRegistry: AlgorithmRegistry
    ) {
        self.inputPath = inputPath
        self.algorithmName = algorithmName
        self.outputPath = outputPath
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
        // Step 1: Validate input path
        try validationRules.validateInputPath(inputPath)

        // Step 2: Validate algorithm name
        try validationRules.validateAlgorithmName(
            algorithmName,
            supportedAlgorithms: algorithmRegistry.supportedAlgorithms
        )

        // Step 3: Check input file exists
        guard fileHandler.fileExists(at: inputPath) else {
            throw InfrastructureError.fileNotFound(path: inputPath)
        }

        // Step 4: Check input file is readable
        guard fileHandler.isReadable(at: inputPath) else {
            throw InfrastructureError.fileNotReadable(path: inputPath, reason: "Permission denied")
        }

        // Step 5: Resolve output path
        let resolvedOutputPath = pathResolver.resolveCompressOutputPath(
            inputPath: inputPath,
            algorithmName: algorithmName,
            outputPath: outputPath
        )

        // Step 6: Validate output path
        try validationRules.validateOutputPath(resolvedOutputPath, inputPath: inputPath)

        // Step 7: Check if output exists and handle force flag
        if fileHandler.fileExists(at: resolvedOutputPath) && !forceOverwrite {
            throw DomainError.outputFileExists(path: resolvedOutputPath)
        }

        // Step 8: Check output directory is writable
        let outputDirectory = (resolvedOutputPath as NSString).deletingLastPathComponent
        if !outputDirectory.isEmpty && !fileHandler.isWritable(at: outputDirectory) {
            throw InfrastructureError.directoryNotWritable(path: outputDirectory)
        }

        // Step 9: Get algorithm from registry
        guard let algorithm = algorithmRegistry.algorithm(named: algorithmName) else {
            throw DomainError.algorithmNotRegistered(name: algorithmName)
        }

        // Step 10: Create input stream
        let inputStream = try fileHandler.inputStream(at: inputPath)

        // Ensure streams are closed on exit
        var outputStreamCreated = false
        var success = false

        defer {
            inputStream.close()

            // Clean up partial output on failure
            if outputStreamCreated && !success {
                try? fileHandler.deleteFile(at: resolvedOutputPath)
            }
        }

        // Step 11: Create output stream
        let outputStream = try fileHandler.outputStream(at: resolvedOutputPath)
        outputStreamCreated = true

        defer {
            outputStream.close()
        }

        // Step 12: Execute compression
        try algorithm.compressStream(
            input: inputStream,
            output: outputStream,
            bufferSize: 65536  // 64 KB buffer
        )

        // Mark success
        success = true
    }
}
