# SwiftCompress - Architecture Documentation Hub

**Version**: 1.3
**Status**: ✅ Production Ready (All 4 Phases Complete)
**Last Updated**: 2025-10-10

---

## Overview

SwiftCompress is a production-ready macOS CLI tool for file compression using Apple's native Compression Framework. Built with **Clean Architecture** principles, it provides four compression algorithms (LZFSE, LZ4, ZLIB, LZMA) with stream processing for constant memory usage.

**Key Stats:**
- 411 tests passing (95%+ coverage)
- ~9.6 MB peak memory (independent of file size)
- 4 layers with strict dependency inversion
- Unix pipeline support (stdin/stdout streaming)

---

## Documentation Map

This hub organizes all architectural documentation. Start with the overview, then explore specific areas.

### Core Documentation

| Document | Purpose | When to Read |
|----------|---------|--------------|
| **[Architecture Overview](./architecture_overview.md)** | High-level system design, SOLID principles, design patterns | **Start here** - Understand overall architecture |
| **[Component Specifications](./component_specifications.md)** | Detailed component contracts and interfaces | Implementing specific components |
| **[Module Structure](./module_structure.md)** | File organization and project structure | Setting up or organizing code |
| **[Error Handling Strategy](./error_handling_strategy.md)** | Error types, propagation, and user messages | Implementing error handling |
| **[Testing Strategy](./testing_strategy.md)** | Testing pyramid, patterns, coverage requirements | Writing tests (95%+ coverage) |
| **[Data Flow Diagrams](./data_flow_diagrams.md)** | Visual workflows for compression/decompression | Understanding system behavior |

---

### Architecture Decision Records (ADRs)

All ADRs are implemented and validated. Key decisions:

| ADR | Decision | Status |
|-----|----------|--------|
| [ADR-001](./ADRs/ADR-001-clean-architecture.md) | Clean Architecture with 4 layers | ✅ Implemented |
| [ADR-002](./ADRs/ADR-002-protocol-abstraction.md) | Protocol-based algorithm abstraction | ✅ Implemented |
| [ADR-003](./ADRs/ADR-003-stream-processing.md) | Stream-based processing (64 KB buffers) | ✅ Implemented |
| [ADR-004](./ADRs/ADR-004-dependency-injection.md) | Constructor-based dependency injection | ✅ Implemented |
| [ADR-005](./ADRs/ADR-005-explicit-algorithm-selection.md) | Explicit `-m` flag requirement | ✅ Implemented |
| [ADR-006](./ADRs/ADR-006-compression-stream-api.md) | True streaming with compression_stream | ✅ Validated (9.6 MB peak) |
| [ADR-007](./ADRs/ADR-007-stdin-stdout-streaming.md) | Unix pipeline support | ✅ Implemented |
| [ADR-008](./ADRs/ADR-008-compression-level-support.md) | Compression levels (--fast, --best) | ✅ Implemented |
| [ADR-009](./ADRs/ADR-009-progress-indicator-support.md) | Progress indicators (--progress) | ✅ Implemented |

**For complete rationale and context, see individual ADR files in [ADRs/](./ADRs/).**

---

## Implementation Status

### Project Phases

| Phase | Features | Target | Status |
|-------|----------|--------|--------|
| **Phase 0** | Architecture planning | 2 weeks | ✅ Complete |
| **Phase 1** | MVP (4 algorithms, basic CLI) | 4 weeks | ✅ Complete |
| **Phase 2** | Usability (auto-detection, help) | 2 weeks | ✅ Complete |
| **Phase 3** | Unix pipelines (stdin/stdout) | 4 weeks | ✅ Complete |
| **Phase 4** | Advanced (levels, progress) | 4 weeks | ✅ Complete |

**Current Version**: 1.2.0 (Production Ready)

**For detailed roadmap, milestones, and task breakdown, see [ROADMAP.md](../ROADMAP.md).**

---

### Architecture Quick Reference

**4-Layer Structure:**
```
CLI Interface → Application → Domain → Infrastructure
   (User I/O)   (Workflows)   (Logic)   (System Integration)
```

**Dependency Rule**: All dependencies point inward. Domain layer has zero outward dependencies.

**Design Patterns:**
- Clean Architecture (layer separation)
- Command Pattern (compress/decompress operations)
- Strategy Pattern (interchangeable algorithms)
- Registry Pattern (algorithm management)
- Adapter Pattern (Apple Framework wrapper)
- Dependency Injection (constructor-based)

