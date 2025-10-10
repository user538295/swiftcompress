import Foundation

/// Formats output messages for terminal display
///
/// The OutputFormatter is responsible for:
/// - Formatting success messages for stdout (typically empty in quiet mode)
/// - Formatting error messages for stderr with "Error: " prefix
/// - Formatting help text with usage information
/// - Formatting version information
///
/// Key behaviors:
/// - **Quiet by default**: Success operations produce no output
/// - **Error prefix**: All errors are prefixed with "Error: "
/// - **Help text**: Includes usage, algorithms, flags, and examples
/// - **Version**: Simple version string
protocol OutputFormatterProtocol {
    /// Format success message for stdout (typically returns nil for quiet mode)
    /// - Parameter message: Optional success message
    /// - Returns: Formatted message or nil for quiet operation
    func formatSuccess(_ message: String?) -> String?

    /// Format error message for stderr with "Error: " prefix
    /// - Parameter error: User-facing error to format
    /// - Returns: Formatted error message with newline
    func formatError(_ error: UserFacingError) -> String

    /// Format help text with usage examples and supported algorithms
    /// - Returns: Complete help text
    func formatHelp() -> String

    /// Format version information
    /// - Returns: Version string
    func formatVersion() -> String
}

/// Concrete implementation of OutputFormatterProtocol
final class OutputFormatter: OutputFormatterProtocol {

    // MARK: - Constants

    private let version = "1.2.0"
    private let supportedAlgorithms = ["lzfse", "lz4", "zlib", "lzma"]

    // MARK: - Public Interface

    /// Format success message (quiet mode: returns nil)
    /// - Parameter message: Optional success message
    /// - Returns: nil for quiet operation, or formatted message if provided
    func formatSuccess(_ message: String?) -> String? {
        // Quiet by default - success produces no output
        guard let message = message, !message.isEmpty else {
            return nil
        }

        // If a message is explicitly provided, format it
        return message
    }

    /// Format error message with proper prefix and newline
    /// - Parameter error: User-facing error to format
    /// - Returns: Formatted error message ready for stderr
    func formatError(_ error: UserFacingError) -> String {
        // Error messages already contain "Error: " prefix from ErrorHandler
        // Ensure message ends with newline for proper terminal display
        let message = error.message

        if message.hasSuffix("\n") {
            return message
        } else {
            return "\(message)\n"
        }
    }

    /// Format comprehensive help text
    /// - Returns: Multi-line help text with usage, algorithms, flags, and examples
    func formatHelp() -> String {
        """
        swiftcompress - A macOS CLI tool for file compression using Apple's Compression framework

        USAGE:
            swiftcompress <command> <input-file> -m <algorithm> [options]

        COMMANDS:
            c, compress      Compress a file
            x, decompress    Decompress a file

        REQUIRED FLAGS:
            -m <algorithm>   Compression algorithm to use

        OPTIONAL FLAGS:
            -o <output>      Output file path (default: input + algorithm extension)
            -f, --force      Force overwrite if output file exists
            --progress       Show progress indicator during compression/decompression
            --help           Show this help message
            --version        Show version information

        SUPPORTED ALGORITHMS:
            lzfse            Apple's LZFSE (balanced speed/ratio, recommended)
            lz4              LZ4 (fastest, lower compression ratio)
            zlib             Zlib/DEFLATE (industry standard, widely compatible)
            lzma             LZMA (highest compression ratio, slower)

        EXAMPLES:
            Compress a file with LZFSE:
                swiftcompress c document.txt -m lzfse
                Output: document.txt.lzfse

            Compress with custom output path:
                swiftcompress c data.bin -m lz4 -o compressed.lz4

            Decompress a file:
                swiftcompress x document.txt.lzfse -m lzfse
                Output: document.txt

            Force overwrite existing output:
                swiftcompress c file.txt -m zlib -f

            Show progress for large files:
                swiftcompress c largefile.bin -m lzfse --progress
                Output: [=====>     ] 45% 5.2 MB/s ETA 00:03

        EXIT CODES:
            0    Success
            1    Error occurred (see error message)

        For more information, visit: https://github.com/gergelymancz/swiftcompress
        """
    }

    /// Format version string
    /// - Returns: Version information
    func formatVersion() -> String {
        "swiftcompress version \(version)\n"
    }
}
