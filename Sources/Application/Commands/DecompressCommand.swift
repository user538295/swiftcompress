import Foundation

/// Command for orchestrating file decompression workflow
/// Follows Clean Architecture principles - coordinates domain and infrastructure layers
final class DecompressCommand: Command {

    // MARK: - Properties

    let inputSource: InputSource
    let algorithmName: String?  // Optional for file input: can be inferred from extension
    let outputDestination: OutputDestination?  // Optional: defaults based on input source
    let forceOverwrite: Bool

    // Injected dependencies
    private let fileHandler: FileHandlerProtocol
    private let pathResolver: FilePathResolver
    private let validationRules: ValidationRules
    private let algorithmRegistry: AlgorithmRegistry

    // MARK: - Initialization

    init(
        inputSource: InputSource,
        algorithmName: String? = nil,
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

    /// Execute decompression workflow
    /// - Returns: Success with no message (quiet mode) or failure with error
    /// - Throws: ApplicationError for unexpected failures
    func execute() throws {
        do {
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

            // Step 2: Determine algorithm (explicit or inferred)
            let resolvedAlgorithmName = try resolveAlgorithmName()

            // Step 3: Validate algorithm name
            try validationRules.validateAlgorithmName(
                resolvedAlgorithmName,
                supportedAlgorithms: algorithmRegistry.supportedAlgorithms
            )

            // Step 4: Get algorithm from registry
            guard let algorithm = algorithmRegistry.algorithm(named: resolvedAlgorithmName) else {
                throw DomainError.algorithmNotRegistered(name: resolvedAlgorithmName)
            }

            // Step 5: Resolve output destination
            let resolvedOutputDestination = try pathResolver.resolveDecompressOutputDestination(
                inputSource: inputSource,
                algorithmName: resolvedAlgorithmName,
                outputDestination: outputDestination,
                fileExists: { [fileHandler] path in
                    fileHandler.fileExists(at: path)
                }
            )

            // Step 6: Validate output destination (only for file destinations)
            if case .file(let outputPath) = resolvedOutputDestination {
                // Validate output path
                if case .file(let inputPath) = inputSource {
                    try validationRules.validateOutputPath(outputPath, inputPath: inputPath)
                } else {
                    // For stdin input, just validate the output path format
                    try validationRules.validateOutputPath(outputPath, inputPath: "")
                }

                // Check output file overwrite protection
                if fileHandler.fileExists(at: outputPath) && !forceOverwrite {
                    throw DomainError.outputFileExists(path: outputPath)
                }

                // Create output directory if needed
                let outputDirectory = (outputPath as NSString).deletingLastPathComponent
                if !outputDirectory.isEmpty && !fileHandler.fileExists(at: outputDirectory) {
                    try fileHandler.createDirectory(at: outputDirectory)
                }
            }

            // Step 7: Create input and output streams
            let inputStream = try fileHandler.inputStream(from: inputSource)
            let outputStream = try fileHandler.outputStream(to: resolvedOutputDestination)

            // Step 8: Execute decompression with cleanup
            var decompressionSucceeded = false
            defer {
                // Cleanup partial output on failure (only for file outputs)
                if !decompressionSucceeded {
                    if case .file(let outputPath) = resolvedOutputDestination {
                        try? fileHandler.deleteFile(at: outputPath)
                    }
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
            let inputDesc = switch inputSource {
            case .file(let path): path
            case .stdin: "<stdin>"
            }
            throw ApplicationError.commandExecutionFailed(
                commandName: "decompress",
                underlyingError: error as? SwiftCompressError ??
                    DomainError.invalidInputPath(path: inputDesc, reason: "Unexpected error: \(error.localizedDescription)")
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

        // For stdin, algorithm MUST be explicit (cannot infer from extension)
        if case .stdin = inputSource {
            throw DomainError.algorithmCannotBeInferred(
                path: "<stdin>",
                extension: nil,
                supportedExtensions: algorithmRegistry.supportedAlgorithms
            )
        }

        // For file input, try to infer from file extension
        if case .file(let path) = inputSource {
            guard let inferredAlgorithm = pathResolver.inferAlgorithm(from: path) else {
                // Extract file extension for better error message
                let url = URL(fileURLWithPath: path)
                let fileExtension = url.pathExtension
                let supportedExtensions = algorithmRegistry.supportedAlgorithms

                throw DomainError.algorithmCannotBeInferred(
                    path: path,
                    extension: fileExtension.isEmpty ? nil : fileExtension,
                    supportedExtensions: supportedExtensions
                )
            }

            return inferredAlgorithm
        }

        // This should never happen due to enum exhaustiveness
        fatalError("Unexpected input source type")
    }
}
