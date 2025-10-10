import Foundation

/// Represents parsed command-line arguments
/// Output of ArgumentParser, input to CommandRouter
struct ParsedCommand: Equatable {
    let commandType: CommandType
    let inputSource: InputSource            // Changed from inputPath
    let algorithmName: String?              // Optional for decompression (can be inferred)
    let outputDestination: OutputDestination?  // Changed from outputPath
    let forceOverwrite: Bool

    /// Standard initializer for ParsedCommand
    init(
        commandType: CommandType,
        inputSource: InputSource,
        algorithmName: String? = nil,
        outputDestination: OutputDestination? = nil,
        forceOverwrite: Bool = false
    ) {
        self.commandType = commandType
        self.inputSource = inputSource
        self.algorithmName = algorithmName
        self.outputDestination = outputDestination
        self.forceOverwrite = forceOverwrite
    }
}
