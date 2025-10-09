import Foundation

/// Represents parsed command-line arguments
/// Output of ArgumentParser, input to CommandRouter
struct ParsedCommand: Equatable {
    let commandType: CommandType
    let inputPath: String
    let algorithmName: String?  // Optional for decompression (can be inferred)
    let outputPath: String?     // Optional, uses default if nil
    let forceOverwrite: Bool

    /// Standard initializer for ParsedCommand
    init(
        commandType: CommandType,
        inputPath: String,
        algorithmName: String? = nil,
        outputPath: String? = nil,
        forceOverwrite: Bool = false
    ) {
        self.commandType = commandType
        self.inputPath = inputPath
        self.algorithmName = algorithmName
        self.outputPath = outputPath
        self.forceOverwrite = forceOverwrite
    }
}
