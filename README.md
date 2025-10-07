# SwiftCompress - Architecture Documentation

**Version**: 1.0
**Date**: 2025-10-07
**Status**: Architecture Complete - Ready for Implementation

---

## Project Overview

SwiftCompress is a macOS command-line tool for compressing and decompressing files using Apple's native Compression Framework. The tool supports multiple compression algorithms (LZFSE, LZ4, Zlib, LZMA) and is designed following Clean Architecture principles.

### Key Characteristics

- **Platform**: macOS only
- **Language**: Swift
- **Architecture**: Clean Architecture with 4 layers
- **Dependency Management**: CocoaPods
- **Core Framework**: Apple Compression Framework
- **Target Users**: CLI users, scripters, power users

---

## Documentation Structure

This architecture documentation is organized into multiple comprehensive documents. Start with the overview and then dive into specific areas as needed.

### Core Documentation

#### 1. [Architecture Overview](./architecture_overview.md)
**Start here for system understanding**

- Executive summary of architectural approach
- High-level component architecture
- Layer responsibilities and boundaries
- Design patterns applied
- Key architectural principles
- SOLID principles application
- Extensibility roadmap

**Read this to**: Understand the overall system design and architectural decisions.

---

#### 2. [Component Specifications](./component_specifications.md)
**Detailed component contracts and responsibilities**

- CLI Interface Layer components (ArgumentParser, CommandRouter, OutputFormatter)
- Application Layer components (CompressCommand, DecompressCommand, ErrorHandler)
- Domain Layer components (CompressionEngine, AlgorithmRegistry, FilePathResolver)
- Infrastructure Layer components (FileSystemHandler, StreamProcessor, Algorithms)
- Interface contracts (protocols)
- Component interactions
- Implementation guidelines for each component

**Read this to**: Understand what each component does and how to implement it.

---

#### 3. [Module Structure](./module_structure.md)
**File and directory organization**

- Complete directory structure
- File naming conventions
- Module organization by layer
- Test organization
- Xcode project structure
- CocoaPods configuration
- Access control guidelines
- Code organization best practices

**Read this to**: Know where to place files and how to organize code.

---

#### 4. [Error Handling Strategy](./error_handling_strategy.md)
**Comprehensive error handling approach**

- Error type hierarchy (Infrastructure, Domain, Application, CLI errors)
- Error propagation patterns
- Error translation strategy
- User-facing error messages
- Exit code strategy
- Error testing approach
- Debugging guidelines

**Read this to**: Understand how to handle errors throughout the system.

---

#### 5. [Testing Strategy](./testing_strategy.md)
**Testing approach and requirements**

- Testing philosophy and principles
- Testing pyramid (60% unit, 30% integration, 10% E2E)
- Unit testing patterns by layer
- Integration testing approach
- End-to-end testing with CLI invocation
- Mocking and stubbing guidelines
- Test data management
- Coverage requirements (85%+)
- Performance testing

**Read this to**: Learn how to test each component and meet quality standards.

---

#### 6. [Data Flow Diagrams](./data_flow_diagrams.md)
**Visual representation of data flow**

- Compression flow (step-by-step)
- Decompression flow (step-by-step)
- Error propagation flow
- Argument parsing flow
- File path resolution flow
- Stream processing flow
- Algorithm selection flow
- Complete end-to-end flows

**Read this to**: Visualize how data moves through the system during operations.

---

### Architecture Decision Records (ADRs)

ADRs document key architectural decisions with context, rationale, and consequences.

#### [ADR-001: Clean Architecture for CLI Tool](./ADRs/ADR-001-clean-architecture.md)
- **Decision**: Adopt Clean Architecture with 4 layers
- **Rationale**: Testability, maintainability, separation of concerns
- **Status**: Accepted

#### [ADR-002: Protocol-Based Algorithm Abstraction](./ADRs/ADR-002-protocol-abstraction.md)
- **Decision**: Use Swift protocols for compression algorithm abstraction
- **Rationale**: Open/Closed Principle, easy extensibility, testability
- **Status**: Accepted

#### [ADR-003: Stream-Based File Processing](./ADRs/ADR-003-stream-processing.md)
- **Decision**: Process files as streams with 64 KB buffer size
- **Rationale**: Scalability to large files, constant memory usage
- **Status**: Accepted

