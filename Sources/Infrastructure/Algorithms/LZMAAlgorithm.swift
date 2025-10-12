import Foundation
import Compression

/// LZMA compression algorithm implementation
/// Highest compression ratio with slower compression speed, fast decompression
final class LZMAAlgorithm: AppleCompressionAlgorithm {
    override var algorithmConstant: compression_algorithm { COMPRESSION_LZMA }
    override var name: String { "lzma" }
}
