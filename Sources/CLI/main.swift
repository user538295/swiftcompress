#!/usr/bin/env swift
//
//  main.swift
//  swiftcompress
//
//  Entry point for the SwiftCompress CLI tool
//  Handles dependency injection and application bootstrapping
//

import Foundation

// MARK: - Application Entry Point

/// Main entry point for swiftcompress CLI tool
/// Wires all dependencies and executes the command pipeline
func main() {
    // MARK: 1. Create Infrastructure Layer Components

    let fileHandler = FileSystemHandler()

    // Create all algorithm implementations
    let lzfseAlgorithm = LZFSEAlgorithm()
    let lz4Algorithm = LZ4Algorithm()
    let zlibAlgorithm = ZLIBAlgorithm()
    let lzmaAlgorithm = LZMAAlgorithm()

    // MARK: 2. Create Domain Layer Components

    // Create algorithm registry and register all algorithms
    let algorithmRegistry = AlgorithmRegistry()
    algorithmRegistry.register(lzfseAlgorithm)
    algorithmRegistry.register(lz4Algorithm)
    algorithmRegistry.register(zlibAlgorithm)
    algorithmRegistry.register(lzmaAlgorithm)

    // Create domain services
    let pathResolver = FilePathResolver()
    let validationRules = ValidationRules()

    // MARK: 3. Create Application Layer Components

    let errorHandler = ErrorHandler()
    let commandExecutor = CommandExecutor(errorHandler: errorHandler)

    // MARK: 4. Create CLI Layer Components

    let argumentParser = CLIArgumentParser()
    let commandRouter = CommandRouter(
        fileHandler: fileHandler,
        algorithmRegistry: algorithmRegistry,
        pathResolver: pathResolver,
        validationRules: validationRules,
        commandExecutor: commandExecutor,
        errorHandler: errorHandler
    )
    let outputFormatter = OutputFormatter()

    // MARK: 5. Parse Command-Line Arguments

    let parsedCommand: ParsedCommand
    do {
        guard let command = try argumentParser.parse(Array(CommandLine.arguments)) else {
            // Help or version was requested and handled by ArgumentParser
            exit(0)
        }
        parsedCommand = command
    } catch let error as CLIError {
        // Handle CLI parsing errors
        if case .helpRequested = error {
            // Display help
            print(outputFormatter.formatHelp())
            exit(0)
        } else if case .versionRequested = error {
            // Display version
            print(outputFormatter.formatVersion())
            exit(0)
        } else {
            // Display error
            let userError = errorHandler.handle(error)
            let formattedError = outputFormatter.formatError(userError)
            FileHandle.standardError.write(formattedError.data(using: .utf8) ?? Data())
            exit(userError.exitCode)
        }
    } catch {
        // Handle unexpected parsing errors
        let userError = errorHandler.handle(error)
        let formattedError = outputFormatter.formatError(userError)
        FileHandle.standardError.write(formattedError.data(using: .utf8) ?? Data())
        exit(userError.exitCode)
    }

    // MARK: 6. Route and Execute Command

    let result = commandRouter.route(parsedCommand)

    // MARK: 7. Format and Output Result

    switch result {
    case .success(let message):
        // Format success message (typically nil for quiet mode)
        if let formatted = outputFormatter.formatSuccess(message) {
            print(formatted)
        }
        exit(0)

    case .failure(let error):
        // Translate error to user-facing format
        let userError = errorHandler.handle(error)
        let formattedError = outputFormatter.formatError(userError)

        // Write to stderr
        FileHandle.standardError.write(formattedError.data(using: .utf8) ?? Data())

        // Exit with error code
        exit(userError.exitCode)
    }
}

// MARK: - Execute Application

main()
