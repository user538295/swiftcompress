import Foundation

/// Base protocol for all SwiftCompress errors
/// Provides consistent error interface across all layers
protocol SwiftCompressError: Error, CustomStringConvertible {
    /// Human-readable error description
    var description: String { get }

    /// Technical error code for debugging and logging
    var errorCode: String { get }

    /// Optional underlying system error
    var underlyingError: Error? { get }
}
