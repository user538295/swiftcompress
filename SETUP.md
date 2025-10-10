# SwiftCompress - Development Environment Setup

**Status**: ✅ Development Environment Ready
**Last Updated**: 2025-10-10

## Prerequisites

- **macOS**: 12.0 or later
- **Xcode**: 14.0 or later (installed via App Store)
- **Swift**: 5.9+ (included with Xcode)

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd swiftcompress
```

### 2. Build the Project

Using Swift Package Manager (recommended):

```bash
swift build
```

### 3. Run the Tool

```bash
swift run swiftcompress
```

Or run the built executable directly:

```bash
.build/debug/swiftcompress
```

### 4. Run Tests

```bash
swift test
```

## Project Structure

The project follows Clean Architecture with 4 layers:

```
swiftcompress/
├── Sources/                    # Production code
│   ├── CLI/                   # CLI Interface Layer
│   ├── Application/           # Application Layer
│   ├── Domain/                # Domain Layer (business logic)
│   ├── Infrastructure/        # Infrastructure Layer (system integration)
│   └── Shared/                # Shared types and utilities
│
├── Tests/                     # Test code
│   ├── UnitTests/            # Unit tests (mirrors Sources structure)
│   ├── IntegrationTests/     # Integration tests
│   ├── E2ETests/             # End-to-end tests
│   └── TestHelpers/          # Test utilities and mocks
│
├── Documentation/             # Architecture documentation
│   ├── ARCHITECTURE.md
│   ├── architecture_overview.md
│   ├── component_specifications.md
│   ├── module_structure.md
│   └── ADRs/                 # Architecture Decision Records
│
├── Package.swift             # Swift Package Manager manifest
└── README.md                 # Project overview (GitHub)
```

## Development Workflow

### Opening in Xcode

#### Option 1: Swift Package Manager (Recommended)

```bash
xed .
```

This opens the Swift Package in Xcode.

#### Option 2: Generate Xcode Project

```bash
swift package generate-xcodeproj
open swiftcompress.xcodeproj
```

### Building for Release

```bash
swift build -c release
```

The optimized executable will be at `.build/release/swiftcompress`.

### Installing Locally

```bash
swift build -c release
sudo cp .build/release/swiftcompress /usr/local/bin/
```

Now you can run `swiftcompress` from anywhere.

## Dependencies

The project uses **Swift Argument Parser** for CLI argument parsing:
- **Package**: swift-argument-parser
- **Version**: 1.3.0+
- **Source**: https://github.com/apple/swift-argument-parser

Dependencies are managed via Swift Package Manager and will be automatically resolved on first build.

## IDE Configuration

### Xcode Settings

Recommended Xcode settings for this project:

1. **Build Settings**:
   - Swift Language Version: Swift 5
   - Optimization Level (Debug): -Onone
   - Optimization Level (Release): -O

2. **Editor Settings**:
   - Tab Width: 4 spaces
   - Indent Width: 4 spaces
   - Use spaces (not tabs)

### Code Formatting

The project follows the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).

Consider installing SwiftLint for consistent code style:

```bash
brew install swiftlint
```

## Testing

### Run All Tests

```bash
swift test
```

### Run Tests with Coverage

```bash
swift test --enable-code-coverage
```

### Test in Xcode

1. Open the project in Xcode: `xed .`
2. Press `Cmd+U` to run all tests
3. View test coverage: Product → Show Build Folder in Finder → Coverage

### Coverage Target

The project aims for **85%+ code coverage** across all layers.

## Troubleshooting

### Build Fails with "Cannot find module"

**Solution**: Clean and rebuild
```bash
swift package clean
swift build
```

### Tests Don't Run in Xcode

**Solution**: Make sure you're using the Package workspace, not a generated project.

### Xcode Can't Resolve Dependencies

**Solution**: Reset package caches
```bash
rm -rf .build
swift package resolve
swift package update
```

### Permission Denied When Installing

**Solution**: Use sudo or change installation directory
```bash
sudo swift build -c release
sudo cp .build/release/swiftcompress /usr/local/bin/
```

Or install to a user directory:
```bash
mkdir -p ~/bin
cp .build/release/swiftcompress ~/bin/
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
```

## Development Status

### ✅ Phase 0: Architecture - COMPLETE
- [x] Project specification
- [x] Complete architectural documentation
- [x] Development environment setup

### ✅ Phase 1: MVP Implementation - COMPLETE

See [ARCHITECTURE.md](Documentation/ARCHITECTURE.md) for detailed implementation roadmap.

#### ✅ Week 1: Foundation Layer - COMPLETE
- [x] Protocol definitions
- [x] FilePathResolver
- [x] ValidationRules
- [x] AlgorithmRegistry
- [x] Error types
- [x] Unit tests (90%+ coverage)

#### ✅ Week 2: Infrastructure Layer - COMPLETE
- [x] FileSystemHandler
- [x] StreamProcessor
- [x] Algorithm implementations (LZFSE, LZ4, Zlib, LZMA)
- [x] Unit and integration tests

#### ✅ Week 3: Application & CLI Layers - COMPLETE
- [x] Commands (CompressCommand, DecompressCommand)
- [x] ArgumentParser integration
- [x] CommandRouter and OutputFormatter
- [x] Dependency wiring
- [x] Layer tests

#### ✅ Week 4: Testing & Polish - COMPLETE
- [x] E2E tests
- [x] Performance testing (100 MB files validated)
- [x] 95%+ test coverage (exceeded 85% target)
- [x] User documentation
- [x] True streaming implementation
- [x] Memory usage validation (9.6 MB peak)

**MVP Status**: ✅ FULLY COMPLETE
- All 279 tests passing (0 failures)
- 95%+ test coverage across all layers
- True streaming with constant memory footprint
- Large file support validated (100 MB files tested)

### 🔧 Phase 2: Improvements (In Progress)
- [x] True streaming implementation ✅ **COMPLETE**
- [x] Performance testing with 100 MB files ✅ **COMPLETE**
- [ ] Performance testing (files >1 GB)
- [ ] CI/CD setup (GitHub Actions)

## Next Steps

### For Users
1. **Build the tool**: `swift build -c release`
2. **Install locally**: `sudo cp .build/release/swiftcompress /usr/local/bin/`
3. **Start compressing**: `swiftcompress c myfile.txt -m lzfse`

### For Contributors
1. **Review Architecture**: Start with [ARCHITECTURE.md](Documentation/ARCHITECTURE.md)
2. **Study Components**: Read [component_specifications.md](Documentation/component_specifications.md)
3. **Pick a Phase 2 task**: See roadmap above
4. **Follow TDD approach**: Maintain 95%+ test coverage

## Useful Commands

```bash
# Build
swift build

