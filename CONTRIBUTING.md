# Contributing to SwiftCompress

Thank you for your interest in contributing to SwiftCompress! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Process](#development-process)
- [Architecture Guidelines](#architecture-guidelines)
- [Code Standards](#code-standards)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Commit Message Guidelines](#commit-message-guidelines)

## Code of Conduct

This project follows a standard code of conduct:
- Be respectful and inclusive
- Welcome constructive feedback
- Focus on what's best for the project and community
- Show empathy towards other contributors

## Getting Started

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/swiftcompress.git
cd swiftcompress
```

### 2. Set Up Development Environment

Follow the instructions in [SETUP.md](SETUP.md) to configure your development environment.

```bash
# Build the project
swift build

# Run tests
swift test

# Open in Xcode
xed .
```

### 3. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Test additions or modifications

## Development Process

### Before You Start

1. **Check Existing Issues**: Look for existing issues or discussions about your proposed change
2. **Create an Issue**: If none exists, create an issue describing your proposed change
3. **Get Feedback**: Wait for maintainer feedback before investing significant time
4. **Review Architecture**: Read the [Architecture Documentation](Documentation/ARCHITECTURE.md)

### Understanding the Architecture

SwiftCompress follows **Clean Architecture** with 4 layers:

```
┌─────────────────────────────────────┐
│     CLI Interface Layer              │  ← ArgumentParser, CommandRouter, OutputFormatter
├─────────────────────────────────────┤
│     Application Layer                │  ← Commands, CommandExecutor, ErrorHandler
├─────────────────────────────────────┤
│     Domain Layer                     │  ← CompressionEngine, AlgorithmRegistry, Protocols
├─────────────────────────────────────┤
│     Infrastructure Layer             │  ← FileSystemHandler, Algorithms, StreamProcessor
└─────────────────────────────────────┘
```

**Key Principles:**
- Dependencies point inward only
- Domain layer has no outward dependencies
- All cross-layer interactions use protocols
- Each layer has specific responsibilities

**Required Reading:**
- [ARCHITECTURE.md](Documentation/ARCHITECTURE.md) - Complete architectural overview
- [component_specifications.md](Documentation/component_specifications.md) - Component details
- [ADRs](Documentation/ADRs/) - Architecture Decision Records

## Architecture Guidelines

### Layer Responsibilities

#### CLI Interface Layer (`Sources/CLI/`)
- Parse command-line arguments
- Route commands to application layer
- Format output for terminal display
- Set exit codes

**Dependencies**: Application layer protocols only

#### Application Layer (`Sources/Application/`)
- Orchestrate workflows (compress/decompress)
- Coordinate domain services
- Handle application-level errors
- Translate errors for CLI layer

**Dependencies**: Domain layer protocols and models

#### Domain Layer (`Sources/Domain/`)
- Core business logic
- Algorithm registry and selection
- File path resolution
- Validation rules
- Protocol definitions

**Dependencies**: None (except Shared types)

#### Infrastructure Layer (`Sources/Infrastructure/`)
- Apple Compression Framework integration
- File system operations
- Stream processing implementation
- Concrete algorithm implementations

**Dependencies**: Domain protocols only

### Design Patterns

When contributing, follow these established patterns:

- **Command Pattern**: For compress/decompress operations
- **Strategy Pattern**: For algorithm implementations
- **Registry Pattern**: For algorithm management
- **Dependency Injection**: Constructor-based DI
- **Protocol-Oriented**: All cross-layer interactions use protocols

## Code Standards

### Swift Style Guide

Follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).

#### Key Conventions

**Naming:**
```swift
// Protocols
protocol CompressionAlgorithm { }

// Implementations
class LZFSEAlgorithm: CompressionAlgorithm { }

// Commands
class CompressCommand { }

// Errors
enum DomainError: Error { }

// Tests
class CompressCommandTests: XCTestCase { }

// Mocks
class MockFileHandler: FileHandlerProtocol { }
```

**File Organization:**
```swift
// 1. Imports
import Foundation
import Compression

// 2. Protocol definitions
protocol CompressionAlgorithm { ... }

// 3. Main type
final class LZFSEAlgorithm: CompressionAlgorithm {
    // MARK: - Properties
    // MARK: - Initialization
    // MARK: - Public Methods
    // MARK: - Private Methods
}

// 4. Extensions
extension LZFSEAlgorithm {
    // Protocol conformance or helpers
}

// 5. Supporting types
private struct CompressionContext { ... }
```

**Documentation:**
```swift
/// Compresses data using the LZFSE algorithm.
///
/// - Parameters:
///   - input: The data to compress
///   - level: Compression level (1-9)
/// - Returns: Compressed data
/// - Throws: `CompressionError` if compression fails
func compress(input: Data, level: Int) throws -> Data
```

### Code Quality Requirements

- **Line Length**: Maximum 120 characters
- **File Size**: Target 200-300 lines, maximum 500 lines
- **Function Complexity**: Keep functions focused and simple
- **Access Control**: Use appropriate access levels (public, internal, private)
- **SwiftLint**: Run SwiftLint before committing (if installed)

### Formatting

```bash
# Install SwiftLint (optional but recommended)
brew install swiftlint

# Run SwiftLint
swiftlint
```

**Editor Settings:**
- Tab Width: 4 spaces
- Indent Width: 4 spaces
- Use spaces (not tabs)

## Testing Requirements

### Coverage Requirements

- **Minimum Coverage**: 85% overall
- **Unit Tests**: All components must have unit tests
- **Integration Tests**: Multi-component interactions must be tested
- **E2E Tests**: Critical user workflows must have end-to-end tests

### Testing Structure

Tests mirror the source structure:

```
Tests/
├── UnitTests/
│   ├── CLI/
│   ├── Application/
│   ├── Domain/
│   └── Infrastructure/
├── IntegrationTests/
├── E2ETests/
└── TestHelpers/
    ├── Mocks/
    └── Fixtures/
```

### Writing Tests

**Unit Test Example:**
```swift
import XCTest
@testable import swiftcompress

final class CompressCommandTests: XCTestCase {
    var sut: CompressCommand!
    var mockEngine: MockCompressionEngine!
    var mockFileHandler: MockFileHandler!

    override func setUp() {
        super.setUp()
        mockEngine = MockCompressionEngine()
        mockFileHandler = MockFileHandler()
        sut = CompressCommand(
            inputPath: "/test.txt",
            algorithmName: "lzfse",
            compressionEngine: mockEngine,
            fileHandler: mockFileHandler
        )
    }

    override func tearDown() {
        sut = nil
        mockEngine = nil
        mockFileHandler = nil
        super.tearDown()
    }

    // MARK: - Happy Path Tests

    func testExecute_ValidInput_Success() throws {
        // Arrange
        mockFileHandler.fileExistsResult = true
        mockFileHandler.fileData = Data("test content".utf8)
        mockEngine.compressResult = Data("compressed".utf8)

        // Act
        let result = try sut.execute()

        // Assert
        XCTAssertEqual(result.status, .success)
        XCTAssertTrue(mockFileHandler.writeWasCalled)
    }

    // MARK: - Error Handling Tests

    func testExecute_FileNotFound_ThrowsError() {
        // Arrange
        mockFileHandler.fileExistsResult = false

        // Act & Assert
        XCTAssertThrowsError(try sut.execute()) { error in
            XCTAssertTrue(error is DomainError)
        }
    }
}
```

### Running Tests

```bash
# Run all tests
swift test

# Run specific test
swift test --filter CompressCommandTests

# Run with coverage
swift test --enable-code-coverage

# View coverage in Xcode
# Product → Test (Cmd+U)
# Then: Report Navigator → Coverage
```

## Pull Request Process

### Before Submitting

1. **Update from main:**
   ```bash
   git checkout main
   git pull upstream main
   git checkout your-feature-branch
   git rebase main
   ```

2. **Run tests:**
   ```bash
   swift test
   ```

3. **Check code quality:**
   ```bash
   swift build
   swiftlint  # If installed
   ```

4. **Update documentation:** If you changed public APIs or architecture

### Pull Request Checklist

- [ ] Code follows Swift API Design Guidelines
- [ ] All tests pass (`swift test`)
- [ ] New functionality has tests (85%+ coverage)
- [ ] Architecture guidelines followed
- [ ] Documentation updated (if needed)
- [ ] Commit messages follow conventions
- [ ] No merge conflicts with main
- [ ] Self-reviewed the changes
- [ ] Added/updated comments for complex logic

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality)
- [ ] Breaking change (fix or feature causing existing functionality to change)
- [ ] Documentation update

## Related Issue
Closes #(issue number)

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] E2E tests added/updated
- [ ] Manual testing performed

## Architecture Compliance
- [ ] Changes follow Clean Architecture principles
- [ ] Dependencies point inward only
- [ ] Proper layer separation maintained
- [ ] Protocols used for cross-layer communication

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] Tests pass locally
- [ ] No new warnings introduced
```

### Review Process

1. **Automated Checks**: CI will run tests and checks (when configured)
2. **Code Review**: Maintainers will review your code
3. **Feedback**: Address any feedback or requested changes
4. **Approval**: Once approved, maintainers will merge your PR

## Commit Message Guidelines

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```bash
feat(cli): add support for LZ4 algorithm

Implement LZ4 compression algorithm using Apple's Compression framework.
Includes unit tests and integration tests.

Closes #42
```

```bash
fix(domain): correct file path resolution for nested directories

FilePathResolver was not handling deeply nested directory structures.
Updated algorithm to properly traverse directory trees.

Fixes #78
```

```bash
docs(architecture): update component specifications

Added detailed documentation for StreamProcessor component.
Clarified protocol contracts and error handling.
```

## Areas for Contribution

### High Priority

- [ ] Core compression algorithm implementations
- [ ] Unit and integration tests
- [ ] Documentation improvements
- [ ] Bug fixes

### Medium Priority

- [ ] Performance optimizations
- [ ] Error message improvements
- [ ] CLI usability enhancements

### Future Enhancements

- [ ] Additional compression algorithms
- [ ] Configuration file support
- [ ] Progress indicators
- [ ] Batch operations

## Getting Help

### Questions?

- **Architecture**: Review [Documentation/ARCHITECTURE.md](Documentation/ARCHITECTURE.md)
- **Setup Issues**: See [SETUP.md](SETUP.md)
- **Component Details**: Check [component_specifications.md](Documentation/component_specifications.md)
- **Design Decisions**: Read [ADRs](Documentation/ADRs/)

### Discussions

- Open a [GitHub Discussion](https://github.com/yourusername/swiftcompress/discussions) for questions
- Create a [GitHub Issue](https://github.com/yourusername/swiftcompress/issues) for bugs

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to SwiftCompress!** 🎉

Your contributions help make this tool better for everyone.
