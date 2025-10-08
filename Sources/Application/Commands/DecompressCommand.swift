import Foundation

/// Command for orchestrating file decompression workflow
/// Follows Clean Architecture principles - coordinates domain and infrastructure layers
final class DecompressCommand {

    // MARK: - Properties

    let inputPath: String
    let algorithmName: String?  // Optional: can be inferred from extension
    let outputPath: String?     // Optional: defaults to input without extension
    let forceOverwrite: Bool

    // Injected dependencies
    private let fileHandler: FileHandlerProtocol
    private let pathResolver: FilePathResolver
    private let validationRules: ValidationRules
    private let algorithmRegistry: AlgorithmRegistry

    // MARK: - Initialization

    init(
        inputPath: String,
        algorithmName: String? = nil,
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

    /// Execute decompression workflow
    /// - Returns: Success with no message (quiet mode) or failure with error
    /// - Throws: ApplicationError for unexpected failures
    func execute() throws {
        do {
            // Step 1: Validate input path
            try validationRules.validateInputPath(inputPath)

            // Step 2: Check input file exists
            guard fileHandler.fileExists(at: inputPath) else {
                throw InfrastructureError.fileNotFound(path: inputPath)
            }

            // Step 3: Check input file is readable
            guard fileHandler.isReadable(at: inputPath) else {
                throw InfrastructureError.fileNotReadable(path: inputPath, reason: "Permission denied")
            }

            // Step 4: Determine algorithm (explicit or inferred)
            let resolvedAlgorithmName = try resolveAlgorithmName()

            // Step 5: Validate algorithm name
            try validationRules.validateAlgorithmName(
                resolvedAlgorithmName,
                supportedAlgorithms: algorithmRegistry.supportedAlgorithms
            )

            // Step 6: Get algorithm from registry
            guard let algorithm = algorithmRegistry.algorithm(named: resolvedAlgorithmName) else {
                throw DomainError.algorithmNotRegistered(name: resolvedAlgorithmName)
            }

            // Step 7: Resolve output path
            let resolvedOutputPath = pathResolver.resolveDecompressOutputPath(
                inputPath: inputPath,
                algorithmName: resolvedAlgorithmName,
                outputPath: outputPath,
                fileExists: { [fileHandler] path in
                    fileHandler.fileExists(at: path)
                }
            )

            // Step 8: Validate output path
            try validationRules.validateOutputPath(resolvedOutputPath, inputPath: inputPath)

            // Step 9: Check output file overwrite protection
            if fileHandler.fileExists(at: resolvedOutputPath) && !forceOverwrite {
                throw DomainError.outputFileExists(path: resolvedOutputPath)
            }

            // Step 10: Create output directory if needed
            let outputDirectory = (resolvedOutputPath as NSString).deletingLastPathComponent
            if !outputDirectory.isEmpty && !fileHandler.fileExists(at: outputDirectory) {
                try fileHandler.createDirectory(at: outputDirectory)
            }

            // Step 11: Create input and output streams
            let inputStream = try fileHandler.inputStream(at: inputPath)
            let outputStream = try fileHandler.outputStream(at: resolvedOutputPath)

            // Step 12: Execute decompression with cleanup
            var decompressionSucceeded = false
            defer {
                // Cleanup partial output on failure
                if !decompressionSucceeded {
                    try? fileHandler.deleteFile(at: resolvedOutputPath)
                }
            }

            try algorithm.decompressStream(
                input: inputStream,
                output: outputStream,
                bufferSize: 65536  // 64 KB buffer
            )

            decompressionSucceeded = true

        } catch let error as SwiftCompressError {
            // Propagate domain and infrastructure errors
            throw error
        } catch {
            // Wrap unexpected errors
            throw ApplicationError.commandExecutionFailed(
                commandName: "decompress",
                underlyingError: error as? SwiftCompressError ??
                    DomainError.invalidInputPath(path: inputPath, reason: "Unexpected error: \(error.localizedDescription)")
            )
        }
    }

    // MARK: - Private Helpers

    /// Resolve algorithm name from explicit value or infer from extension
    /// - Returns: Resolved algorithm name
    /// - Throws: DomainError if algorithm cannot be determined
    private func resolveAlgorithmName() throws -> String {
        // If algorithm explicitly provided, use it
        if let explicitAlgorithm = algorithmName {
            return explicitAlgorithm
        }

        // Otherwise, try to infer from file extension
        guard let inferredAlgorithm = pathResolver.inferAlgorithm(from: inputPath) else {
            throw DomainError.missingRequiredArgument(
                argumentName: "-m (algorithm)"
            )
        }

        return inferredAlgorithm
    }
}