#### [ADR-004: Dependency Injection Strategy](./ADRs/ADR-004-dependency-injection.md)
- **Decision**: Constructor-based DI with manual wiring in main.swift
- **Rationale**: Explicitness, testability, compile-time safety
- **Status**: Accepted

#### [ADR-005: Explicit Algorithm Selection (MVP)](./ADRs/ADR-005-explicit-algorithm-selection.md)
- **Decision**: Require explicit `-m` flag in MVP, add auto-detection in Phase 2
- **Rationale**: Simplicity for MVP, progressive enhancement
- **Status**: Accepted with planned evolution

---

## Quick Reference

### Project Phases

#### Phase 1: MVP (Core Functionality)
- Compress and decompress single files
- Four algorithms: LZFSE, LZ4, Zlib, LZMA
- Explicit algorithm selection required (`-m` flag)
- Default output path generation
- Basic error handling
- Exit codes

**Target**: 4 weeks

#### Phase 2: Usability Improvements
- Algorithm auto-detection from file extension (decompression only)
- Enhanced help system
- Overwrite protection with `-f` flag
- Improved error messages

**Target**: 2 weeks

#### Phase 3: Advanced Features
- stdin/stdout streaming support
- Compression level tuning
- Progress indicators
- Batch operations (future consideration)

**Target**: TBD based on user feedback

---

### Layer Responsibilities at a Glance

```
┌─────────────────────────────────────────────────────┐
│           CLI Interface Layer                        │
│  - Parse command-line arguments                      │
│  - Route commands                                    │
│  - Format output                                     │
│  - Set exit codes                                    │
└───────────────┬─────────────────────────────────────┘
                │ Depends on ▼
┌───────────────▼─────────────────────────────────────┐
│         Application Layer                            │
│  - Orchestrate compression/decompression workflows   │
│  - Coordinate domain services                        │
│  - Handle application-level errors                   │
│  - Manage cross-cutting concerns                     │
└───────────────┬─────────────────────────────────────┘
                │ Depends on ▼
┌───────────────▼─────────────────────────────────────┐
│          Domain Layer (Core Business Logic)          │
│  - Compression engine orchestration                  │
│  - Algorithm registry and selection                  │
│  - File path resolution                              │
│  - Business rules and validation                     │
│  - Protocol definitions                              │
└───────────────┬─────────────────────────────────────┘
                │ Implemented by ▼
┌───────────────▼─────────────────────────────────────┐
│       Infrastructure Layer                           │
│  - Apple Compression Framework integration           │
│  - File system operations (FileManager)              │
│  - Stream processing                                 │
│  - Concrete algorithm implementations                │
└─────────────────────────────────────────────────────┘
```

**Dependency Rule**: Dependencies point inward. Domain layer has no outward dependencies.

---

### Key Design Patterns

| Pattern | Location | Purpose |
|---------|----------|---------|
| **Clean Architecture** | Overall | Layer separation, testability |
| **Command Pattern** | Application Layer | Encapsulate operations (compress, decompress) |
| **Strategy Pattern** | Infrastructure | Interchangeable compression algorithms |
| **Registry Pattern** | Domain | Manage algorithm instances |
| **Adapter Pattern** | Infrastructure | Wrap Apple Compression Framework |
| **Dependency Injection** | Throughout | Provide dependencies via constructors |
| **Template Method** | Stream Processing | Define processing workflow |

---

### Technology Stack

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| Language | Swift 5.9+ | Native macOS development, type safety |
| Compression | Apple Compression Framework | Native, optimized, no external deps |
| Dependency Management | CocoaPods | Established, widely used |
| CLI Parsing | Third-party via CocoaPods | Professional argument parsing |
| Testing | XCTest | Native Swift testing framework |
| CI/CD | GitHub Actions | Automation (future) |

---

## Implementation Roadmap

### Week 1: Foundation Layer
**Priority**: Protocols and Domain Logic

1. Define all protocol interfaces (Domain/Protocols/)
2. Implement FilePathResolver (pure logic, no I/O)
3. Implement ValidationRules (pure logic)
4. Implement AlgorithmRegistry
5. Define error types (all layers)
6. Write unit tests for above

**Deliverable**: Core domain logic with 90%+ test coverage

---

