# ADR-004: Dependency Injection Strategy

**Status**: Accepted

**Date**: 2025-10-07

---

## Context

SwiftCompress follows Clean Architecture with clear layer separation. Components in outer layers depend on inner layer abstractions (protocols), and infrastructure components implement these protocols.

### Dependency Management Challenges

1. **Coupling**: How do we wire concrete implementations without creating tight coupling?
2. **Testing**: How do we substitute mock implementations for testing?
3. **Configuration**: How do we initialize components with their dependencies?
4. **Lifecycle**: When and where should dependencies be created?
5. **Flexibility**: How do we make it easy to swap implementations?

### Traditional Approaches

**1. Direct Instantiation (Poor)**
```swift
class CompressCommand {
    let engine = CompressionEngine()  // Tightly coupled
}
```
- Hard to test
- Cannot swap implementations
- Violates Dependency Inversion Principle

**2. Service Locator (Anti-pattern)**
```swift
class CompressCommand {
    let engine = ServiceLocator.shared.get(CompressionEngine.self)
}
```
- Hidden dependencies
- Runtime errors if not configured
- Hard to test
- Global state

**3. Dependency Injection (Recommended)**
```swift
class CompressCommand {
    let engine: CompressionEngineProtocol

    init(engine: CompressionEngineProtocol) {
        self.engine = engine
    }
}
```
- Explicit dependencies
- Easy to test
- Compile-time safety
- Follows Dependency Inversion Principle

---

## Decision

We will use **Constructor-Based Dependency Injection** throughout the application, with manual wiring in `main.swift`. All dependencies are injected through initializers, making them explicit and testable.

### Dependency Injection Pattern

**1. Define Protocol in Domain Layer**
```swift
// Domain/Protocols/FileHandler.swift
protocol FileHandlerProtocol {
    func fileExists(at path: String) -> Bool
    // ...
}
```

**2. Implement in Infrastructure Layer**
```swift
// Infrastructure/FileSystemHandler.swift
final class FileSystemHandler: FileHandlerProtocol {
    func fileExists(at path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
}
```

**3. Inject via Constructor**
```swift
// Application/Commands/CompressCommand.swift
final class CompressCommand {
    private let compressionEngine: CompressionEngineProtocol
    private let fileHandler: FileHandlerProtocol
    private let pathResolver: FilePathResolverProtocol

    init(
        inputPath: String,
        algorithmName: String,
        outputPath: String?,
        forceOverwrite: Bool,
        compressionEngine: CompressionEngineProtocol,
        fileHandler: FileHandlerProtocol,
        pathResolver: FilePathResolverProtocol
    ) {
        self.compressionEngine = compressionEngine
        self.fileHandler = fileHandler
        self.pathResolver = pathResolver
        // Store other parameters
    }
}
```

**4. Wire in main.swift**
```swift
// CLI/main.swift

// Create infrastructure components
let fileHandler = FileSystemHandler()
let streamProcessor = StreamProcessor()

// Create domain components with infrastructure dependencies
let algorithmRegistry = AlgorithmRegistry()
algorithmRegistry.register(LZFSEAlgorithm())
algorithmRegistry.register(LZ4Algorithm())
algorithmRegistry.register(ZlibAlgorithm())
algorithmRegistry.register(LZMAAlgorithm())

let compressionEngine = CompressionEngine(
    algorithmRegistry: algorithmRegistry,
    streamProcessor: streamProcessor
)

let pathResolver = FilePathResolver()
let validationRules = ValidationRules()

// Create application components
let errorHandler = ErrorHandler()
let commandExecutor = CommandExecutor(errorHandler: errorHandler)

// Create CLI components
let argumentParser = ArgumentParser()
let commandRouter = CommandRouter(
    compressionEngine: compressionEngine,
    fileHandler: fileHandler,
    pathResolver: pathResolver,
    commandExecutor: commandExecutor
)

let outputFormatter = OutputFormatter()

// Execute
do {
    let parsedCommand = try argumentParser.parse(CommandLine.arguments)

    guard let command = parsedCommand else {
        // Help or version requested
        exit(0)
    }

    let result = try commandRouter.route(command)

    switch result {
    case .success(let message):
        if let message = message {
            outputFormatter.writeSuccess(message)
        }
        exit(0)

    case .failure(let error):
        let userError = errorHandler.handle(error)
        outputFormatter.writeError(userError)
        exit(userError.exitCode)
    }

} catch {
    fputs("Error: \(error)\n", stderr)
    exit(1)
}
```

