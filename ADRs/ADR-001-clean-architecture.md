# ADR-001: Clean Architecture for CLI Tool

**Status**: Accepted

**Date**: 2025-10-07

---

## Context

SwiftCompress is a macOS command-line tool for file compression and decompression. The tool needs to be:
- **Testable**: All components should be easily unit tested in isolation
- **Maintainable**: Code should be organized logically and easy to understand
- **Extensible**: New features (compression algorithms, commands, etc.) should be easy to add
- **Reliable**: Error handling and edge cases must be robust

Traditional CLI tools often mix concerns, leading to:
- Difficulty testing without invoking the full binary
- Tight coupling between user interface, business logic, and system integration
- Challenges when adding new features
- Hard-to-maintain codebases as complexity grows

We need an architectural approach that addresses these challenges while remaining appropriate for a CLI application.

---

## Decision

We will adopt **Clean Architecture** principles adapted for CLI applications, organizing the codebase into four distinct layers:

### 1. CLI Interface Layer
- Handles command-line argument parsing
- Routes commands to appropriate handlers
- Formats output for terminal display
- Manages process exit codes

### 2. Application Layer
- Orchestrates business workflows (compress/decompress operations)
- Coordinates between domain services
- Handles application-level error translation
- Manages cross-cutting concerns

### 3. Domain Layer
- Contains core business logic and rules
- Defines abstractions (protocols) for external dependencies
- Implements compression engine orchestration
- Validates business rules

### 4. Infrastructure Layer
- Integrates with Apple Compression Framework
- Performs file system operations via FileManager
- Handles binary data streaming
- Provides concrete implementations of domain protocols

### Dependency Rule

**Dependencies point inward**: Outer layers depend on inner layers, never the reverse.

```
CLI → Application → Domain ← Infrastructure
```

The Domain layer has no dependencies on outer layers or frameworks. Infrastructure implements domain-defined protocols.

---

## Rationale

### Why Clean Architecture?

**Testability**:
- Domain layer can be unit tested without any infrastructure
- Application layer can be tested with mocked domain services
- CLI layer can be tested with mocked application services
- Each layer can be tested in isolation

**Separation of Concerns**:
- User interface concerns (CLI) separated from business logic (Domain)
- Business logic separated from system integration (Infrastructure)
- Clear boundaries make code easier to understand and maintain

**Flexibility**:
- Easy to swap infrastructure implementations (e.g., different compression libraries)
- Business rules can evolve without affecting CLI or infrastructure
- New commands can be added without modifying existing code (Open/Closed Principle)

**Dependency Management**:
- Inner layers have no knowledge of outer layers
- Domain layer is framework-agnostic and portable
- Infrastructure dependencies are isolated and contained

### Why Adapted for CLI?

Traditional Clean Architecture is often presented for web or mobile applications. We adapt it for CLI by:
- Treating the CLI interface as the "Presentation Layer"
- Using command pattern for CLI commands
- Simplifying to four layers (appropriate for CLI scope)
- Focusing on synchronous operations (CLI tools are typically synchronous)

### Alternative Approaches Considered

**1. Single-Layer/Script Approach**
- **Rejected**: Difficult to test, hard to maintain, tight coupling
- Suitable only for trivial scripts, not production tools

**2. MVC Pattern**
- **Rejected**: Designed for GUI applications, doesn't fit CLI paradigm
- Unclear separation between Model and Controller for CLI

**3. Layered Architecture (Traditional 3-tier)**
- **Considered**: Good separation, but less emphasis on testability
- Clean Architecture provides better dependency inversion

**4. Hexagonal Architecture (Ports and Adapters)**
- **Considered**: Very similar to Clean Architecture
- Clean Architecture terminology is more widely recognized

---

## Consequences

### Positive

1. **High Testability**
   - All business logic can be unit tested without file system or compression framework
   - Mock implementations enable fast, reliable tests
   - Test coverage can easily exceed 85%

2. **Clear Structure**
   - Developers immediately understand where code belongs
   - Onboarding new team members is faster
   - Code reviews focus on appropriate layer responsibilities

3. **Maintainability**
   - Changes to business logic don't affect CLI parsing or file I/O
   - Changes to compression framework don't affect business rules
   - Each layer can evolve independently

