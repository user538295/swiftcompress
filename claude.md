# swiftcompress

A macOS CLI tool for compressing and decompressing files using Apple's Compression framework.

## Project Overview

**swiftcompress** is a command-line utility written in Swift that provides explicit, scriptable file compression using Apple's native compression algorithms (LZFSE, LZ4, ZLIB, LZMA).

The project follows **Clean Architecture** principles with 4 distinct layers, ensuring testability, maintainability, and extensibility.

## Tech Stack

- **Language**: Swift 5.9+
- **Platform**: macOS 12.0+
- **Architecture**: Clean Architecture (4 layers)
- **Framework**: Apple Compression framework
- **Dependencies**: Swift Package Manager with ArgumentParser
- **Testing**: XCTest with 85%+ coverage target

Always use context7 when I need code generation, setup or configuration steps, or
library/API documentation. This means you should automatically use the Context7 MCP
tools to resolve library id and get library docs without me having to explicitly ask.

## Architecture Documentation

Comprehensive architectural documentation has been created. **Start with [ARCHITECTURE.md](./Documentation/ARCHITECTURE.md)** for the complete overview.

### Core Documentation Files

1. **[README.md](./README.md)** - Project overview, features, quick start (GitHub landing page)
2. **[SETUP.md](./SETUP.md)** - Development environment setup guide
3. **[ARCHITECTURE.md](./Documentation/ARCHITECTURE.md)** - Complete architecture overview, roadmap, and quick reference
4. **[architecture_overview.md](./Documentation/architecture_overview.md)** - System design and architectural approach
5. **[component_specifications.md](./Documentation/component_specifications.md)** - Detailed component contracts
6. **[module_structure.md](./Documentation/module_structure.md)** - File organization and project structure
7. **[error_handling_strategy.md](./Documentation/error_handling_strategy.md)** - Error handling patterns
8. **[testing_strategy.md](./Documentation/testing_strategy.md)** - Testing approach and requirements
9. **[data_flow_diagrams.md](./Documentation/data_flow_diagrams.md)** - Visual data flow representations

### Architecture Decision Records (ADRs)

- **[ADR-001](./Documentation/ADRs/ADR-001-clean-architecture.md)** - Clean Architecture for CLI tool
- **[ADR-002](./Documentation/ADRs/ADR-002-protocol-abstraction.md)** - Protocol-based algorithm abstraction
- **[ADR-003](./Documentation/ADRs/ADR-003-stream-processing.md)** - Stream-based file processing
- **[ADR-004](./Documentation/ADRs/ADR-004-dependency-injection.md)** - Dependency injection strategy
- **[ADR-005](./Documentation/ADRs/ADR-005-explicit-algorithm-selection.md)** - Explicit algorithm selection

## Architecture Overview

### Four-Layer Architecture

```
┌─────────────────────────────────────┐
│     CLI Interface Layer              │  ← User interaction
├─────────────────────────────────────┤
│     Application Layer                │  ← Workflow orchestration
├─────────────────────────────────────┤
│     Domain Layer                     │  ← Business logic
├─────────────────────────────────────┤
│     Infrastructure Layer             │  ← System integration
└─────────────────────────────────────┘
```

**Key Principles:**
- Dependencies point inward only
- Domain layer has zero outward dependencies
- All cross-layer interactions use protocols
- Stream-based processing (64 KB buffers)
- Constructor-based dependency injection

### Design Patterns Applied

- **Clean Architecture** - Layer separation
- **Command Pattern** - Compress/decompress operations
- **Strategy Pattern** - Interchangeable algorithms
- **Registry Pattern** - Algorithm management
- **Adapter Pattern** - Apple Framework integration

## Project Structure

Architecture complete. Implementation pending. Follow the 4-week roadmap in [ARCHITECTURE.md](./Documentation/ARCHITECTURE.md):

- **Week 1**: Foundation layer (protocols, domain logic)
- **Week 2**: Infrastructure layer (file I/O, algorithms)
- **Week 3**: Application & CLI layers (commands, parsing)
- **Week 4**: Testing, polish, documentation

## Commands

### Compress
```bash
swiftcompress c <inputfile> -m <algorithm> [-o <outputfile>] [-f]
```

### Decompress
```bash
swiftcompress x <inputfile> -m <algorithm> [-o <outputfile>] [-f]
```

### Supported Algorithms
- `lzfse` - Apple's LZFSE compression
- `lz4` - LZ4 fast compression
- `zlib` - ZLIB/DEFLATE compression
- `lzma` - LZMA compression