### Dependency Graph

```
main.swift (Composition Root)
    │
    ├─> FileSystemHandler
    ├─> StreamProcessor
    │
    ├─> AlgorithmRegistry
    │   ├─> LZFSEAlgorithm
    │   ├─> LZ4Algorithm
    │   ├─> ZlibAlgorithm
    │   └─> LZMAAlgorithm
    │
    ├─> CompressionEngine
    │   ├─> AlgorithmRegistry
    │   └─> StreamProcessor
    │
    ├─> FilePathResolver
    ├─> ValidationRules
    │
    ├─> ErrorHandler
    ├─> CommandExecutor
    │   └─> ErrorHandler
    │
    ├─> ArgumentParser
    │
    ├─> CommandRouter
    │   ├─> CompressionEngine
    │   ├─> FileHandler
    │   ├─> PathResolver
    │   └─> CommandExecutor
    │
    └─> OutputFormatter
```

---

## Rationale

### Why Constructor Injection?

**1. Explicitness**
- All dependencies visible in constructor signature
- Impossible to create object without required dependencies
- Clear from reading code what component needs

**2. Immutability**
- Dependencies injected once at construction
- Stored as private constants (let)
- No risk of dependencies changing during lifetime

**3. Compile-Time Safety**
- Compiler enforces dependency provision
- No runtime dependency resolution failures
- Refactoring supported by type system

**4. Testability**
- Easy to inject mock implementations
- Each component can be tested in isolation
- No global state or singletons

**5. Simple and Explicit**
- No magic or framework required
- Easy to understand and debug
- Follows Swift conventions

### Why Manual Wiring in main.swift?

**1. Single Composition Root**
- All wiring in one place
- Easy to understand object graph
- No hidden dependencies

**2. No Framework Overhead**
- Zero runtime dependency injection framework cost
- Faster compilation
- Simpler debugging

**3. Explicit Configuration**
- Clear initialization order
- Easy to modify for different configurations
- Can create multiple configurations (e.g., testing vs. production)

**4. Suitable for CLI**
- CLI applications have simple, linear startup
- All dependencies created once at startup
- No need for complex lifecycle management

### Alternative Approaches Considered

**1. Dependency Injection Framework (e.g., Swinject, Cleanse)**

**Rejected Because**:
- Overkill for CLI application
- Adds external dependency
- Increases complexity
- Learning curve for team
- Runtime overhead
- CLI has simple dependency graph

**Would Consider If**:
- Application grows significantly (> 50 components)
- Need conditional dependency registration
- Multiple configuration environments
- Complex lifecycle management

**2. Property Injection**
```swift
class CompressCommand {
    var engine: CompressionEngineProtocol!

    init(inputPath: String, ...) {
        // ...
    }
}

let command = CompressCommand(inputPath: "...")
command.engine = compressionEngine  // Set after construction
```

**Rejected Because**:
- Dependencies can be nil (requires !)
- Object in invalid state between init and property setting
- Easy to forget to set dependencies
- Not thread-safe
- Mutable state

**3. Method Injection**
```swift
class CompressCommand {
    func execute(engine: CompressionEngineProtocol) throws {
        // Use engine
    }
}
```

**Rejected Because**:
- Must pass dependencies on every method call
- Verbose
- Easy to pass wrong dependency
- Doesn't work well for multiple methods

**4. Singleton Pattern**
```swift
class CompressionEngine {
    static let shared = CompressionEngine()
}
```

**Rejected Because**:
- Global state
- Hard to test (cannot substitute mocks)
- Tight coupling
- Cannot have multiple configurations
- Violates Single Responsibility (manages own lifecycle)

**5. Protocol Extension with Default Implementation**
```swift
protocol HasCompressionEngine {
    var engine: CompressionEngineProtocol { get }
}

extension HasCompressionEngine {
    var engine: CompressionEngineProtocol {
        return CompressionEngine.shared  // Default
    }
}
```

**Rejected Because**:
- Hidden dependency on singleton
- Hard to test
- Magic behavior (not explicit)

---

## Consequences

### Positive

1. **Highly Testable**
   - Mock implementations easily injected
   - Each component testable in isolation
   - No global state to reset between tests

