# SwiftCompress

> A macOS command-line tool for file compression using Apple's native Compression framework

[![Platform](https://img.shields.io/badge/platform-macOS%2012.0+-blue.svg)](https://developer.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## Overview

**SwiftCompress** is a lightweight, scriptable CLI tool that provides explicit file compression and decompression using Apple's highly-optimized Compression framework. Built with Clean Architecture principles, it offers a simple interface to four industry-standard compression algorithms.

### Key Features

- 🚀 **Four Compression Algorithms**: LZFSE, LZ4, ZLIB, LZMA
- 🎯 **Explicit Control**: User specifies algorithm and output path
- 📦 **Native Performance**: Leverages Apple's Compression framework
- 💻 **Scriptable**: Designed for CLI automation and scripting
- 🧪 **Well-Tested**: 85%+ code coverage with comprehensive test suite
- 🏗️ **Clean Architecture**: Maintainable, extensible, and testable design

## Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/swiftcompress.git
cd swiftcompress

# Build and install
swift build -c release
sudo cp .build/release/swiftcompress /usr/local/bin/
```

### Basic Usage

```bash
# Compress a file
swiftcompress c myfile.txt -m lzfse
# Output: myfile.txt.lzfse

# Decompress a file
swiftcompress x myfile.txt.lzfse -m lzfse
# Output: myfile.txt

# Specify output path
swiftcompress c myfile.txt -m lz4 -o compressed.lz4

# Force overwrite existing files
swiftcompress c myfile.txt -m zlib -f
```

## Supported Algorithms

| Algorithm | Compression Ratio | Speed | Best For |
|-----------|------------------|-------|----------|
| **LZFSE** | High | Fast | General purpose, Apple ecosystem |
| **LZ4** | Medium | Very Fast | Real-time compression, streaming |
| **ZLIB** | High | Medium | Cross-platform compatibility |
| **LZMA** | Very High | Slow | Maximum compression, archives |

## Commands

### Compress

```bash
swiftcompress c <input> -m <algorithm> [-o <output>] [-f]
```

**Options:**
- `-m <algorithm>`: Compression algorithm (required): `lzfse`, `lz4`, `zlib`, `lzma`
- `-o <output>`: Output file path (optional, defaults to `<input>.<algorithm>`)
- `-f`: Force overwrite if output file exists

### Decompress

```bash
swiftcompress x <input> -m <algorithm> [-o <output>] [-f]
```

**Options:**
- `-m <algorithm>`: Compression algorithm (required): `lzfse`, `lz4`, `zlib`, `lzma`
- `-o <output>`: Output file path (optional, defaults to input without extension)
- `-f`: Force overwrite if output file exists

## Examples

```bash
# Compress with different algorithms
swiftcompress c document.pdf -m lzfse
swiftcompress c video.mp4 -m lz4
swiftcompress c archive.tar -m lzma

# Decompress
swiftcompress x document.pdf.lzfse -m lzfse
swiftcompress x video.mp4.lz4 -m lz4

# Custom output paths
swiftcompress c large_dataset.csv -m zlib -o data.compressed
swiftcompress x data.compressed -m zlib -o recovered.csv

# Force overwrite
swiftcompress c important.txt -m lzfse -f

# Use in scripts
for file in *.txt; do
    swiftcompress c "$file" -m lzfse
done
```

## Requirements

- **macOS**: 12.0 or later
- **Xcode**: 14.0 or later (for building from source)
- **Swift**: 5.9 or later

## Development

### Getting Started

See [SETUP.md](SETUP.md) for detailed development environment setup instructions.

```bash
# Build
swift build

# Run
swift run swiftcompress

# Run tests
swift test

# Open in Xcode
xed .
```

### Architecture

SwiftCompress follows **Clean Architecture** with four distinct layers:

```
┌─────────────────────────────────────┐
│     CLI Interface Layer              │  ← ArgumentParser, CommandRouter
├─────────────────────────────────────┤
│     Application Layer                │  ← Commands, Workflows
├─────────────────────────────────────┤
│     Domain Layer                     │  ← Business Logic, Protocols
├─────────────────────────────────────┤
│     Infrastructure Layer             │  ← Compression Framework, File I/O
└─────────────────────────────────────┘
```

For comprehensive architectural documentation, see:
- [Architecture Overview](Documentation/ARCHITECTURE.md)
- [Component Specifications](Documentation/component_specifications.md)
- [Architecture Decision Records (ADRs)](Documentation/ADRs/)

### Project Structure

```
swiftcompress/
├── Sources/                  # Production code
│   ├── CLI/                 # Command-line interface
│   ├── Application/         # Application workflows
│   ├── Domain/              # Business logic
│   ├── Infrastructure/      # System integration
│   └── Shared/              # Common types
├── Tests/                   # Test code
│   ├── UnitTests/
│   ├── IntegrationTests/
│   ├── E2ETests/
│   └── TestHelpers/
├── Documentation/           # Architecture docs
└── Package.swift           # SPM configuration
```

## Documentation

### For Users
- [README.md](README.md) - This file
- [SETUP.md](SETUP.md) - Development environment setup

### For Developers
- [Architecture Overview](Documentation/ARCHITECTURE.md) - Complete architectural documentation
- [Component Specifications](Documentation/component_specifications.md) - Detailed component contracts
- [Module Structure](Documentation/module_structure.md) - File organization guide
- [Error Handling Strategy](Documentation/error_handling_strategy.md) - Error handling patterns
- [Testing Strategy](Documentation/testing_strategy.md) - Testing approach and requirements
- [Data Flow Diagrams](Documentation/data_flow_diagrams.md) - Visual flow representations

### Architecture Decision Records
- [ADR-001: Clean Architecture](Documentation/ADRs/ADR-001-clean-architecture.md)
- [ADR-002: Protocol Abstraction](Documentation/ADRs/ADR-002-protocol-abstraction.md)
- [ADR-003: Stream Processing](Documentation/ADRs/ADR-003-stream-processing.md)
- [ADR-004: Dependency Injection](Documentation/ADRs/ADR-004-dependency-injection.md)
- [ADR-005: Explicit Algorithm Selection](Documentation/ADRs/ADR-005-explicit-algorithm-selection.md)

## Roadmap

### ✅ Phase 0: Architecture (Complete)
- [x] Project specification and design
- [x] Comprehensive architectural documentation
- [x] Development environment setup

### ✅ Phase 1: MVP Implementation (Complete)
- [x] **Week 1**: Foundation layer (protocols, domain logic) ✅
- [x] **Week 2**: Infrastructure layer (file I/O, algorithms) ✅
- [x] **Week 3**: Application & CLI layers (commands, parsing) ✅
- [x] **Week 4**: Testing, polish, documentation ✅

**Status**: MVP Complete - All 279 tests passing, 95%+ coverage

**Metrics**:
- 31 source files (~2,956 lines)
- 13 test files (~5,918 lines)
- 279 tests (100% passing)
- All 4 layers fully implemented
- All 4 algorithms working (LZFSE, LZ4, ZLIB, LZMA)
- End-to-end CLI workflows verified

### 🔧 Phase 2: Usability Improvements (In Progress)
- [x] True streaming implementation ✅ **COMPLETE** (validated: 9.6 MB peak memory for 100 MB files)
- [x] Algorithm auto-detection from file extension ✅ **COMPLETE** (decompression)
- [x] Performance testing with large files ✅ **COMPLETE** (100 MB validated)
- [ ] Performance testing with files >1 GB
- [ ] Enhanced help system with examples
- [ ] Improved error messages
- [ ] CI/CD setup (GitHub Actions)
- [ ] Performance benchmarking and optimization

### 🚀 Phase 3: Advanced Features (Future)
- [ ] stdin/stdout streaming support
- [ ] Compression level flags (`--fast`, `--best`)
- [ ] Progress indicators for large files
- [ ] Batch operation support

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the architecture guidelines in [Documentation/](Documentation/)
4. Write tests for new functionality (85%+ coverage required)
5. Ensure all tests pass (`swift test`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Code Quality Standards

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Maintain 85%+ test coverage
- Document all public APIs
- Follow Clean Architecture principles
- All layers must have proper separation of concerns

## Testing

```bash
# Run all tests
swift test

# Run with coverage
swift test --enable-code-coverage

# Run specific test
swift test --filter CompressCommandTests
```

The project maintains **85%+ test coverage** across all layers with comprehensive unit, integration, and E2E tests.

## Performance

SwiftCompress is designed for efficiency with true streaming implementation:
- ✅ **Constant memory footprint**: ~9.6 MB peak for compression, ~8.4 MB for decompression
- ✅ **Fast processing**: 100 MB file compressed in 0.67s (LZFSE)
- ✅ **True streaming**: Processes files of any size with 64 KB buffers
- ✅ **Validated**: 100 MB files tested, ready for multi-GB files

**Validated Performance (100 MB test file, LZFSE):**
- Compression: 0.67s, 9.6 MB peak memory
- Decompression: 0.25s, 8.4 MB peak memory
- Data integrity: ✅ Verified via round-trip testing

## Error Handling

SwiftCompress provides clear, actionable error messages:

```bash
$ swiftcompress c nonexistent.txt -m lzfse
Error: File not found: nonexistent.txt
Please check the file path and try again.

$ swiftcompress c file.txt -m invalid
Error: Unsupported algorithm: invalid
Supported algorithms: lzfse, lz4, zlib, lzma
```

Exit codes:
- `0` - Success
- `1` - General error (MVP)
- Expanded error codes in Phase 2

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [Swift Argument Parser](https://github.com/apple/swift-argument-parser)
- Leverages Apple's [Compression Framework](https://developer.apple.com/documentation/compression)
- Architecture inspired by [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

## Contact

- **Issues**: [GitHub Issues](https://github.com/yourusername/swiftcompress/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/swiftcompress/discussions)

## Status

**Current Version**: 0.1.0 (MVP Complete)
**Status**: ✅ Fully functional CLI tool with all layers implemented
**Test Coverage**: 95%+ (279/279 tests passing)
**Last Updated**: October 2025

### MVP Achievements
- ✅ All 4 compression algorithms working (LZFSE, LZ4, ZLIB, LZMA)
- ✅ Complete CLI interface with ArgumentParser
- ✅ Full compress/decompress workflows
- ✅ Comprehensive error handling
- ✅ 95%+ test coverage across all layers
- ✅ Clean Architecture fully implemented
- ✅ Round-trip data integrity verified

---

**Ready to use?** Build with `swift build` and start compressing files!
