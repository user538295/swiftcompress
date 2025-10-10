import Foundation

/// Represents compression level for tuning compression behavior
/// Maps to algorithm selection and performance characteristics
///
/// Note: Apple's Compression framework does not provide native compression level parameters.
/// These semantic levels optimize compression through:
/// - Algorithm recommendation (fast→LZ4, balanced→LZFSE, best→LZMA)
/// - Buffer size optimization for performance characteristics
public enum CompressionLevel: String, CaseIterable {
    case fast = "fast"
    case balanced = "balanced"
    case best = "best"

    /// Default compression level when none specified
    public static let `default`: CompressionLevel = .balanced

    /// User-facing description of the level
    public var description: String {
        switch self {
        case .fast:
            return "Fast compression (prioritizes speed)"
        case .balanced:
            return "Balanced compression (default, good speed/ratio)"
        case .best:
            return "Best compression (prioritizes compression ratio)"
        }
    }

    /// Recommended algorithm for this compression level
    /// These recommendations are based on the performance characteristics of each algorithm:
    /// - LZ4: Very fast compression/decompression, moderate ratio
    /// - LZFSE: Apple's balanced algorithm, good speed and ratio
    /// - LZMA: Highest compression ratio, slower speed
    public func recommendedAlgorithm() -> String {
        switch self {
        case .fast:
            return "lz4"
        case .balanced:
            return "lzfse"
        case .best:
            return "lzma"
        }
    }

    /// Optimal buffer size for this compression level
    /// - fast: 256 KB - larger chunks for speed optimization
    /// - balanced: 64 KB - standard size for good balance
    /// - best: 64 KB - LZMA benefits from standard size for better ratio
    public var bufferSize: Int {
        switch self {
        case .fast:
            return 262_144  // 256 KB - larger chunks for speed
        case .balanced:
            return 65_536   // 64 KB - current default
        case .best:
            return 65_536   // 64 KB - LZMA benefits from standard size
        }
    }
}
