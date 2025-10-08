import Foundation

/// Registry for managing compression algorithm instances
/// Provides runtime algorithm selection and lookup
final class AlgorithmRegistry {

    // MARK: - Properties

    private var algorithms: [String: CompressionAlgorithmProtocol] = [:]

    // MARK: - Initialization

    init() {}

    // MARK: - Registration

    /// Register a compression algorithm
    /// - Parameter algorithm: Algorithm to register
    func register(_ algorithm: CompressionAlgorithmProtocol) {
        let normalizedName = algorithm.name.lowercased()
        algorithms[normalizedName] = algorithm
    }

    // MARK: - Lookup

    /// Retrieve algorithm by name
    /// - Parameter name: Algorithm name (case-insensitive)
    /// - Returns: Algorithm if found, nil otherwise
    func algorithm(named name: String) -> CompressionAlgorithmProtocol? {
        let normalizedName = name.lowercased()
        return algorithms[normalizedName]
    }

    /// Get list of all supported algorithm names
    var supportedAlgorithms: [String] {
        return Array(algorithms.keys).sorted()
    }

    /// Check if algorithm is registered
    /// - Parameter name: Algorithm name (case-insensitive)
    /// - Returns: true if algorithm is registered
    func isRegistered(_ name: String) -> Bool {
        return algorithm(named: name) != nil
    }
}
