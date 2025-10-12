import Foundation
import Compression

/// LZFSE compression algorithm implementation
/// Apple's native algorithm with good balance of speed and compression ratio
final class LZFSEAlgorithm: AppleCompressionAlgorithm {
    override var algorithmConstant: compression_algorithm { COMPRESSION_LZFSE }
    override var name: String { "lzfse" }
}
