# ADR-002: Protocol-Based Algorithm Abstraction

**Status**: Accepted

**Date**: 2025-10-07

---

## Context

SwiftCompress needs to support multiple compression algorithms:
- LZFSE (Apple's proprietary algorithm)
- LZ4 (fast compression)
- Zlib (industry standard)
- LZMA (high compression ratio)

Each algorithm has different characteristics (speed, compression ratio, use cases), but from the application's perspective, they all perform the same fundamental operations: compress and decompress data.

### Challenges

1. **Algorithm Selection**: Users specify algorithm via `-m` flag; system must select and invoke correct algorithm
2. **Extensibility**: Future algorithms should be easy to add without modifying existing code
3. **Testability**: Compression logic should be testable without depending on Apple's Compression Framework
4. **Consistency**: All algorithms should provide uniform interface and error handling
5. **Framework Coupling**: Avoid tight coupling to Apple's Compression Framework

### Requirements

- Algorithms must be interchangeable at runtime based on user input
- New algorithms should be addable without modifying engine code
- Each algorithm should be testable independently
- Error handling should be consistent across algorithms

---

## Decision

We will use **Protocol-Based Abstraction** to define a common interface for all compression algorithms and implement each algorithm as a separate class conforming to this protocol.

### Protocol Definition

```swift
protocol CompressionAlgorithmProtocol {
    /// Algorithm name (e.g., "lzfse", "lz4", "zlib", "lzma")
    var name: String { get }

    /// Compress data in-memory (for small data)
    func compress(input: Data) throws -> Data

    /// Decompress data in-memory (for small data)
    func decompress(input: Data) throws -> Data

    /// Stream-based compression (for large files)
    func compressStream(
        input: InputStream,
        output: OutputStream,
        bufferSize: Int
    ) throws

    /// Stream-based decompression (for large files)
    func decompressStream(
        input: InputStream,
        output: OutputStream,
        bufferSize: Int
    ) throws
}
```

### Algorithm Registry

A registry pattern manages algorithm instances and enables runtime selection:

```swift
class AlgorithmRegistry {
    private var algorithms: [String: CompressionAlgorithmProtocol] = [:]

    func register(_ algorithm: CompressionAlgorithmProtocol) {
        algorithms[algorithm.name.lowercased()] = algorithm
    }

    func algorithm(named: String) -> CompressionAlgorithmProtocol? {
        return algorithms[named.lowercased()]
    }

    var supportedAlgorithms: [String] {
        return Array(algorithms.keys).sorted()
    }
}
```

### Algorithm Implementations

Each algorithm is implemented as a separate class:

```swift
final class LZFSEAlgorithm: CompressionAlgorithmProtocol {
    let name = "lzfse"

    func compress(input: Data) throws -> Data {
        // Apple Compression Framework integration
    }

    func decompress(input: Data) throws -> Data {
        // Apple Compression Framework integration
    }

    // Stream methods...
}

final class LZ4Algorithm: CompressionAlgorithmProtocol {
    let name = "lz4"
    // Implementation...
}

// ZlibAlgorithm, LZMAAlgorithm, etc.
```

### Registration at Startup

Algorithms are registered in `main.swift`:

```swift
// main.swift
let registry = AlgorithmRegistry()
registry.register(LZFSEAlgorithm())
registry.register(LZ4Algorithm())
registry.register(ZlibAlgorithm())
registry.register(LZMAAlgorithm())

let compressionEngine = CompressionEngine(algorithmRegistry: registry, ...)
```

### Usage in Engine

```swift
class CompressionEngine {
    let algorithmRegistry: AlgorithmRegistry

    func compress(inputPath: String, outputPath: String, algorithmName: String) throws {
        guard let algorithm = algorithmRegistry.algorithm(named: algorithmName) else {
            throw DomainError.invalidAlgorithmName(
                name: algorithmName,
                supported: algorithmRegistry.supportedAlgorithms
            )
        }

        try algorithm.compressStream(input: ..., output: ..., bufferSize: ...)
    }
}
```

---

## Rationale

### Why Protocol-Based Abstraction?

**1. Open/Closed Principle**
- System is open for extension (add new algorithms)
- Closed for modification (no changes to engine or existing algorithms)

**2. Dependency Inversion Principle**
- High-level compression engine depends on protocol abstraction
- Low-level algorithm implementations depend on same abstraction
- No direct dependency on concrete implementations

**3. Single Responsibility Principle**
- Each algorithm class has one responsibility: implement specific compression
- Registry has one responsibility: manage algorithm instances
- Engine has one responsibility: orchestrate compression operations

**4. Testability**
- Mock algorithms for testing engine logic
- Test each algorithm implementation independently
- Test registry behavior without real algorithms

**5. Extensibility**
- Adding new algorithm: Create new class implementing protocol
- No modification to existing code
- Register in main.swift
- Immediately available via `-m` flag

### Why Registry Pattern?

**1. Centralized Management**
- Single source of truth for available algorithms
- Easy to query supported algorithms for help text
- Consistent algorithm lookup

**2. Runtime Selection**
- Algorithm determined by user input at runtime
- No need for large switch statements
- O(1) lookup time

**3. Flexibility**
- Algorithms can be conditionally registered (e.g., based on OS version)
- Easy to implement algorithm aliases (e.g., "deflate" → "zlib")
- Future: Could load algorithms from plugins

### Alternative Approaches Considered

**1. Enum with Associated Values**
```swift
enum CompressionAlgorithm {
    case lzfse
    case lz4
    case zlib
    case lzma

    func compress(input: Data) throws -> Data {
        switch self {
        case .lzfse: // implementation
        case .lz4: // implementation
        // ...
        }
    }
}
```

**Rejected Because**:
- Violates Open/Closed Principle (must modify enum to add algorithm)
- All algorithm code in one large enum
- Harder to test individual algorithms
- Switch statements throughout codebase

**2. Class Hierarchy with Inheritance**
```swift
class CompressionAlgorithm {
    func compress(input: Data) throws -> Data {
        fatalError("Must override")
    }
}

class LZFSEAlgorithm: CompressionAlgorithm {
    override func compress(input: Data) throws -> Data {
        // implementation
    }
}
```

**Rejected Because**:
- Inheritance creates tight coupling
- Base class has no meaningful implementation
- Swift protocols are more idiomatic
- Protocols support composition better than inheritance

**3. Function Pointers / Closures**
```swift
struct CompressionAlgorithm {
    let name: String
    let compress: (Data) throws -> Data
    let decompress: (Data) throws -> Data
}
```

**Rejected Because**:
- Harder to test (can't easily mock closures)
- No type safety for algorithm implementations
- Loses object-oriented benefits (encapsulation, state)
- Less discoverable in code

---

## Consequences

### Positive

1. **Easy to Add Algorithms**
   - Create new class implementing protocol
   - Register in main.swift
   - No other code changes needed

2. **Highly Testable**
   - Mock algorithms for engine tests
   - Test each algorithm independently
   - Test registry behavior in isolation

3. **Clear Separation**
   - Algorithm logic isolated in dedicated classes
   - No leakage into engine or application code
   - Each algorithm is self-contained

4. **Runtime Flexibility**
   - Algorithm selected dynamically based on user input
   - Easy to validate algorithm names
   - Simple to list supported algorithms

5. **Type Safety**
   - Compiler enforces protocol conformance
   - All algorithms guaranteed to have required methods
   - Refactoring supported by compiler

6. **Consistent Error Handling**
   - All algorithms throw typed errors
   - Uniform error handling in engine
   - Consistent user experience

### Negative

1. **Boilerplate**
   - Each algorithm requires separate class file
   - Protocol definition adds code
   - Registry adds additional layer

2. **Indirection**
   - Algorithm lookup through registry
   - Protocol dispatch has minor performance cost (negligible for I/O-bound operations)

3. **Registration Requirement**
   - Must remember to register new algorithms
   - Runtime error if algorithm not registered (mitigated by tests)

### Neutral

1. **File Count**
   - More files (one per algorithm)
   - Offset by improved organization

2. **Learning Curve**
   - Developers must understand protocol pattern
   - Standard Swift pattern, widely understood

---

## Implementation Guide

### Step 1: Define Protocol

Create protocol in Domain layer:
```swift
// Sources/Domain/Protocols/CompressionAlgorithm.swift
protocol CompressionAlgorithmProtocol {
    var name: String { get }
    func compress(input: Data) throws -> Data
    func decompress(input: Data) throws -> Data
    func compressStream(input: InputStream, output: OutputStream, bufferSize: Int) throws
    func decompressStream(input: InputStream, output: OutputStream, bufferSize: Int) throws
}
```

### Step 2: Create Registry

Implement registry in Domain layer:
```swift
// Sources/Domain/AlgorithmRegistry.swift
class AlgorithmRegistry {
    private var algorithms: [String: CompressionAlgorithmProtocol] = [:]
    // Implementation...
}
```

### Step 3: Implement Algorithms

Create infrastructure implementations:
```swift
// Sources/Infrastructure/Algorithms/LZFSEAlgorithm.swift
final class LZFSEAlgorithm: CompressionAlgorithmProtocol {
    let name = "lzfse"
    // Apple Compression Framework integration
}
```

### Step 4: Register Algorithms

Wire up in main.swift:
```swift
let registry = AlgorithmRegistry()
registry.register(LZFSEAlgorithm())
registry.register(LZ4Algorithm())
registry.register(ZlibAlgorithm())
registry.register(LZMAAlgorithm())
```

### Step 5: Use in Engine

Update engine to use registry:
```swift
class CompressionEngine {
    let algorithmRegistry: AlgorithmRegistry

    func compress(..., algorithmName: String) throws {
        guard let algorithm = algorithmRegistry.algorithm(named: algorithmName) else {
            throw DomainError.invalidAlgorithmName(...)
        }
        try algorithm.compressStream(...)
    }
}
```

### Step 6: Test Coverage

Create tests:
- Unit tests for each algorithm implementation
- Unit tests for registry behavior
- Mock algorithm for engine tests
- Integration tests with real algorithms

---

## Validation Criteria

This decision is successfully implemented when:

1. **New Algorithm Test**: Adding new algorithm requires only:
   - Creating new class implementing protocol
   - Registering in main.swift
   - No other code changes

2. **Test Coverage**: All algorithms have 85%+ test coverage

3. **Engine Independence**: Compression engine has no knowledge of specific algorithm implementations

4. **Registry Functionality**: Registry correctly handles:
   - Case-insensitive lookup
   - Missing algorithm errors
   - List of supported algorithms

5. **Error Handling**: All algorithms throw consistent error types

6. **Performance**: Protocol dispatch overhead is negligible (< 1% of execution time)

---

## Future Enhancements

### Phase 2: Algorithm Auto-Detection

Use registry to map file extensions to algorithms:
```swift
extension AlgorithmRegistry {
    func algorithmForExtension(_ ext: String) -> CompressionAlgorithmProtocol? {
        let mapping = [".lzfse": "lzfse", ".lz4": "lz4", ...]
        return mapping[ext].flatMap { algorithm(named: $0) }
    }
}
```

### Phase 3: Algorithm Metadata

Extend protocol with metadata:
```swift
protocol CompressionAlgorithmProtocol {
    var name: String { get }
    var displayName: String { get }
    var fileExtension: String { get }
    var compressionLevelRange: ClosedRange<Int>? { get }
    // ...
}
```

### Phase 4: Plugin Support

Enable loading algorithms from external bundles:
```swift
extension AlgorithmRegistry {
    func loadPlugin(from bundle: Bundle) {
        // Load algorithm implementations dynamically
    }
}
```

---

## Related Decisions

- **ADR-001**: Clean Architecture (protocol-based abstraction supports layer isolation)
- **ADR-003**: Stream-Based Processing (algorithms implement stream processing)
- **ADR-004**: Dependency Injection (algorithms injected via registry)

---

## References

- [Protocol-Oriented Programming in Swift](https://developer.apple.com/videos/play/wwdc2015/408/)
- [Strategy Pattern](https://en.wikipedia.org/wiki/Strategy_pattern)
- [Registry Pattern](https://martinfowler.com/eaaCatalog/registry.html)
- [Open/Closed Principle](https://en.wikipedia.org/wiki/Open%E2%80%93closed_principle)

---

## Review and Approval

**Proposed by**: Architecture Team
**Reviewed by**: Development Team
**Approved by**: Technical Lead
**Date**: 2025-10-07

This pattern provides excellent extensibility and testability while maintaining clean separation of concerns.