**Technology Stack:**
- Swift 5.9+ with Swift Package Manager
- Apple Compression Framework (LZFSE, LZ4, ZLIB, LZMA)
- Swift ArgumentParser (CLI)
- XCTest (95%+ coverage)

**For detailed architecture, see [architecture_overview.md](./architecture_overview.md).**

---

## Production Status

**Version**: 1.2.0 - Production Ready (All Phases Complete)

**Quality Metrics:**
- 411 tests passing (0 failures)
- 95%+ test coverage
- ~9.6 MB peak memory (validated with 100 MB files)
- All 4 compression algorithms working
- Unix pipeline support
- Progress indicators
- Compression level control

**Validated Performance:**
- 100 MB compression: 0.67s (LZFSE)
- 100 MB decompression: 0.25s (LZFSE)
- Memory: Constant footprint regardless of file size

---

## Quality Gates Status

All production quality gates passed:

| Category | Criteria | Status |
|----------|----------|--------|
| **Architecture** | Layer separation, dependency inversion | ✅ Verified |
| **Testing** | 95%+ coverage, 411 tests passing | ✅ Achieved |
| **Functionality** | All 4 algorithms, round-trip validation | ✅ Working |
| **Performance** | <5s compression, <100 MB memory | ✅ Validated |
| **Usability** | Clear errors, help system, defaults | ✅ Complete |

---

## Development Guidelines

**Code Style:**
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Maximum line length: 120 characters
- Document public APIs with `///` comments
- Prefer explicitness over cleverness

**Testing Requirements:**
- TDD approach encouraged
- Minimum 85% coverage (currently 95%+)
- Test all error paths
- Integration + E2E tests for critical workflows

**Naming Conventions:**
- Protocols: `<Name>Protocol` (e.g., `CompressionAlgorithmProtocol`)
- Implementations: `<Name>` (e.g., `LZFSEAlgorithm`)
- Commands: `<Action>Command` (e.g., `CompressCommand`)
- Tests: `<Component>Tests` (e.g., `CompressCommandTests`)
- Mocks: `Mock<Component>` (e.g., `MockFileHandler`)

**For detailed patterns and examples, see [component_specifications.md](./component_specifications.md) and [testing_strategy.md](./testing_strategy.md).**

---

## Troubleshooting & Resources

**Common Issues:**

| Issue | Solution |
|-------|----------|
| Circular dependency between layers | Review dependency direction - dependencies point inward only |
| Too many dependencies (>5) | Refactor - may violate Single Responsibility Principle |
| File system test failures | Use temporary directories, clean up in `tearDown()` |
| Unclear layer assignment | Ask: Business logic (Domain)? Workflow (Application)? System I/O (Infrastructure)? User I/O (CLI)? |

**Getting Help:**
- Architecture questions: [architecture_overview.md](./architecture_overview.md)
- Implementation details: [component_specifications.md](./component_specifications.md)
- Decision rationale: [ADRs/](./ADRs/)
- Testing patterns: [testing_strategy.md](./testing_strategy.md)
- Setup instructions: [SETUP.md](../SETUP.md)

---

## For New Contributors

**Getting Started:**

1. Review [architecture_overview.md](./architecture_overview.md) for system design
2. Follow [SETUP.md](../SETUP.md) for development environment
3. Run `swift test` - verify all 411 tests pass
4. Build and test: `swift build -c release`
5. Explore [component_specifications.md](./component_specifications.md) for implementation details

**Success Criteria (All Achieved):**
- ✅ Functional: All features completed and tested
- ✅ Testable: 95%+ test coverage (exceeded 85% target)
- ✅ Maintainable: Clear layer separation, comprehensive docs
- ✅ Extensible: New algorithm can be added in <1 hour
- ✅ Reliable: All error scenarios handled gracefully
- ✅ Performant: Constant memory footprint for files of any size

---

## Document Version History

| Version | Date | Key Changes |
|---------|------|-------------|
| 1.0 | 2025-10-07 | Initial architecture documentation |
| 1.1 | 2025-10-09 | MVP complete (279 tests) |
| 1.2 | 2025-10-10 | True streaming validated (ADR-006) |
| 1.3 | 2025-10-10 | Unix pipelines (ADR-007, 328 tests) |
| 1.4 | 2025-10-10 | Compression levels (ADR-008, 365 tests) |
| 1.5 | 2025-10-10 | Progress indicators (ADR-009, 411 tests) |
| 1.6 | 2025-10-23 | Documentation simplified and improved |

---

**This architecture provides a production-ready foundation for maintainable, testable, and extensible CLI tool development following Clean Architecture and Swift best practices.**