4. **Extensibility**
   - New compression algorithms: Add infrastructure implementation
   - New commands: Add application command class
   - New validations: Add domain validation rules
   - No need to modify existing code (Open/Closed Principle)

5. **Framework Independence**
   - Domain layer could be reused in GUI application
   - Could switch from CocoaPods to Swift Package Manager without affecting domain
   - Business rules portable to other platforms

### Negative

1. **Initial Complexity**
   - More files and classes than simpler approaches
   - Requires understanding of layer boundaries
   - May seem over-engineered for very simple operations

2. **Boilerplate Code**
   - Protocol definitions for all abstractions
   - Mock implementations for testing
   - Dependency injection wiring in main.swift

3. **Learning Curve**
   - Developers unfamiliar with Clean Architecture need ramp-up time
   - Requires discipline to maintain layer boundaries
   - Risk of mixing concerns if guidelines not followed

4. **Performance Overhead**
   - Protocol dispatch has slight performance cost (negligible for CLI)
   - Additional layers add indirection (minimal impact)

### Neutral

1. **Project Size**
   - More files and directories
   - Clear organization offsets increased file count

2. **Dependency Injection**
   - Requires explicit wiring of dependencies in main.swift
   - Makes dependencies explicit and testable

3. **Development Time**
   - Initial development slightly slower due to architecture setup
   - Long-term maintenance and feature additions faster

---

## Implementation Guide

### Step 1: Define Layer Boundaries

Create directory structure:
```
Sources/
├── CLI/              # CLI Interface Layer
├── Application/      # Application Layer
├── Domain/           # Domain Layer
└── Infrastructure/   # Infrastructure Layer
```

### Step 2: Define Domain Protocols

Start with domain layer, defining protocols for all external dependencies:
```swift
// Domain/Protocols/CompressionAlgorithm.swift
protocol CompressionAlgorithmProtocol {
    func compress(input: Data) throws -> Data
    func decompress(input: Data) throws -> Data
}
```

### Step 3: Implement Domain Logic

Implement business logic using protocol abstractions (no concrete infrastructure):
```swift
// Domain/CompressionEngine.swift
class CompressionEngine {
    let algorithmRegistry: AlgorithmRegistryProtocol
    // Uses protocols, not concrete implementations
}
```

### Step 4: Implement Infrastructure

Provide concrete implementations of domain protocols:
```swift
// Infrastructure/Algorithms/LZFSEAlgorithm.swift
class LZFSEAlgorithm: CompressionAlgorithmProtocol {
    // Concrete implementation using Apple framework
}
```

### Step 5: Implement Application Workflows

Create command orchestration:
```swift
// Application/Commands/CompressCommand.swift
class CompressCommand: Command {
    // Orchestrates domain services
}
```

### Step 6: Implement CLI Interface

Wire everything together:
```swift
// CLI/main.swift
// Create all dependencies
// Inject into commands
// Execute
```

### Step 7: Enforce Layer Boundaries

Use code reviews and linting to ensure:
- Domain layer has no import statements except Foundation
- Application layer depends only on Domain protocols
- Infrastructure layer implements Domain protocols
- CLI layer depends only on Application layer

---

## Validation Criteria

This architectural decision is successfully implemented when:

1. **Layer Isolation**: Each layer can be modified without affecting other layers (except through protocol changes)
2. **Test Coverage**: Domain layer achieves 90%+ unit test coverage without any infrastructure
3. **Dependency Direction**: All dependencies point inward (verified via dependency graph)
4. **Framework Independence**: Domain layer has no dependencies on Compression framework or FileManager
5. **Extensibility**: New compression algorithm can be added by creating single Infrastructure class
6. **Code Organization**: Developers can locate any functionality by understanding layer responsibilities

---

## Related Decisions

- **ADR-002**: Protocol-Based Algorithm Abstraction (implements domain abstraction)
- **ADR-003**: Stream-Based Processing (infrastructure implementation detail)
- **ADR-004**: Dependency Injection Strategy (implements Clean Architecture wiring)

---

## References

- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Swift Clean Architecture Examples](https://github.com/kudoleh/iOS-Clean-Architecture-MVVM)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/)

---

## Review and Approval

**Proposed by**: Architecture Team
**Reviewed by**: Development Team
**Approved by**: Technical Lead
**Date**: 2025-10-07

This decision will be reviewed after MVP completion to assess effectiveness and identify any necessary adjustments.
