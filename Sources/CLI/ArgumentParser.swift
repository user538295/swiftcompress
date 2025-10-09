import Foundation
import ArgumentParser

// MARK: - Protocol Definition

/// Protocol for argument parsing
/// Abstracts Swift ArgumentParser for testability and clean architecture
protocol ArgumentParserProtocol {
    /// Parse arguments and return structured command data
    /// Returns nil if --help or --version requested (handled by ArgumentParser)
    func parse(_ arguments: [String]) throws -> ParsedCommand?
}

// MARK: - Root Command

/// Root command for SwiftCompress CLI
/// Provides version and help information, delegates to subcommands
struct SwiftCompressCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftcompress",
        abstract: "A macOS CLI tool for compressing and decompressing files using Apple's Compression framework.",
        version: "0.1.0",
        subcommands: [Compress.self, Decompress.self],
        helpNames: [.short, .long]
    )
}

// MARK: - Compress Subcommand

extension SwiftCompressCLI {
    /// Compress command (shorthand: 'c')
    struct Compress: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "c",
            abstract: "Compress a file using the specified algorithm",
            helpNames: [.short, .long]
        )

        @Argument(
            help: "Path to the input file to compress"
        )
        var inputFile: String

        @Option(
            name: .shortAndLong,
            help: "Compression algorithm: lzfse, lz4, zlib, or lzma"
        )
        var method: String

        @Option(
            name: .shortAndLong,
            help: "Output file path (default: <inputFile>.<algorithm>)"
        )
        var output: String?

        @Flag(
            name: .shortAndLong,
            help: "Force overwrite if output file exists"
        )
        var force: Bool = false

        func run() throws {
            // Execution is handled by main.swift via CLIArgumentParser
            // This method is required by ParsableCommand but not used directly
        }

        /// Convert to ParsedCommand for domain layer
        func toParsedCommand() throws -> ParsedCommand {
            // Validate algorithm name
            let supportedAlgorithms = ["lzfse", "lz4", "zlib", "lzma"]
            let normalizedMethod = method.lowercased()

            guard supportedAlgorithms.contains(normalizedMethod) else {
                throw CLIError.invalidFlagValue(
                    flag: "-m/--method",
                    value: method,
                    expected: "lzfse, lz4, zlib, or lzma"
                )
            }

            return ParsedCommand(
                commandType: .compress,
                inputPath: inputFile,
                algorithmName: normalizedMethod,
                outputPath: output,
                forceOverwrite: force
            )
        }
    }
}

// MARK: - Decompress Subcommand

extension SwiftCompressCLI {
    /// Decompress command (shorthand: 'x')
    struct Decompress: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "x",
            abstract: "Decompress a file using the specified algorithm",
            helpNames: [.short, .long]
        )

        @Argument(
            help: "Path to the input file to decompress"
        )
        var inputFile: String

        @Option(
            name: .shortAndLong,
            help: "Decompression algorithm: lzfse, lz4, zlib, or lzma (optional, can be inferred from extension)"
        )
        var method: String?

        @Option(
            name: .shortAndLong,
            help: "Output file path (default: input path with algorithm extension stripped)"
        )
        var output: String?

        @Flag(
            name: .shortAndLong,
            help: "Force overwrite if output file exists"
        )
        var force: Bool = false

        func run() throws {
            // Execution is handled by main.swift via CLIArgumentParser
            // This method is required by ParsableCommand but not used directly
        }

        /// Convert to ParsedCommand for domain layer
        func toParsedCommand() throws -> ParsedCommand {
            // Validate algorithm name if provided
            let normalizedMethod: String?
            if let method = method {
                let supportedAlgorithms = ["lzfse", "lz4", "zlib", "lzma"]
                let normalized = method.lowercased()

                guard supportedAlgorithms.contains(normalized) else {
                    throw CLIError.invalidFlagValue(
                        flag: "-m/--method",
                        value: method,
                        expected: "lzfse, lz4, zlib, or lzma"
                    )
                }
                normalizedMethod = normalized
            } else {
                normalizedMethod = nil
            }

            return ParsedCommand(
                commandType: .decompress,
                inputPath: inputFile,
                algorithmName: normalizedMethod,
                outputPath: output,
                forceOverwrite: force
            )
        }
    }
}

// MARK: - Argument Parser Implementation

/// Implementation of ArgumentParserProtocol using Swift ArgumentParser
/// Translates command-line arguments into ParsedCommand structures
final class CLIArgumentParser: ArgumentParserProtocol {