# Build for release
swift build -c release

# Run
swift run swiftcompress

# Test
swift test

# Clean
swift package clean

# Update dependencies
swift package update

# Open in Xcode
xed .

# Check Swift version
swift --version

# Lint (if SwiftLint installed)
swiftlint
```

## Resources

### Official Documentation
- [Swift Package Manager](https://swift.org/package-manager/)
- [Xcode Documentation](https://developer.apple.com/xcode/)
- [Swift Argument Parser](https://github.com/apple/swift-argument-parser)

### Project Documentation
- [README.md](README.md) - Project overview and quick start
- [ARCHITECTURE.md](Documentation/ARCHITECTURE.md) - Complete architecture overview
- [Documentation/](Documentation/) - Detailed specifications

### Apple Frameworks Used
- [Compression Framework](https://developer.apple.com/documentation/compression)
- [Foundation Framework](https://developer.apple.com/documentation/foundation)
- [XCTest](https://developer.apple.com/documentation/xctest)

## Getting Help

### Build Issues
1. Check this SETUP.md file
2. Clean and rebuild: `swift package clean && swift build`
3. Update dependencies: `swift package update`

### Architecture Questions
1. Review [architecture_overview.md](Documentation/architecture_overview.md)
2. Check relevant [ADR](Documentation/ADRs/) files
3. Read [component_specifications.md](Documentation/component_specifications.md)

### Testing Issues
1. See [testing_strategy.md](Documentation/testing_strategy.md)
2. Review test examples in the documentation

---

**Environment Status**: ✅ Ready for Use and Contribution

The development environment is fully configured. The MVP is complete with all 279 tests passing. You can build and use the tool, or contribute to Phase 2 improvements.
