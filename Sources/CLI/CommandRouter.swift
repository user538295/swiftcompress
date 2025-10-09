import Foundation

/// Protocol for command routing
/// Routes parsed commands to appropriate command implementations
protocol CommandRouterProtocol {
    /// Route and execute the parsed command
    /// - Parameter command: The parsed command to route
    /// - Returns: Result of command execution
    func route(_ command: ParsedCommand) -> CommandResult
}

/// Routes parsed commands to appropriate command handlers
///
/// Responsibilities:
/// - Create appropriate command handler based on command type
/// - Inject dependencies into command handlers
/// - Execute command via CommandExecutor
/// - Handle special cases (help, version)
/// - Return structured CommandResult
///
/// The CommandRouter acts as a factory for commands and coordinates
/// their execution through the CommandExecutor.
final class CommandRouter: CommandRouterProtocol {

    // MARK: - Properties

    private let fileHandler: FileHandlerProtocol
    private let algorithmRegistry: AlgorithmRegistry
    private let pathResolver: FilePathResolver
    private let validationRules: ValidationRules
    private let commandExecutor: CommandExecutor
    private let errorHandler: ErrorHandler

    // MARK: - Initialization

    /// Initialize CommandRouter with all required dependencies
    ///
    /// - Parameters:
    ///   - fileHandler: File system operations handler
    ///   - algorithmRegistry: Registry of compression algorithms
    ///   - pathResolver: Path resolution service
    ///   - validationRules: Business validation rules
    ///   - commandExecutor: Command execution coordinator
    ///   - errorHandler: Error translation service
    init(
        fileHandler: FileHandlerProtocol,
        algorithmRegistry: AlgorithmRegistry,
        pathResolver: FilePathResolver,
        validationRules: ValidationRules,
        commandExecutor: CommandExecutor,
        errorHandler: ErrorHandler
    ) {
        self.fileHandler = fileHandler
        self.algorithmRegistry = algorithmRegistry
        self.pathResolver = pathResolver
        self.validationRules = validationRules
        self.commandExecutor = commandExecutor
        self.errorHandler = errorHandler
    }

    // MARK: - Routing

    /// Route and execute the parsed command
    ///
    /// This method:
    /// 1. Determines the command type
    /// 2. Creates appropriate command instance with dependencies
    /// 3. Executes command via CommandExecutor
    /// 4. Returns CommandResult
    ///
    /// - Parameter command: The parsed command from ArgumentParser
    /// - Returns: Result of command execution (success or failure)
    func route(_ command: ParsedCommand) -> CommandResult {
        // Route based on command type
        switch command.commandType {
        case .compress:
            return routeCompressCommand(command)
        case .decompress:
            return routeDecompressCommand(command)
        }
    }

    // MARK: - Private Routing Methods

    /// Route compress command
    /// - Parameter command: Parsed command with compression parameters
    /// - Returns: Result of compression operation
    private func routeCompressCommand(_ command: ParsedCommand) -> CommandResult {
        // Validate algorithm is provided for compression
        guard let algorithmName = command.algorithmName else {
            let error = CLIError.missingRequiredArgument(name: "-m (algorithm)")
            return .failure(error: error)
        }

        // Create compress command with dependencies
        let compressCommand = CompressCommand(
            inputPath: command.inputPath,
            algorithmName: algorithmName,
            outputPath: command.outputPath,
            forceOverwrite: command.forceOverwrite,
            fileHandler: fileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Execute command via CommandExecutor
        return commandExecutor.execute(compressCommand)
    }

    /// Route decompress command
    /// - Parameter command: Parsed command with decompression parameters
    /// - Returns: Result of decompression operation
    private func routeDecompressCommand(_ command: ParsedCommand) -> CommandResult {
        // Create decompress command with dependencies
        // Algorithm name is optional for decompression (can be inferred)
        let decompressCommand = DecompressCommand(
            inputPath: command.inputPath,
            algorithmName: command.algorithmName,
            outputPath: command.outputPath,
            forceOverwrite: command.forceOverwrite,
            fileHandler: fileHandler,
            pathResolver: pathResolver,
            validationRules: validationRules,
            algorithmRegistry: algorithmRegistry
        )

        // Execute command via CommandExecutor
        return commandExecutor.execute(decompressCommand)
    }
}

// MARK: - Special Case Handlers

extension CommandRouter {
    /// Handle help request
    /// - Returns: Success result with help text
    static func handleHelp() -> CommandResult {
        let helpText = """
        swiftcompress - macOS file compression tool

        USAGE:
            swiftcompress <command> <inputfile> [options]

        COMMANDS:
            c    Compress a file
            x    Decompress a file

        OPTIONS:
            -m <algorithm>    Specify compression algorithm (required for compress)
                              Supported: lzfse, lz4, zlib, lzma
            -o <outputfile>   Override default output filename (optional)
            -f                Force overwrite existing files (optional)

        EXAMPLES:
            # Compress file with LZFSE
            swiftcompress c file.txt -m lzfse

            # Compress with custom output
            swiftcompress c file.txt -m lz4 -o compressed.lz4

            # Decompress (algorithm auto-detected from extension)
            swiftcompress x file.txt.lzfse

            # Decompress with explicit algorithm
            swiftcompress x file.txt.lzfse -m lzfse -o output.txt

            # Force overwrite existing file
            swiftcompress c file.txt -m zlib -f

        DEFAULT BEHAVIOR:
            Compression:   file.txt -> file.txt.<algorithm>
            Decompression: file.txt.lzfse -> file.txt

        EXIT CODES:
            0    Success
            1    Failure

        For more information, visit: https://github.com/yourusername/swiftcompress
        """

        return .success(message: helpText)
    }

    /// Handle version request
    /// - Returns: Success result with version information
    static func handleVersion() -> CommandResult {
        let versionText = """
        swiftcompress version 0.1.0

        A macOS CLI tool for compressing and decompressing files using Apple's
        Compression framework.

        Supported algorithms: LZFSE, LZ4, ZLIB, LZMA
        Platform: macOS 12.0+
        Swift: 5.9+

        Copyright (c) 2024. Licensed under MIT License.
        """

        return .success(message: versionText)
    }
}
