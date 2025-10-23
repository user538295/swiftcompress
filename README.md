# SwiftCompress

> A macOS command-line tool for file compression using Apple's native Compression framework

[![Platform](https://img.shields.io/badge/platform-macOS%2012.0+-blue.svg)](https://developer.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## Overview

**SwiftCompress** is a lightweight, scriptable CLI tool that provides explicit file compression and decompression using Apple's highly-optimized Compression framework. Built with Clean Architecture principles, it offers a simple interface to four industry-standard compression algorithms.
- Includes AI-generated code, carefully reviewed by a human.

### Key Features

- 🚀 **Four Compression Algorithms**: LZFSE, LZ4, ZLIB, LZMA
- 🎯 **Explicit Control**: User specifies algorithm and output path
- 📦 **Native Performance**: Leverages Apple's Compression framework
- 🔄 **Unix Pipeline Support**: Full stdin/stdout streaming for pipelines
- 💻 **Scriptable**: Designed for CLI automation and scripting
- 🧪 **Well-Tested**: 95%+ code coverage with comprehensive test suite
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
swiftcompress c <input> -m <algorithm> [-o <output>] [-f] [--progress]
```

**Options:**
- `-m <algorithm>`: Compression algorithm (required): `lzfse`, `lz4`, `zlib`, `lzma`
- `-o <output>`: Output file path (optional, defaults to `<input>.<algorithm>`)
- `-f`: Force overwrite if output file exists
- `--progress`: Show progress indicator during compression (opt-in)

### Decompress

```bash
swiftcompress x <input> [-m <algorithm>] [-o <output>] [-f] [--progress]
```

**Options:**
- `-m <algorithm>`: Compression algorithm (optional for file inputs, inferred from extension; required for stdin): `lzfse`, `lz4`, `zlib`, `lzma`
- `-o <output>`: Output file path (optional, defaults to input without extension)
- `-f`: Force overwrite if output file exists
- `--progress`: Show progress indicator during decompression (opt-in)

## Examples

### File-based Compression

```bash
# Compress with different algorithms
swiftcompress c document.pdf -m lzfse
swiftcompress c video.mp4 -m lz4
swiftcompress c archive.tar -m lzma

# Decompress (algorithm inferred from extension)
swiftcompress x document.pdf.lzfse
swiftcompress x video.mp4.lz4

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

### Unix Pipeline Support

SwiftCompress fully supports stdin/stdout streaming for seamless integration with Unix pipelines:

```bash
# Compress from stdin to stdout
cat largefile.txt | swiftcompress c -m lzfse > output.lzfse
echo "Hello World" | swiftcompress c -m lz4 > message.lz4

# Decompress from stdin to stdout
cat compressed.lzfse | swiftcompress x -m lzfse > output.txt
swiftcompress c input.txt -m zlib | swiftcompress x -m zlib > roundtrip.txt

# Chain with other tools
cat data.json | swiftcompress c -m lzfse | ssh user@remote "cat > data.json.lzfse"
curl https://example.com/data.txt | swiftcompress c -m lz4 > cached.lz4

# Mix stdin/stdout with file I/O
cat input.txt | swiftcompress c -m lzfse -o output.lzfse
swiftcompress x compressed.zlib -m zlib | less

# Process multiple files through pipeline
find . -name "*.log" | xargs cat | swiftcompress c -m lzma > all_logs.lzma

# Real-time log compression
tail -f app.log | swiftcompress c -m lz4 > app.log.lz4
```

**Pipeline Notes:**
- When reading from stdin, you must specify the algorithm with `-m`
- When writing to stdout, output is automatically piped
- File integrity is maintained in all pipeline scenarios
- Memory usage remains constant (~10 MB) regardless of data size

### Progress Indicators

SwiftCompress supports optional progress indicators for interactive use (requires `--progress` flag):

```bash
# Show progress during compression
swiftcompress c large-file.bin -m lzfse --progress
# Output to stderr: Compressing large-file.bin: [=====>     ] 45% 5.2 MB/s ETA 00:03

# Show progress during decompression
swiftcompress x compressed.lzfse -m lzfse --progress
# Output to stderr: Decompressing compressed.lzfse: [=========> ] 87% 12.1 MB/s ETA 00:01

# Progress works with file redirection (progress to stderr, data to file)
swiftcompress c data.txt -m lzfse --progress > output.lzfse
# Shows progress on terminal while data goes to file

# Progress in pipelines (visible on terminal, data flows through pipe)
swiftcompress c data.txt -m lzfse --progress | ssh remote "cat > file.lzfse"
```

**Progress Notes:**
- Progress is opt-in via `--progress` flag (quiet by default)
- Progress output goes to stderr (doesn't interfere with data on stdout)
- Shows percentage, speed, and ETA for files
- For stdin, shows speed and bytes processed (size unknown)
- Automatically disabled when output goes to stdout (to avoid corrupting piped data)

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
- [ADR-006: Compression Stream API](Documentation/ADRs/ADR-006-compression-stream-api.md)
- [ADR-007: stdin/stdout Streaming](Documentation/ADRs/ADR-007-stdin-stdout-streaming.md)
- [ADR-008: Compression Level Flags](Documentation/ADRs/ADR-008-compression-level-flags.md)
- [ADR-009: Progress Indicator Support](Documentation/ADRs/ADR-009-progress-indicator-support.md)

## Project Status & Roadmap

> **Current Status**: See [STATUS.md](STATUS.md) for complete project metrics and validation results.

### Recent Milestones

- ✅ **Phase 0**: Architecture & Design (Complete)
- ✅ **Phase 1**: MVP Implementation - All 4 layers, 4 algorithms (Complete)
- ✅ **Phase 2**: Usability Improvements - True streaming, help system, error messages (Complete)
- ✅ **Phase 3**: stdin/stdout Streaming - Full Unix pipeline support (Complete)
- ✅ **Phase 4**: Advanced Features - Compression levels ✅, Progress indicators ✅ (Complete)

**For detailed development roadmap, milestones, and task tracking, see [ROADMAP.md](ROADMAP.md)**

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

The project maintains **95%+ test coverage** across all layers with comprehensive unit, integration, and E2E tests. See [STATUS.md](STATUS.md) for current test metrics.

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
- `1` - General error

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

> **For complete status information, metrics, and validation results, see [STATUS.md](STATUS.md)**

**Quick Summary**: Production-ready v1.2.0 with all planned features complete (411/411 tests passing, 95%+ coverage).

---

**Ready to use?** Build with `swift build` and start compressing files!