2. **Explicit Dependencies**
   - Clear what each component depends on
   - Code review shows all dependencies
   - Impossible to forget dependencies

3. **Compile-Time Safety**
   - Type checking ensures correct dependencies
   - Refactoring supported by compiler
   - No runtime dependency resolution errors

4. **No Framework Dependency**
   - No third-party DI framework needed
   - Faster compilation
   - Simpler debugging

5. **Clean Architecture Enforcement**
   - Inner layers depend on abstractions
   - Outer layers provide concrete implementations
   - Dependency Inversion Principle enforced

6. **Easy to Understand**
   - Standard Swift pattern
   - No magic or hidden behavior
   - New developers can quickly understand

### Negative

1. **Verbose main.swift**
   - All wiring code in one file
   - Can become lengthy as application grows
   - Mitigated by: Clear organization, comments

2. **Constructor Parameter Count**
   - Classes with many dependencies have large initializers
   - Can indicate Single Responsibility violation
   - Mitigated by: Refactoring, parameter objects

3. **Manual Wiring**
   - Must manually create and wire all dependencies
   - Easy to forget to update main.swift when adding dependencies
   - Mitigated by: Compiler errors, tests

4. **No Lazy Initialization**
   - All components created at startup
   - Not a problem for CLI (startup is one-time)
   - Could be issue for long-running daemons (not our use case)

### Neutral

1. **Initial Setup Time**
   - Takes time to set up initially
   - Offset by long-term benefits

2. **Refactoring Changes**
   - Changing constructor signature requires updating callers
   - Compiler ensures all call sites updated

---

## Implementation Guide

### Step 1: Define Protocols in Domain Layer

```swift
// Domain/Protocols/FileHandler.swift
protocol FileHandlerProtocol {
    func fileExists(at path: String) -> Bool
    // ...
}
```

### Step 2: Implement in Infrastructure Layer

```swift
// Infrastructure/FileSystemHandler.swift
final class FileSystemHandler: FileHandlerProtocol {
    init() {
        // No dependencies or minimal dependencies
    }

    func fileExists(at path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
}
```

### Step 3: Inject Dependencies in Consumers

```swift
// Application/Commands/CompressCommand.swift
final class CompressCommand {
    private let fileHandler: FileHandlerProtocol

    init(fileHandler: FileHandlerProtocol, ...) {
        self.fileHandler = fileHandler
    }
}
```

### Step 4: Wire in main.swift

```swift
// CLI/main.swift

// 1. Create leaf dependencies (no dependencies)
let fileHandler = FileSystemHandler()

// 2. Create mid-level dependencies
let compressionEngine = CompressionEngine(
    algorithmRegistry: algorithmRegistry,
    streamProcessor: streamProcessor
)

// 3. Create top-level components
let commandRouter = CommandRouter(
    compressionEngine: compressionEngine,
    fileHandler: fileHandler,
    pathResolver: pathResolver,
    commandExecutor: commandExecutor
)

// 4. Execute
let result = try commandRouter.route(parsedCommand)
```

### Step 5: Testing with Mocks

```swift
// Tests/UnitTests/Application/CompressCommandTests.swift
class CompressCommandTests: XCTestCase {
    func testExecute_FileNotFound_ThrowsError() {
        // Arrange
        let mockFileHandler = MockFileHandler()
        mockFileHandler.fileExistsResult = false

        let command = CompressCommand(
            inputPath: "/test.txt",
            algorithmName: "lzfse",
            outputPath: nil,
            forceOverwrite: false,
            compressionEngine: mockEngine,
            fileHandler: mockFileHandler,  // Inject mock
            pathResolver: mockPathResolver
        )

        // Act & Assert
        XCTAssertThrowsError(try command.execute())
    }
}
```

### Guidelines for Constructor Design

**Good Constructor**:
```swift
init(
    // Data parameters first
    inputPath: String,
    algorithmName: String,
    outputPath: String?,

    // Dependencies last
    compressionEngine: CompressionEngineProtocol,
    fileHandler: FileHandlerProtocol
) {
    self.inputPath = inputPath
    self.algorithmName = algorithmName
    self.outputPath = outputPath
    self.compressionEngine = compressionEngine
    self.fileHandler = fileHandler
}
```

**Parameter Ordering**:
1. Required data parameters
2. Optional data parameters
3. Required dependencies
4. Optional dependencies

