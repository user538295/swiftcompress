import Foundation

/// Command for orchestrating file decompression workflow
/// Follows Clean Architecture principles - coordinates domain and infrastructure layers
final class DecompressCommand: Command {

    // MARK: - Properties

    let inputSource: InputSource
    let algorithmName: String?  // Optional for file input: can be inferred from extension
    let outputDestination: OutputDestination?  // Optional: defaults based on input source
    let forceOverwrite: Bool
    let progressEnabled: Bool

    // Injected dependencies
    private let fileHandler: FileHandlerProtocol
    private let pathResolver: FilePathResolver
    private let validationRules: ValidationRules
    private let algorithmRegistry: AlgorithmRegistry
    private let progressCoordinator: ProgressCoordinator

    // MARK: - Initialization

    init(
        inputSource: InputSource,
        algorithmName: String? = nil,
        outputDestination: OutputDestination? = nil,
        forceOverwrite: Bool = false,
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
        self.progressEnabled = progressEnabled
        self.fileHandler = fileHandler
        self.pathResolver = pathResolver
        self.validationRules = validationRules
        self.algorithmRegistry = algorithmRegistry
        self.progressCoordinator = progressCoordinator
    }

    // MARK: - Execution

    /// Execute decompression workflow
    /// - Returns: Success with no message (quiet mode) or failure with error
    /// - Throws: ApplicationError for unexpected failures
    func execute() throws {
        do {
            // Step 1: Validate input
            try CommandWorkflowHelpers.validateFileInput(
                source: inputSource,
                fileHandler: fileHandler,
                validationRules: validationRules
            )

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

            // Step 6: Validate output destination
            try CommandWorkflowHelpers.validateFileOutput(
                destination: resolvedOutputDestination,
                inputSource: inputSource,
                forceOverwrite: forceOverwrite,
                fileHandler: fileHandler,
                validationRules: validationRules,
                createDirectoryIfNeeded: true
            )

            // Step 7: Setup progress tracking
            let operationDescription = "Decompressing \(inputSource.description)"
            let (progressReporter, inputStream) = try CommandWorkflowHelpers.setupProgressTracking(
                inputSource: inputSource,
                outputDestination: resolvedOutputDestination,
                progressEnabled: progressEnabled,
                operationDescription: operationDescription,
                fileHandler: fileHandler,
                progressCoordinator: progressCoordinator
            )

            // Step 8: Create output stream
            let outputStream = try fileHandler.outputStream(to: resolvedOutputDestination)

            // Step 9: Execute decompression with cleanup
            var decompressionSucceeded = false
            defer {
                // Cleanup partial output on failure
                if !decompressionSucceeded {
                    CommandWorkflowHelpers.cleanupPartialOutput(
                        destination: resolvedOutputDestination,
                        fileHandler: fileHandler
                    )
                }

                // Clear progress indicator on exit (success or failure)
                progressReporter.complete()
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