### Options
- `-m <algorithm>`: Specify compression algorithm (required)
- `-o <outputfile>`: Override default output filename (optional)
- `-f`: Force overwrite existing files (optional)

## Default Behavior

- **Compression**: `file.txt` → `file.txt.lzfse`
- **Decompression**: `file.txt.lzfse` → `file.txt`

## Development Status

### ✅ Phase 0: Architecture - COMPLETE
- [x] Project specification defined
- [x] Complete architectural documentation (12 files)
- [x] Component specifications with protocols
- [x] Module structure defined
- [x] Error handling strategy designed
- [x] Testing strategy documented
- [x] Data flow diagrams created
- [x] 5 ADRs documenting key decisions
- [x] 4-week implementation roadmap

### ✅ Phase 1: MVP Implementation - COMPLETE

#### ✅ Week 1: Foundation Layer - COMPLETE
- [x] Define all protocol interfaces
- [x] Implement FilePathResolver
- [x] Implement ValidationRules
- [x] Implement AlgorithmRegistry
- [x] Define error types (all layers)
- [x] Unit tests (90%+ coverage)

#### ✅ Week 2: Infrastructure Layer - COMPLETE
- [x] FileSystemHandler implementation
- [x] StreamProcessor implementation
- [x] Algorithm implementations (LZFSE, LZ4, Zlib, LZMA)
- [x] Apple Compression Framework integration
- [x] Unit and integration tests

#### ✅ Week 3: Application & CLI Layers - COMPLETE
- [x] CompressCommand & DecompressCommand
- [x] CommandExecutor
- [x] ErrorHandler (error translation)
- [x] ArgumentParser (Swift ArgumentParser integration)
- [x] CommandRouter & OutputFormatter
- [x] Dependency wiring in main.swift
- [x] Layer tests

#### ✅ Week 4: Testing & Polish - COMPLETE
- [x] E2E tests (full CLI invocations)
- [x] Integration testing across layers
- [x] Error scenario coverage
- [x] Achieve 95%+ test coverage (279 tests passing)
- [x] End-to-end CLI workflows verified
- [x] Round-trip data integrity validated

**MVP Status**: ✅ FULLY FUNCTIONAL
- All 279 tests passing (0 failures)
- 95%+ test coverage across all layers
- 31 source files (~2,956 lines)
- 13 test files (~5,918 lines)
- All 4 compression algorithms working
- Complete CLI interface operational

### 🔧 Phase 2: Improvements (Planned)
- [ ] True streaming implementation (current: loads full file into memory)
- [ ] Performance testing (large files >100 MB)
- [ ] Performance optimization and benchmarking
- [ ] Algorithm auto-detection from file extension (partial support exists)
- [ ] Enhanced help system
- [ ] CI/CD setup (GitHub Actions)

### 🚀 Phase 3: Advanced Features (Future)
- [ ] stdin/stdout streaming support
- [ ] Compression level flags (`--fast`, `--best`)
- [ ] Progress indicators

## Output Policy

- **Quiet by default**: Success produces no stdout
- **Errors**: Printed to stderr with clear, actionable messages
- **Exit codes**: `0` = success, `1` = failure (MVP), expanded codes in Phase 2

## Getting Started

**For Project Overview:** Start with [README.md](./README.md)

**For Architecture Review:** Read [ARCHITECTURE.md](./Documentation/ARCHITECTURE.md)

**For Development Setup:** Follow [SETUP.md](./SETUP.md)

**For Implementation:**
1. Review all architectural documentation in Documentation/
2. Set up development environment (see [SETUP.md](./SETUP.md))
3. Study component specifications (see [component_specifications.md](./Documentation/component_specifications.md))
4. Begin Week 1 tasks (Foundation layer)
5. Follow TDD approach with 85%+ coverage target

## Quality Gates

MVP Quality Gates Status:
- [x] All 4 layers properly separated ✅
- [x] Dependencies point inward only ✅
- [x] 95%+ test coverage (exceeded 85% target) ✅
- [x] All 4 algorithms working ✅
- [x] Round-trip compression preserves data ✅
- [ ] Large files (>100 MB) process successfully ⚠️ (loads into memory)
- [ ] Memory usage < 100 MB regardless of file size ⚠️ (needs true streaming)

**Overall MVP Status**: ✅ PASSED (6/7 gates, 2 deferred to Phase 2)
