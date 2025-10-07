# SwiftCompress Testing Strategy

**Version**: 1.0
**Last Updated**: 2025-10-07

This document defines the comprehensive testing approach for SwiftCompress, including testing principles, test organization, testing patterns, coverage requirements, and quality gates.

---

## Table of Contents

1. [Testing Philosophy](#testing-philosophy)
2. [Testing Pyramid](#testing-pyramid)
3. [Unit Testing Strategy](#unit-testing-strategy)
4. [Integration Testing Strategy](#integration-testing-strategy)
5. [End-to-End Testing Strategy](#end-to-end-testing-strategy)
6. [Test Data Management](#test-data-management)
7. [Mocking and Stubbing](#mocking-and-stubbing)
8. [Performance Testing](#performance-testing)
9. [Coverage Requirements](#coverage-requirements)
10. [Continuous Integration](#continuous-integration)

---

## Testing Philosophy

### Core Testing Principles

1. **Test Behavior, Not Implementation**: Focus on what components do, not how they do it
2. **Fast Feedback**: Tests should run quickly to enable rapid development
3. **Isolation**: Each test should be independent and not rely on others
4. **Repeatability**: Tests should produce same results every time
5. **Clarity**: Test names and structure should clearly communicate intent
6. **Maintainability**: Tests should be as maintainable as production code

### Test-Driven Development (TDD) Approach

**Recommended Workflow**:

1. **Red**: Write a failing test that defines desired behavior
2. **Green**: Write minimal code to make the test pass
3. **Refactor**: Improve code while keeping tests green

**Benefits**:
- Forces clear interface design
- Ensures high test coverage
- Produces testable, modular code
- Documents expected behavior

**When to Use TDD**:
- New feature development
- Bug fixes (write test that reproduces bug first)
- Refactoring existing code

### Testing at Each Architectural Layer

```
┌─────────────────────────────────────────────────────┐
│            CLI Layer                                 │
│  Testing: E2E tests with process execution           │
│  Focus: User interaction, exit codes, output format  │
└───────────────┬─────────────────────────────────────┘
                │
┌───────────────▼─────────────────────────────────────┐
│         Application Layer                            │
│  Testing: Unit tests with mocked dependencies        │
│  Focus: Command orchestration, error handling        │
└───────────────┬─────────────────────────────────────┘
                │
┌───────────────▼─────────────────────────────────────┐
│          Domain Layer                                │
│  Testing: Pure unit tests (no mocks needed)          │
│  Focus: Business logic, algorithms, validation       │
└───────────────┬─────────────────────────────────────┘
                │
┌───────────────▼─────────────────────────────────────┐
│       Infrastructure Layer                           │
│  Testing: Integration tests with real systems        │
│  Focus: File I/O, compression framework integration  │
└─────────────────────────────────────────────────────┘
```

---

## Testing Pyramid

### Test Distribution

SwiftCompress follows the testing pyramid pattern:

```
                    /\
                   /  \
                  /    \
                 / E2E  \           10% - Full CLI integration
                /   10%  \          ~20 tests
               /──────────\
              /            \
             / Integration  \      30% - Component integration
            /      30%       \     ~60 tests
           /__________________\
          /                    \
         /     Unit Tests       \   60% - Individual components
        /        60%             \  ~120 tests
       /__________________________\

       Total: ~200 tests
```

### Test Type Characteristics

| Test Type | Count | Speed | Scope | Dependencies |
|-----------|-------|-------|-------|--------------|
| Unit | ~120 | < 0.1s each | Single component | Mocked |
| Integration | ~60 | < 1s each | Multiple components | Real (isolated) |
| E2E | ~20 | < 5s each | Full system | Real |

### Why This Distribution?

**60% Unit Tests**:
- Fast execution (entire suite < 10 seconds)
- Pinpoint failures to specific components
- Enable confident refactoring
- Test edge cases exhaustively

**30% Integration Tests**:
- Verify component interactions
- Test with real file system (temp directories)
- Validate compression algorithms work correctly
- Ensure error propagation across layers

**10% E2E Tests**:
- Validate user-facing functionality
- Test complete workflows
- Verify CLI interface works correctly
- Ensure scriptability requirements met

---

## Unit Testing Strategy

### Unit Test Characteristics

**Definition**: Test single component in isolation with all dependencies mocked

**Properties**:
- Fast (<0.1s per test)
- No external dependencies (file system, network, etc.)
- Deterministic (same input = same output)
- Isolated (test failures don't cascade)

### Unit Testing by Layer

#### CLI Layer Unit Tests

**Components to Test**:
- ArgumentParser
- CommandRouter
- OutputFormatter

**Test Focus**:
- Argument parsing correctness
- Command routing logic
- Output formatting

**Example Test**:

```swift
// ArgumentParserTests.swift
class ArgumentParserTests: XCTestCase {
    var parser: ArgumentParser!

    override func setUp() {
        super.setUp()
        parser = ArgumentParser()
    }

    // MARK: - Compress Command Tests

    func testParse_CompressCommand_WithAllArguments_Success() {
        // Arrange
        let args = ["swiftcompress", "c", "input.txt", "-m", "lzfse", "-o", "output.lzfse"]

        // Act
        let result = try? parser.parse(args)

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.commandType, .compress)
        XCTAssertEqual(result?.inputPath, "input.txt")
        XCTAssertEqual(result?.algorithmName, "lzfse")
        XCTAssertEqual(result?.outputPath, "output.lzfse")
        XCTAssertFalse(result?.forceOverwrite ?? true)
    }

    func testParse_CompressCommand_MissingAlgorithm_ThrowsError() {
        // Arrange
        let args = ["swiftcompress", "c", "input.txt"]

        // Act & Assert
        XCTAssertThrowsError(try parser.parse(args)) { error in
            XCTAssertTrue(error is CLIError)
            if case CLIError.missingRequiredArgument(let name) = error {
                XCTAssertEqual(name, "-m")
            }
        }
    }

    func testParse_InvalidCommand_ThrowsError() {
        // Arrange
        let args = ["swiftcompress", "invalid", "input.txt"]

        // Act & Assert
        XCTAssertThrowsError(try parser.parse(args)) { error in
            if case CLIError.invalidCommand(let provided, let expected) = error {
                XCTAssertEqual(provided, "invalid")
                XCTAssertTrue(expected.contains("c"))
                XCTAssertTrue(expected.contains("x"))
            }
        }
    }

    // MARK: - Flag Tests

    func testParse_ForceOverwriteFlag_SetsFlag() {
        // Arrange
        let args = ["swiftcompress", "c", "input.txt", "-m", "lzfse", "-f"]

        // Act
        let result = try? parser.parse(args)

        // Assert
        XCTAssertTrue(result?.forceOverwrite ?? false)
    }

    // MARK: - Help and Version Tests

    func testParse_HelpFlag_ReturnsNil() {
        // Arrange
        let args = ["swiftcompress", "--help"]

        // Act
        let result = try? parser.parse(args)

        // Assert
        XCTAssertNil(result)
    }
}
```

#### Application Layer Unit Tests

**Components to Test**:
- CompressCommand
- DecompressCommand
- CommandExecutor
- ErrorHandler

**Test Focus**:
- Command orchestration logic
- Error translation
- Workflow coordination

**Mocking Requirements**:
- Mock CompressionEngine
- Mock FilePathResolver
- Mock FileHandler

**Example Test**:

```swift
// CompressCommandTests.swift
class CompressCommandTests: XCTestCase {
    var command: CompressCommand!
    var mockEngine: MockCompressionEngine!
    var mockPathResolver: MockFilePathResolver!
    var mockFileHandler: MockFileHandler!

    override func setUp() {
        super.setUp()
        mockEngine = MockCompressionEngine()
        mockPathResolver = MockFilePathResolver()
        mockFileHandler = MockFileHandler()

        command = CompressCommand(
            inputPath: "/test/input.txt",
            algorithmName: "lzfse",
            outputPath: nil,
            forceOverwrite: false,
            compressionEngine: mockEngine,
            pathResolver: mockPathResolver,
            fileHandler: mockFileHandler
        )
    }

    // MARK: - Output Path Resolution Tests

    func testExecute_NoOutputPath_UsesDefaultPath() throws {
        // Arrange
        mockFileHandler.fileExistsResult = true
        mockFileHandler.isReadableResult = true
        mockPathResolver.resolveCompressOutputPathResult = "/test/input.txt.lzfse"

        // Act
        _ = try command.execute()

        // Assert
        XCTAssertTrue(mockPathResolver.resolveCompressOutputPathCalled)
        XCTAssertEqual(mockEngine.compressInputPath, "/test/input.txt")
        XCTAssertEqual(mockEngine.compressOutputPath, "/test/input.txt.lzfse")
    }

    func testExecute_WithOutputPath_UsesProvidedPath() throws {
        // Arrange
        command = CompressCommand(
            inputPath: "/test/input.txt",
            algorithmName: "lzfse",
            outputPath: "/custom/output.dat",
            forceOverwrite: false,
            compressionEngine: mockEngine,
            pathResolver: mockPathResolver,
            fileHandler: mockFileHandler
        )
        mockFileHandler.fileExistsResult = true
        mockFileHandler.isReadableResult = true

        // Act
        _ = try command.execute()

        // Assert
        XCTAssertEqual(mockEngine.compressOutputPath, "/custom/output.dat")
    }

    // MARK: - Validation Tests

    func testExecute_InputFileNotFound_ThrowsError() {
        // Arrange
        mockFileHandler.fileExistsResult = false

        // Act & Assert
        XCTAssertThrowsError(try command.execute()) { error in
            XCTAssertTrue(error is InfrastructureError)
        }
    }

    func testExecute_OutputExistsWithoutForce_ThrowsError() {
        // Arrange
        mockFileHandler.fileExistsResult = true
        mockFileHandler.isReadableResult = true
        mockPathResolver.resolveCompressOutputPathResult = "/test/output.lzfse"

        // Mock output file already exists
        mockFileHandler.fileExistsResults = [
            "/test/input.txt": true,        // Input exists
            "/test/output.lzfse": true      // Output exists
        ]

        // Act & Assert
        XCTAssertThrowsError(try command.execute()) { error in
            if case DomainError.outputFileExists(let path) = error {
                XCTAssertEqual(path, "/test/output.lzfse")
            }
        }
    }

    func testExecute_OutputExistsWithForce_Succeeds() throws {
        // Arrange
        command = CompressCommand(
            inputPath: "/test/input.txt",
            algorithmName: "lzfse",
            outputPath: nil,
            forceOverwrite: true,  // Force flag set
            compressionEngine: mockEngine,
            pathResolver: mockPathResolver,
            fileHandler: mockFileHandler
        )
        mockFileHandler.fileExistsResult = true
        mockFileHandler.isReadableResult = true
        mockPathResolver.resolveCompressOutputPathResult = "/test/output.lzfse"

        // Act
        let result = try command.execute()

        // Assert
        XCTAssertEqual(result, .success(message: nil))
    }

    // MARK: - Compression Execution Tests

    func testExecute_Success_CallsCompressionEngine() throws {
        // Arrange
        mockFileHandler.fileExistsResult = true
        mockFileHandler.isReadableResult = true
        mockPathResolver.resolveCompressOutputPathResult = "/test/output.lzfse"

        // Act
        _ = try command.execute()

        // Assert
        XCTAssertTrue(mockEngine.compressCalled)
        XCTAssertEqual(mockEngine.compressInputPath, "/test/input.txt")
        XCTAssertEqual(mockEngine.compressAlgorithm, "lzfse")
    }

    func testExecute_CompressionFails_PropagatesError() {
        // Arrange
        mockFileHandler.fileExistsResult = true
        mockFileHandler.isReadableResult = true
        mockPathResolver.resolveCompressOutputPathResult = "/test/output.lzfse"
        mockEngine.compressError = InfrastructureError.compressionFailed(
            algorithm: "lzfse",
            reason: "Test failure"
        )

        // Act & Assert
        XCTAssertThrowsError(try command.execute()) { error in
            XCTAssertTrue(error is InfrastructureError)
        }
    }
}
```

#### Domain Layer Unit Tests

**Components to Test**:
- CompressionEngine
- AlgorithmRegistry
- FilePathResolver
- ValidationRules

**Test Focus**:
- Business logic correctness
- Validation rules
- Algorithm selection

**Mocking Requirements**:
- Mock CompressionAlgorithm implementations
- Mock StreamProcessor

**Example Test**:

```swift
// FilePathResolverTests.swift
class FilePathResolverTests: XCTestCase {
    var resolver: FilePathResolver!

    override func setUp() {
        super.setUp()
        resolver = FilePathResolver()
    }

    // MARK: - Compress Output Path Tests

    func testResolveCompressOutputPath_NoOutputPath_AppendsAlgorithmExtension() {
        // Act
        let result = resolver.resolveCompressOutputPath(
            inputPath: "/path/to/file.txt",
            algorithmName: "lzfse",
            outputPath: nil
        )

        // Assert
        XCTAssertEqual(result, "/path/to/file.txt.lzfse")
    }

    func testResolveCompressOutputPath_WithOutputPath_ReturnsProvidedPath() {
        // Act
        let result = resolver.resolveCompressOutputPath(
            inputPath: "/path/to/file.txt",
            algorithmName: "lzfse",
            outputPath: "/custom/output.dat"
        )

        // Assert
        XCTAssertEqual(result, "/custom/output.dat")
    }

    func testResolveCompressOutputPath_FileWithoutExtension_AppendsAlgorithm() {
        // Act
        let result = resolver.resolveCompressOutputPath(
            inputPath: "/path/to/myfile",
            algorithmName: "lz4",
            outputPath: nil
        )

        // Assert
        XCTAssertEqual(result, "/path/to/myfile.lz4")
    }

    // MARK: - Decompress Output Path Tests

    func testResolveDecompressOutputPath_NoOutputPath_StripsExtension() {
        // Arrange
        let fileExists: (String) -> Bool = { _ in false }

        // Act
        let result = resolver.resolveDecompressOutputPath(
            inputPath: "/path/to/file.txt.lzfse",
            algorithmName: "lzfse",
            outputPath: nil,
            fileExists: fileExists
        )

        // Assert
        XCTAssertEqual(result, "/path/to/file.txt")
    }

    func testResolveDecompressOutputPath_OutputExists_AppendsOutSuffix() {
        // Arrange
        let fileExists: (String) -> Bool = { path in
            path == "/path/to/file.txt"
        }

        // Act
        let result = resolver.resolveDecompressOutputPath(
            inputPath: "/path/to/file.txt.lzfse",
            algorithmName: "lzfse",
            outputPath: nil,
            fileExists: fileExists
        )

        // Assert
        XCTAssertEqual(result, "/path/to/file.txt.out")
    }

    // MARK: - Algorithm Inference Tests (Phase 2)

    func testInferAlgorithm_LZFSEExtension_ReturnsLZFSE() {
        // Act
        let result = resolver.inferAlgorithm(from: "/path/to/file.txt.lzfse")

        // Assert
        XCTAssertEqual(result, "lzfse")
    }

    func testInferAlgorithm_LZ4Extension_ReturnsLZ4() {
        // Act
        let result = resolver.inferAlgorithm(from: "/path/to/file.dat.lz4")

        // Assert
        XCTAssertEqual(result, "lz4")
    }

    func testInferAlgorithm_UnknownExtension_ReturnsNil() {
        // Act
        let result = resolver.inferAlgorithm(from: "/path/to/file.txt")

        // Assert
        XCTAssertNil(result)
    }

    func testInferAlgorithm_NoExtension_ReturnsNil() {
        // Act
        let result = resolver.inferAlgorithm(from: "/path/to/myfile")

        // Assert
        XCTAssertNil(result)
    }

    // MARK: - Edge Cases

    func testResolveCompressOutputPath_PathWithMultipleDots_HandlesCorrectly() {
        // Act
        let result = resolver.resolveCompressOutputPath(
            inputPath: "/path/to/file.tar.gz",
            algorithmName: "lzfse",
            outputPath: nil
        )

        // Assert
        XCTAssertEqual(result, "/path/to/file.tar.gz.lzfse")
    }

    func testResolveDecompressOutputPath_HiddenFile_HandlesCorrectly() {
        // Arrange
        let fileExists: (String) -> Bool = { _ in false }

        // Act
        let result = resolver.resolveDecompressOutputPath(
            inputPath: "/path/to/.hidden.lz4",
            algorithmName: "lz4",
            outputPath: nil,
            fileExists: fileExists
        )

        // Assert
        XCTAssertEqual(result, "/path/to/.hidden")
    }
}
```

#### Infrastructure Layer Unit Tests

**Components to Test**:
- Algorithm implementations (with mocked framework)
- FileSystemHandler (with mocked FileManager)
- StreamProcessor (with mocked streams)

**Test Focus**:
- Correct framework API usage
- Error translation
- Stream processing logic

**Example Test**:

```swift
// LZFSEAlgorithmTests.swift
class LZFSEAlgorithmTests: XCTestCase {
    var algorithm: LZFSEAlgorithm!

    override func setUp() {
        super.setUp()
        algorithm = LZFSEAlgorithm()
    }

    // MARK: - Properties Tests

    func testName_ReturnsCorrectName() {
        // Assert
        XCTAssertEqual(algorithm.name, "lzfse")
    }

    // MARK: - Compression Tests

    func testCompress_ValidData_ReturnsCompressedData() throws {
        // Arrange
        let inputData = "Hello, World! This is test data for compression.".data(using: .utf8)!

        // Act
        let compressed = try algorithm.compress(input: inputData)

        // Assert
        XCTAssertNotNil(compressed)
        XCTAssertGreaterThan(compressed.count, 0)
        XCTAssertNotEqual(compressed, inputData)
    }

    func testCompress_EmptyData_ReturnsEmptyData() throws {
        // Arrange
        let inputData = Data()

        // Act
        let compressed = try algorithm.compress(input: inputData)

        // Assert
        XCTAssertEqual(compressed.count, 0)
    }

    // MARK: - Decompression Tests

    func testDecompress_ValidCompressedData_ReturnsOriginalData() throws {
        // Arrange
        let original = "Test data for round-trip compression.".data(using: .utf8)!
        let compressed = try algorithm.compress(input: original)

        // Act
        let decompressed = try algorithm.decompress(input: compressed)

        // Assert
        XCTAssertEqual(decompressed, original)
    }

    func testDecompress_CorruptedData_ThrowsError() {
        // Arrange
        let corruptedData = Data([0xFF, 0xAA, 0xBB, 0xCC, 0xDD])

        // Act & Assert
        XCTAssertThrowsError(try algorithm.decompress(input: corruptedData)) { error in
            XCTAssertTrue(error is InfrastructureError)
        }
    }

    // MARK: - Round-trip Tests

    func testRoundTrip_LargeData_PreservesData() throws {
        // Arrange
        let largeData = Data(repeating: 0x42, count: 100_000)

        // Act
        let compressed = try algorithm.compress(input: largeData)
        let decompressed = try algorithm.decompress(input: compressed)

        // Assert
        XCTAssertEqual(decompressed, largeData)
        XCTAssertLessThan(compressed.count, largeData.count)  // Should be compressed
    }

    func testRoundTrip_BinaryData_PreservesData() throws {
        // Arrange
        var binaryData = Data()
        for i in 0..<1000 {
            binaryData.append(UInt8(i % 256))
        }

        // Act
        let compressed = try algorithm.compress(input: binaryData)
        let decompressed = try algorithm.decompress(input: binaryData)

        // Assert
        XCTAssertEqual(decompressed, binaryData)
    }
}
```

### Unit Test Organization

**Test File Structure**:

```swift
import XCTest
@testable import swiftcompress

final class ComponentNameTests: XCTestCase {
    // MARK: - Properties
    var systemUnderTest: ComponentType!
    var mockDependency1: MockType1!
    var mockDependency2: MockType2!

    // MARK: - Setup and Teardown
    override func setUp() {
        super.setUp()
        // Initialize mocks and SUT
    }

    override func tearDown() {
        // Cleanup
        super.tearDown()
    }

    // MARK: - Feature 1 Tests
    func testFeature1_Scenario1_ExpectedBehavior() {
        // Arrange
        // Act
        // Assert
    }

    // MARK: - Feature 2 Tests
    // ...

    // MARK: - Error Handling Tests
    // ...

    // MARK: - Edge Case Tests
    // ...
}
```

### Unit Test Naming Convention

**Pattern**: `test<MethodName>_<Scenario>_<ExpectedBehavior>`

**Examples**:
- `testCompress_ValidInput_ReturnsCompressedData`
- `testExecute_FileNotFound_ThrowsError`
- `testParse_MissingRequiredArg_ThrowsError`
- `testResolve_OutputExists_AppendsOutSuffix`

---

## Integration Testing Strategy

### Integration Test Characteristics

**Definition**: Test multiple components working together with real implementations

**Properties**:
- Medium speed (< 1s per test)
- Use real infrastructure (file system, compression framework)
- Use isolated environments (temp directories)
- Clean up after each test

### Integration Test Scenarios

#### File System Integration Tests

**Test Focus**: Verify file operations work correctly

```swift
// FileOperationsIntegrationTests.swift
class FileOperationsIntegrationTests: XCTestCase {
    var tempDirectory: URL!
    var fileHandler: FileSystemHandler!

    override func setUp() {
        super.setUp()
        // Create temp directory for each test
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        fileHandler = FileSystemHandler()
    }

    override func tearDown() {
        // Clean up temp directory
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func testFileOperations_CreateReadDelete_Success() throws {
        // Arrange
        let testFile = tempDirectory.appendingPathComponent("test.txt")
        let testData = "Test data".data(using: .utf8)!

        // Act: Write
        let outputStream = try fileHandler.outputStream(at: testFile.path)
        outputStream.open()
        testData.withUnsafeBytes { buffer in
            outputStream.write(buffer.bindMemory(to: UInt8.self).baseAddress!, maxLength: testData.count)
        }
        outputStream.close()

        // Assert: File exists
        XCTAssertTrue(fileHandler.fileExists(at: testFile.path))

        // Act: Read
        let inputStream = try fileHandler.inputStream(at: testFile.path)
        inputStream.open()
        var readData = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
        defer { buffer.deallocate() }
        while inputStream.hasBytesAvailable {
            let bytesRead = inputStream.read(buffer, maxLength: 1024)
            if bytesRead > 0 {
                readData.append(buffer, count: bytesRead)
            }
        }
        inputStream.close()

        // Assert: Data matches
        XCTAssertEqual(readData, testData)

        // Act: Delete
        try fileHandler.deleteFile(at: testFile.path)

        // Assert: File gone
        XCTAssertFalse(fileHandler.fileExists(at: testFile.path))
    }
}
```

#### Compression Integration Tests

**Test Focus**: Verify compression algorithms work with real data

```swift
// CompressionIntegrationTests.swift
class CompressionIntegrationTests: XCTestCase {
    var tempDirectory: URL!
    var compressionEngine: CompressionEngine!
    var fileHandler: FileSystemHandler!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        // Setup real components
        let registry = AlgorithmRegistry()
        registry.register(LZFSEAlgorithm())
        registry.register(LZ4Algorithm())
        registry.register(ZlibAlgorithm())
        registry.register(LZMAAlgorithm())

        fileHandler = FileSystemHandler()
        let streamProcessor = StreamProcessor()
        compressionEngine = CompressionEngine(
            algorithmRegistry: registry,
            streamProcessor: streamProcessor
        )
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func testCompression_LZFSEAlgorithm_Success() throws {
        // Arrange: Create test file
        let inputFile = tempDirectory.appendingPathComponent("input.txt")
        let outputFile = tempDirectory.appendingPathComponent("output.lzfse")
        let testData = String(repeating: "Test data ", count: 1000).data(using: .utf8)!
        try testData.write(to: inputFile)

        // Act: Compress
        try compressionEngine.compress(
            inputPath: inputFile.path,
            outputPath: outputFile.path,
            algorithmName: "lzfse"
        )

        // Assert
        XCTAssertTrue(fileHandler.fileExists(at: outputFile.path))
        let compressedSize = try fileHandler.fileSize(at: outputFile.path)
        XCTAssertGreaterThan(compressedSize, 0)
        XCTAssertLessThan(compressedSize, testData.count)  // Should be smaller
    }

    func testRoundTrip_AllAlgorithms_PreservesData() throws {
        let algorithms = ["lzfse", "lz4", "zlib", "lzma"]
        let testData = "The quick brown fox jumps over the lazy dog. ".data(using: .utf8)!

        for algorithm in algorithms {
            // Arrange
            let inputFile = tempDirectory.appendingPathComponent("input_\(algorithm).txt")
            let compressedFile = tempDirectory.appendingPathComponent("compressed_\(algorithm)")
            let decompressedFile = tempDirectory.appendingPathComponent("output_\(algorithm).txt")
            try testData.write(to: inputFile)

            // Act: Compress
            try compressionEngine.compress(
                inputPath: inputFile.path,
                outputPath: compressedFile.path,
                algorithmName: algorithm
            )

            // Act: Decompress
            try compressionEngine.decompress(
                inputPath: compressedFile.path,
                outputPath: decompressedFile.path,
                algorithmName: algorithm
            )

            // Assert
            let decompressedData = try Data(contentsOf: decompressedFile)
            XCTAssertEqual(decompressedData, testData, "Round-trip failed for \(algorithm)")
        }
    }

    func testCompression_LargeFile_Success() throws {
        // Arrange: Create 10 MB test file
        let inputFile = tempDirectory.appendingPathComponent("large.bin")
        let outputFile = tempDirectory.appendingPathComponent("large.lzfse")
        let largeData = Data(repeating: 0x42, count: 10 * 1024 * 1024)
        try largeData.write(to: inputFile)

        // Act
        try compressionEngine.compress(
            inputPath: inputFile.path,
            outputPath: outputFile.path,
            algorithmName: "lzfse"
        )

        // Assert
        XCTAssertTrue(fileHandler.fileExists(at: outputFile.path))
        let compressedSize = try fileHandler.fileSize(at: outputFile.path)
        XCTAssertLessThan(compressedSize, largeData.count)
    }
}
```

---

## End-to-End Testing Strategy

### E2E Test Characteristics

**Definition**: Test complete user workflows by executing the CLI binary

**Properties**:
- Slowest tests (< 5s per test)
- Execute actual binary
- Capture stdout/stderr
- Verify exit codes
- Use real file system

### E2E Test Implementation

```swift
// CLIExecutionTests.swift
class CLIExecutionTests: XCTestCase {
    var tempDirectory: URL!
    var binaryPath: String!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        // Find built binary (adjust path as needed)
        binaryPath = "<path-to-built-binary>/swiftcompress"
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func testCLI_CompressFile_Success() throws {
        // Arrange: Create test file
        let inputFile = tempDirectory.appendingPathComponent("test.txt")
        let testData = "Test data for CLI".data(using: .utf8)!
        try testData.write(to: inputFile)

        // Act: Execute CLI
        let result = executeCLI(arguments: [
            "c",
            inputFile.path,
            "-m", "lzfse"
        ])

        // Assert
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.stdout.isEmpty)  // Quiet mode
        XCTAssertTrue(result.stderr.isEmpty)

        // Verify output file created
        let outputFile = tempDirectory.appendingPathComponent("test.txt.lzfse")
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile.path))
    }

    func testCLI_DecompressFile_Success() throws {
        // Arrange: Compress file first
        let inputFile = tempDirectory.appendingPathComponent("test.txt")
        let testData = "Test data".data(using: .utf8)!
        try testData.write(to: inputFile)

        _ = executeCLI(arguments: ["c", inputFile.path, "-m", "lzfse"])

        // Act: Decompress
        let compressedFile = tempDirectory.appendingPathComponent("test.txt.lzfse")
        let outputFile = tempDirectory.appendingPathComponent("test.txt.out")

        let result = executeCLI(arguments: [
            "x",
            compressedFile.path,
            "-m", "lzfse",
            "-o", outputFile.path
        ])

        // Assert
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile.path))

        let decompressedData = try Data(contentsOf: outputFile)
        XCTAssertEqual(decompressedData, testData)
    }

    func testCLI_FileNotFound_ReturnsError() {
        // Act
        let result = executeCLI(arguments: [
            "c",
            "/nonexistent/file.txt",
            "-m", "lzfse"
        ])

        // Assert
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.stderr.contains("Error: File not found"))
    }

    func testCLI_InvalidAlgorithm_ReturnsError() throws {
        // Arrange
        let inputFile = tempDirectory.appendingPathComponent("test.txt")
        try "data".data(using: .utf8)!.write(to: inputFile)

        // Act
        let result = executeCLI(arguments: [
            "c",
            inputFile.path,
            "-m", "invalid"
        ])

        // Assert
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.stderr.contains("Unknown algorithm"))
    }

    func testCLI_OutputExists_WithoutForce_ReturnsError() throws {
        // Arrange: Create both input and output files
        let inputFile = tempDirectory.appendingPathComponent("test.txt")
        let outputFile = tempDirectory.appendingPathComponent("test.txt.lzfse")
        try "data".data(using: .utf8)!.write(to: inputFile)
        try "existing".data(using: .utf8)!.write(to: outputFile)

        // Act
        let result = executeCLI(arguments: [
            "c",
            inputFile.path,
            "-m", "lzfse"
        ])

        // Assert
        XCTAssertEqual(result.exitCode, 1)
        XCTAssertTrue(result.stderr.contains("already exists"))
        XCTAssertTrue(result.stderr.contains("-f"))
    }

    func testCLI_OutputExists_WithForce_Succeeds() throws {
        // Arrange
        let inputFile = tempDirectory.appendingPathComponent("test.txt")
        let outputFile = tempDirectory.appendingPathComponent("test.txt.lzfse")
        try "new data".data(using: .utf8)!.write(to: inputFile)
        try "old data".data(using: .utf8)!.write(to: outputFile)

        // Act
        let result = executeCLI(arguments: [
            "c",
            inputFile.path,
            "-m", "lzfse",
            "-f"
        ])

        // Assert
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputFile.path))
    }

    func testCLI_Help_PrintsUsage() {
        // Act
        let result = executeCLI(arguments: ["--help"])

        // Assert
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertTrue(result.stdout.contains("usage") || result.stdout.contains("Usage"))
        XCTAssertTrue(result.stdout.contains("swiftcompress"))
    }

    // MARK: - Helper Methods

    struct CLIResult {
        let exitCode: Int32
        let stdout: String
        let stderr: String
    }

    func executeCLI(arguments: [String]) -> CLIResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try! process.run()
        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        return CLIResult(
            exitCode: process.terminationStatus,
            stdout: String(data: stdoutData, encoding: .utf8) ?? "",
            stderr: String(data: stderrData, encoding: .utf8) ?? ""
        )
    }
}
```

---

## Test Data Management

### Test File Fixtures

**Location**: `Tests/TestHelpers/Fixtures/TestFiles/`

**Fixture Types**:
- **small.txt**: ~1 KB text file
- **medium.bin**: ~100 KB binary file
- **large.dat**: ~10 MB data file
- **corrupted.lzfse**: Intentionally corrupted compressed file
- **already-compressed.gz**: File already compressed (low compressibility)

### Generating Test Data

```swift
// TestUtilities.swift
class TestDataGenerator {
    static func generateTextFile(size: Int) -> Data {
        let text = "Lorem ipsum dolor sit amet. "
        var data = Data()
        while data.count < size {
            data.append(text.data(using: .utf8)!)
        }
        return data.prefix(size)
    }

    static func generateBinaryFile(size: Int) -> Data {
        var data = Data(count: size)
        data.withUnsafeMutableBytes { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            arc4random_buf(baseAddress, size)
        }
        return data
    }

    static func generateRepetitiveData(size: Int) -> Data {
        // Highly compressible data
        return Data(repeating: 0x42, count: size)
    }
}
```

### Test File Cleanup

Ensure all tests clean up temporary files:

```swift
override func tearDown() {
    // Clean up temp directory
    if let tempDir = tempDirectory {
        try? FileManager.default.removeItem(at: tempDir)
    }
    super.tearDown()
}
```

---

## Mocking and Stubbing

### Mock Implementation Guidelines

**Mock Naming**: `Mock<ProtocolName>`

**Mock Pattern**:

```swift
// MockFileHandler.swift
class MockFileHandler: FileHandlerProtocol {
    // Call tracking
    var fileExistsCalled = false
    var fileExistsCalledWithPath: String?

    // Configured responses
    var fileExistsResult = false
    var fileExistsResults: [String: Bool] = [:]

    // Method implementations
    func fileExists(at path: String) -> Bool {
        fileExistsCalled = true
        fileExistsCalledWithPath = path

        // Check for path-specific result
        if let result = fileExistsResults[path] {
            return result
        }

        return fileExistsResult
    }

    // ... other protocol methods
}
```

### Required Mocks

1. **MockFileHandler**: Mock file system operations
2. **MockCompressionAlgorithm**: Mock compression operations
3. **MockStreamProcessor**: Mock stream processing
4. **MockAlgorithmRegistry**: Mock algorithm lookup
5. **MockCompressionEngine**: Mock engine orchestration

---

## Performance Testing

### Performance Test Guidelines

**Test Scenarios**:
- Compress 1 MB file (< 1s)
- Compress 10 MB file (< 5s)
- Compress 100 MB file (< 30s)
- Decompress speeds match or exceed compression

**Performance Test Example**:

```swift
func testPerformance_CompressLargeFile() {
    let testData = Data(repeating: 0x42, count: 10 * 1024 * 1024)
    let inputFile = tempDirectory.appendingPathComponent("large.bin")
    try! testData.write(to: inputFile)

    measure {
        let outputFile = tempDirectory.appendingPathComponent("large_\(UUID()).lzfse")
        try! compressionEngine.compress(
            inputPath: inputFile.path,
            outputPath: outputFile.path,
            algorithmName: "lzfse"
        )
    }
}
```

---

## Coverage Requirements

### Minimum Coverage Targets

| Layer | Unit Test Coverage | Integration Test Coverage | Total Coverage |
|-------|-------------------|---------------------------|----------------|
| CLI | 80% | N/A (E2E tests) | 80% |
| Application | 85% | 60% | 90% |
| Domain | 90% | 70% | 95% |
| Infrastructure | 70% | 80% | 85% |
| **Overall** | **80%** | **70%** | **85%+** |

### Coverage Exclusions

**Acceptable to Skip**:
- Generated code
- main.swift (tested via E2E)
- Debug-only code
- Boilerplate getters/setters

---

## Continuous Integration

### CI Pipeline

```yaml
# .github/workflows/test.yml (example)
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Unit Tests
        run: swift test --filter UnitTests
      - name: Run Integration Tests
        run: swift test --filter IntegrationTests
      - name: Run E2E Tests
        run: swift test --filter E2ETests
      - name: Generate Coverage
        run: swift test --enable-code-coverage
```

### Test Execution Order

1. **Unit Tests** (fastest feedback)
2. **Integration Tests** (medium feedback)
3. **E2E Tests** (slowest, but critical)

---

## Testing Checklist

Before considering a feature complete:

- [ ] All components have unit tests
- [ ] All error scenarios have tests
- [ ] Integration tests cover component interactions
- [ ] E2E tests cover user workflows
- [ ] Code coverage meets targets (85%+)
- [ ] All tests pass consistently
- [ ] Performance tests meet targets
- [ ] Test data properly cleaned up
- [ ] Mocks implement all protocol methods

---

This comprehensive testing strategy ensures SwiftCompress is reliable, maintainable, and meets quality standards through rigorous testing at all architectural layers.