    /// Parse command-line arguments and return ParsedCommand
    /// - Parameter arguments: Array of command-line arguments (including program name)
    /// - Returns: ParsedCommand or nil if help/version was requested
    /// - Throws: CLIError for parsing failures
    func parse(_ arguments: [String]) throws -> ParsedCommand? {
        // Check for empty arguments
        if arguments.isEmpty || arguments.count == 1 {
            throw CLIError.missingRequiredArgument(name: "command (c or x)")
        }

        // Check for help/version flags at root level
        if arguments.contains("--help") || arguments.contains("-h") {
            throw CLIError.helpRequested
        }

        if arguments.contains("--version") {
            throw CLIError.versionRequested
        }

        // Extract command and check validity
        let command = arguments[1]

        // Handle invalid commands
        if command != "c" && command != "x" && !command.starts(with: "-") {
            throw CLIError.invalidCommand(provided: command, expected: ["c", "x"])
        }

        // Try to parse with ArgumentParser
        do {
            // For compress command
            if command == "c" {
                // Drop first two elements: program name and "c" command
                let args = Array(arguments.dropFirst(2))
                let compressCmd = try SwiftCompressCLI.Compress.parse(args)
                return try compressCmd.toParsedCommand()
            }
            // For decompress command
            else if command == "x" {
                // Drop first two elements: program name and "x" command
                let args = Array(arguments.dropFirst(2))
                let decompressCmd = try SwiftCompressCLI.Decompress.parse(args)
                return try decompressCmd.toParsedCommand()
            }
            // Missing command
            else {
                throw CLIError.missingRequiredArgument(name: "command (c or x)")
            }

        } catch let error as CLIError {
            // Already a CLIError, re-throw as-is
            throw error

        } catch let exitCode as ExitCode {
            // Handle ArgumentParser exit codes
            return try handleExitCode(exitCode)

        } catch {
            // Translate other ArgumentParser errors to CLIError
            throw translateArgumentParserError(error)
        }
    }

    // MARK: - Private Helpers

    /// Handle ArgumentParser ExitCode
    private func handleExitCode(_ exitCode: ExitCode) throws -> ParsedCommand? {
        switch exitCode {
        case .success:
            // Help or version was displayed successfully
            throw CLIError.helpRequested
        case .validationFailure:
            throw CLIError.missingRequiredArgument(name: "required argument")
        default:
            throw CLIError.unknownFlag(flag: "parsing error")
        }
    }

    /// Translate Swift ArgumentParser errors to CLIError
    private func translateArgumentParserError(_ error: Error) -> CLIError {
        let errorMessage = error.localizedDescription

        // Unknown option/flag - check this FIRST before missing argument checks
        if errorMessage.contains("Unknown option") || errorMessage.contains("Unexpected argument") {
            // Extract flag name if possible
            let components = errorMessage.components(separatedBy: "'")
            let flag = components.count > 1 ? components[1] : "unknown"
            return CLIError.unknownFlag(flag: flag)
        }

        // Missing input file argument
        if errorMessage.contains("Missing expected argument '<input-file>'") ||
           errorMessage.contains("'<input-file>'") ||
           errorMessage.contains("<input-file>") {
            return CLIError.missingRequiredArgument(name: "inputFile")
        }

        // Missing required --method option
        if errorMessage.contains("Missing expected option '--method'") ||
           errorMessage.contains("Missing expected argument '<method>'") ||
           errorMessage.contains("'--method'") ||
           errorMessage.contains("<method>") ||
           errorMessage.contains("--method") {
            return CLIError.missingRequiredArgument(name: "--method/-m")
        }

        // Unknown command
        if errorMessage.contains("Error: Unknown command") {
            // Try to extract the provided command
            let components = errorMessage.components(separatedBy: "'")
            let provided = components.count > 1 ? components[1] : "unknown"
            return CLIError.invalidCommand(
                provided: provided,
                expected: ["c", "x"]
            )
        }

        // Invalid value for option
        if errorMessage.contains("Invalid value") {
            return CLIError.invalidFlagValue(
                flag: "unknown",
                value: "unknown",
                expected: "valid value"
            )
        }

        // Generic error - check if it mentions specific arguments
        let lowerMessage = errorMessage.lowercased()
        if lowerMessage.contains("input") || lowerMessage.contains("file") {
            return CLIError.missingRequiredArgument(name: "inputFile")
        }
        if lowerMessage.contains("method") {
            return CLIError.missingRequiredArgument(name: "--method/-m")
        }

        // Generic error - missing argument
        return CLIError.missingRequiredArgument(name: "required argument")
    }
}