### Week 2: Infrastructure Layer
**Priority**: System Integration

1. Implement FileSystemHandler (FileManager wrapper)
2. Implement StreamProcessor (stream handling)
3. Implement algorithm classes (LZFSE, LZ4, Zlib, LZMA)
4. Integrate with Apple Compression Framework
5. Write unit tests for infrastructure components
6. Write integration tests with real file system

**Deliverable**: Working compression/decompression with real files

---

### Week 3: Application and CLI Layers
**Priority**: User Interface and Workflows

1. Implement CompressCommand and DecompressCommand
2. Implement CommandExecutor
3. Implement ErrorHandler (error translation)
4. Implement ArgumentParser (integrate CocoaPods library)
5. Implement CommandRouter
6. Implement OutputFormatter
7. Wire dependencies in main.swift
8. Write unit tests for application and CLI layers

**Deliverable**: Working CLI tool end-to-end

---

### Week 4: Testing, Polish, Documentation
**Priority**: Quality and Usability

1. Write E2E tests (full CLI invocations)
2. Integration testing across all layers
3. Performance testing (large files)
4. Error scenario coverage
5. User-facing documentation (usage, examples)
6. Code review and refinements
7. Achieve 85%+ overall test coverage

**Deliverable**: Production-ready MVP

---

## Quality Gates

Before considering implementation complete, verify:

### Architecture Compliance
- [ ] All components in correct layer
- [ ] Dependencies point inward only
- [ ] No circular dependencies
- [ ] Protocols defined in Domain layer
- [ ] Infrastructure implements Domain protocols

### Code Quality
- [ ] All components have unit tests
- [ ] Overall test coverage ≥ 85%
- [ ] All error scenarios tested
- [ ] Code passes linting (SwiftLint recommended)
- [ ] All public APIs documented

### Functionality
- [ ] Compression works for all 4 algorithms
- [ ] Decompression works for all 4 algorithms
- [ ] Round-trip compression/decompression preserves data
- [ ] Large files (> 100 MB) process successfully
- [ ] Error messages are clear and actionable
- [ ] Exit codes set correctly

### Performance
- [ ] 100 MB file compresses in < 5 seconds
- [ ] Memory usage < 100 MB regardless of file size
- [ ] Compression ratio comparable to native tools

### Usability
- [ ] `--help` displays clear usage information
- [ ] Error messages guide users to solutions
- [ ] Default output paths work as expected
- [ ] `-f` flag overwrite protection works

---

## Development Guidelines

### Code Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftLint for consistency (recommended configuration TBD)
- Maximum line length: 120 characters
- Prefer explicitness over cleverness
- Document all public APIs with `///` comments

### Naming Conventions

- **Protocols**: `<Name>Protocol` (e.g., `CompressionAlgorithmProtocol`)
- **Implementations**: `<Name>` (e.g., `LZFSEAlgorithm`)
- **Commands**: `<Action>Command` (e.g., `CompressCommand`)
- **Errors**: `<Layer>Error` (e.g., `DomainError`, `InfrastructureError`)
- **Tests**: `<Component>Tests` (e.g., `CompressCommandTests`)
- **Mocks**: `Mock<Component>` (e.g., `MockFileHandler`)

### Testing Requirements

- Write tests alongside implementation (TDD encouraged)
- Minimum 85% code coverage overall
- All error paths must be tested
- Integration tests for multi-component interactions
- E2E tests for critical user workflows

### Git Workflow

- Feature branches: `feature/<component-name>`
- Create PR for each component or logical unit
- All tests must pass before merge
- Code review required before merge

---

## Common Patterns and Examples

### Dependency Injection Pattern

```swift
// Good: Constructor injection
class CompressCommand {
    private let engine: CompressionEngineProtocol
    private let fileHandler: FileHandlerProtocol

    init(
        inputPath: String,
        algorithmName: String,
        compressionEngine: CompressionEngineProtocol,
        fileHandler: FileHandlerProtocol
    ) {
        self.engine = compressionEngine
        self.fileHandler = fileHandler
    }
}

// Usage in main.swift
let engine = CompressionEngine(...)
let fileHandler = FileSystemHandler()
let command = CompressCommand(
    inputPath: "file.txt",
    algorithmName: "lzfse",
    compressionEngine: engine,
    fileHandler: fileHandler
)
```

