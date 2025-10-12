import Foundation
import Compression

/// ZLIB compression algorithm implementation
/// Industry standard with wide compatibility and moderate speed
final class ZLIBAlgorithm: AppleCompressionAlgorithm {
    override var algorithmConstant: compression_algorithm { COMPRESSION_ZLIB }
    override var name: String { "zlib" }
}