**Too Many Parameters?**
If > 5 parameters, consider:
- Parameter object pattern
- Checking Single Responsibility Principle
- Breaking into smaller components

---

## Validation Criteria

This decision is successfully implemented when:

1. **No Global State**: No singletons or global variables (except in main.swift)
2. **Explicit Dependencies**: All dependencies injected via constructor
3. **Testability**: All components can be unit tested with mocks
4. **Compilation**: Application compiles with all dependencies satisfied
5. **main.swift Organization**: Clear, organized composition root
6. **Protocol Usage**: All cross-layer dependencies use protocols
7. **No Service Locator**: No global dependency registry or service locator

---

## main.swift Organization Pattern

### Recommended Structure

```swift
// CLI/main.swift

// MARK: - Infrastructure Components
let fileHandler = FileSystemHandler()
let streamProcessor = StreamProcessor()

// MARK: - Algorithm Registry
let algorithmRegistry = AlgorithmRegistry()
algorithmRegistry.register(LZFSEAlgorithm())
algorithmRegistry.register(LZ4Algorithm())
algorithmRegistry.register(ZlibAlgorithm())
algorithmRegistry.register(LZMAAlgorithm())

// MARK: - Domain Components
let compressionEngine = CompressionEngine(
    algorithmRegistry: algorithmRegistry,
    streamProcessor: streamProcessor
)
let pathResolver = FilePathResolver()
let validationRules = ValidationRules()

// MARK: - Application Components
let errorHandler = ErrorHandler()
let commandExecutor = CommandExecutor(errorHandler: errorHandler)

// MARK: - CLI Components
let argumentParser = ArgumentParser()
let commandRouter = CommandRouter(
    compressionEngine: compressionEngine,
    fileHandler: fileHandler,
    pathResolver: pathResolver,
    commandExecutor: commandExecutor
)
let outputFormatter = OutputFormatter()

// MARK: - Execution
do {
    // Parse arguments
    let parsedCommand = try argumentParser.parse(CommandLine.arguments)

    guard let command = parsedCommand else {
        exit(0)  // Help or version
    }

    // Route and execute
    let result = try commandRouter.route(command)

    // Handle result
    switch result {
    case .success(let message):
        if let message = message {
            outputFormatter.writeSuccess(message)
        }
        exit(0)

    case .failure(let error):
        let userError = errorHandler.handle(error)
        outputFormatter.writeError(userError)
        exit(userError.exitCode)
    }

} catch let error as SwiftCompressError {
    let userError = errorHandler.handle(error)
    outputFormatter.writeError(userError)
    exit(userError.exitCode)

} catch {
    fputs("Error: An unexpected error occurred.\n", stderr)
    exit(1)
}
```

---

## Future Considerations

### If Application Grows Significantly

Consider DI framework when:
- More than 50 components
- Complex conditional dependency logic
- Multiple application configurations
- Plugin system with dynamic loading

### Recommended Frameworks (if needed)

- **Swinject**: Pure Swift, well-documented
- **Cleanse**: Type-safe, compile-time validation
- **Swift-DI**: Lightweight, minimal

### Configuration Abstraction

For future configuration needs:

```swift
protocol Configuration {
    var bufferSize: Int { get }
    var defaultAlgorithm: String { get }
}

let config = ProductionConfiguration()
let engine = CompressionEngine(..., configuration: config)
```

---

## Related Decisions

- **ADR-001**: Clean Architecture (DI enforces layer boundaries)
- **ADR-002**: Protocol-Based Algorithm Abstraction (DI uses protocols)
- **ADR-003**: Stream-Based Processing (StreamProcessor injected)

---

## References

- [Dependency Injection in Swift](https://www.swiftbysundell.com/articles/dependency-injection-using-factories-in-swift/)
- [Dependency Inversion Principle](https://en.wikipedia.org/wiki/Dependency_inversion_principle)
- [Constructor Injection](https://martinfowler.com/articles/injection.html)
- [Composition Root Pattern](https://blog.ploeh.dk/2011/07/28/CompositionRoot/)

---

## Review and Approval

**Proposed by**: Architecture Team
**Reviewed by**: Development Team
**Approved by**: Technical Lead
**Date**: 2025-10-07

Constructor-based dependency injection with manual wiring in main.swift provides the right balance of simplicity, testability, and explicitness for a CLI application of this scope.