### Error Handling Pattern

```swift
// Infrastructure throws specific errors
func compress(input: Data) throws -> Data {
    do {
        return try appleFrameworkCompress(input)
    } catch {
        throw InfrastructureError.compressionFailed(
            algorithm: name,
            reason: error.localizedDescription
        )
    }
}

// Application catches and translates
func execute() throws -> CommandResult {
    do {
        try engine.compress(...)
        return .success(message: nil)
    } catch let error as SwiftCompressError {
        return .failure(error: error)
    }
}

// CLI formats for user
let userError = errorHandler.handle(error)
fputs("\(userError.message)\n", stderr)
exit(userError.exitCode)
```

### Testing Pattern

```swift
class CompressCommandTests: XCTestCase {
    var command: CompressCommand!
    var mockEngine: MockCompressionEngine!
    var mockFileHandler: MockFileHandler!

    override func setUp() {
        super.setUp()
        mockEngine = MockCompressionEngine()
        mockFileHandler = MockFileHandler()
        command = CompressCommand(
            inputPath: "/test.txt",
            algorithmName: "lzfse",
            compressionEngine: mockEngine,
            fileHandler: mockFileHandler
        )
    }

    func testExecute_FileNotFound_ThrowsError() {
        // Arrange
        mockFileHandler.fileExistsResult = false

        // Act & Assert
        XCTAssertThrowsError(try command.execute())
    }
}
```

---

## Troubleshooting Common Issues

### Issue: Circular dependency between layers
**Solution**: Review dependency direction. Inner layers should never import outer layers.

### Issue: Component has too many dependencies (> 5)
**Solution**: Consider refactoring. May violate Single Responsibility Principle.

### Issue: Tests fail with file system errors
**Solution**: Use temporary directories. Clean up in `tearDown()`.

### Issue: Can't decide which layer a component belongs to
**Solution**: Ask: Does it contain business logic (Domain), orchestrate workflows (Application), interact with external systems (Infrastructure), or handle user interface (CLI)?

---

## Getting Help

### Documentation
- Start with [Architecture Overview](./architecture_overview.md)
- Check relevant [ADR](./ADRs/) for specific decisions
- Review [Component Specifications](./component_specifications.md) for implementation details

### Code Examples
- Refer to [Data Flow Diagrams](./data_flow_diagrams.md) for operation flows
- See [Testing Strategy](./testing_strategy.md) for test examples

### Architecture Questions
- Review SOLID principles in [Architecture Overview](./architecture_overview.md)
- Check [ADRs](./ADRs/) for rationale behind decisions
- Refer to Clean Architecture resources

---

## Success Criteria

This architecture is successfully implemented when:

1. **Functional**: All MVP user stories completed and tested
2. **Testable**: 85%+ test coverage across all layers
3. **Maintainable**: New developers can understand and contribute within 1 week
4. **Extensible**: New compression algorithm can be added in < 1 hour
5. **Reliable**: All error scenarios handled gracefully
6. **Performant**: Handles files up to several GB without memory issues

---

## Next Steps for Implementation Team

1. **Review all documentation** (start with Architecture Overview)
2. **Set up development environment** (Xcode, CocoaPods)
3. **Create project structure** (following Module Structure guide)
4. **Begin with Week 1 roadmap** (Foundation Layer)
5. **Follow TDD approach** (write tests first)
6. **Regular architecture reviews** (ensure compliance with patterns)

---

## Appendix: File Checklist

Use this checklist to verify all architectural documentation files are present:

- [x] README.md (this file)
- [x] architecture_overview.md
- [x] component_specifications.md
- [x] module_structure.md
- [x] error_handling_strategy.md
- [x] testing_strategy.md
- [x] data_flow_diagrams.md
- [x] ADRs/ADR-001-clean-architecture.md
- [x] ADRs/ADR-002-protocol-abstraction.md
- [x] ADRs/ADR-003-stream-processing.md
- [x] ADRs/ADR-004-dependency-injection.md
- [x] ADRs/ADR-005-explicit-algorithm-selection.md

---

## Document Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-10-07 | Initial architecture documentation complete |

---

**Ready to build!** This comprehensive architecture provides everything needed to implement a production-quality CLI compression tool following industry best practices.
