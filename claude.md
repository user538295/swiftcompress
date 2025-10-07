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
- **Dependencies**: CocoaPods for CLI argument parsing
- **Testing**: XCTest with 85%+ coverage target

Always use context7 when I need code generation, setup or configuration steps, or
library/API documentation. This means you should automatically use the Context7 MCP
tools to resolve library id and get library docs without me having to explicitly ask.

## Architecture Documentation

Comprehensive architectural documentation has been created. **Start with [README.md](./README.md)** for the complete overview.

### Core Documentation Files

1. **[README.md](./README.md)** - Architecture overview, roadmap, and quick reference
2. **[architecture_overview.md](./architecture_overview.md)** - System design and architectural approach
3. **[component_specifications.md](./component_specifications.md)** - Detailed component contracts
4. **[module_structure.md](./module_structure.md)** - File organization and project structure
5. **[error_handling_strategy.md](./error_handling_strategy.md)** - Error handling patterns
6. **[testing_strategy.md](./testing_strategy.md)** - Testing approach and requirements
7. **[data_flow_diagrams.md](./data_flow_diagrams.md)** - Visual data flow representations

### Architecture Decision Records (ADRs)

- **[ADR-001](./ADRs/ADR-001-clean-architecture.md)** - Clean Architecture for CLI tool
- **[ADR-002](./ADRs/ADR-002-protocol-abstraction.md)** - Protocol-based algorithm abstraction
- **[ADR-003](./ADRs/ADR-003-stream-processing.md)** - Stream-based file processing
- **[ADR-004](./ADRs/ADR-004-dependency-injection.md)** - Dependency injection strategy
- **[ADR-005](./ADRs/ADR-005-explicit-algorithm-selection.md)** - Explicit algorithm selection

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

Architecture complete. Implementation pending. Follow the 4-week roadmap in [README.md](./README.md):

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

### 📋 Phase 1: MVP Implementation (Target: 4 weeks)

#### Week 1: Foundation Layer
- [ ] Define all protocol interfaces
- [ ] Implement FilePathResolver
- [ ] Implement ValidationRules
- [ ] Implement AlgorithmRegistry
- [ ] Define error types (all layers)
- [ ] Unit tests (90%+ coverage)

#### Week 2: Infrastructure Layer
- [ ] FileSystemHandler implementation
- [ ] StreamProcessor implementation
- [ ] Algorithm implementations (LZFSE, LZ4, Zlib, LZMA)
- [ ] Apple Compression Framework integration
- [ ] Unit and integration tests

#### Week 3: Application & CLI Layers
- [ ] CompressCommand & DecompressCommand
- [ ] CommandExecutor
- [ ] ErrorHandler (error translation)
- [ ] ArgumentParser (CocoaPods integration)
- [ ] CommandRouter & OutputFormatter
- [ ] Dependency wiring in main.swift
- [ ] Layer tests

#### Week 4: Testing & Polish
- [ ] E2E tests (full CLI invocations)
- [ ] Integration testing across layers
- [ ] Performance testing (large files)
- [ ] Error scenario coverage
- [ ] User documentation
- [ ] Achieve 85%+ test coverage

### 🔮 Phase 2: Usability Improvements
- [ ] Algorithm auto-detection from file extension
- [ ] Enhanced help system
- [ ] Overwrite protection with `-f` flag
- [ ] Improved error messages

### 🚀 Phase 3: Advanced Features
- [ ] stdin/stdout streaming support
- [ ] Compression level flags (`--fast`, `--best`)
- [ ] Progress indicators

## Output Policy

- **Quiet by default**: Success produces no stdout
- **Errors**: Printed to stderr with clear, actionable messages
- **Exit codes**: `0` = success, `1` = failure (MVP), expanded codes in Phase 2

## Getting Started

**For Architecture Review:** Start with [README.md](./README.md)

**For Implementation:**
1. Review all architectural documentation
2. Set up Xcode project structure (see [module_structure.md](./module_structure.md))
3. Configure CocoaPods for CLI parsing
4. Begin Week 1 tasks (Foundation layer)
5. Follow TDD approach with 85%+ coverage target

## Quality Gates

Before MVP completion:
- [ ] All 4 layers properly separated
- [ ] Dependencies point inward only
- [ ] 85%+ test coverage
- [ ] All 4 algorithms working
- [ ] Round-trip compression preserves data
- [ ] Large files (>100 MB) process successfully
- [ ] Memory usage < 100 MB regardless of file size
