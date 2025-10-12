import Foundation
import Compression

/// LZ4 compression algorithm implementation
/// Extremely fast compression/decompression with lower compression ratio
final class LZ4Algorithm: AppleCompressionAlgorithm {
    override var algorithmConstant: compression_algorithm { COMPRESSION_LZ4 }
    override var name: String { "lz4" }
}
