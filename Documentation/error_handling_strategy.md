# SwiftCompress Error Handling Strategy

**Version**: 1.0
**Last Updated**: 2025-10-07

This document defines the comprehensive error handling approach for SwiftCompress, including error type definitions, propagation patterns, translation strategies, and user-facing error messaging.

---

## Table of Contents

1. [Error Handling Philosophy](#error-handling-philosophy)
2. [Error Type Hierarchy](#error-type-hierarchy)
3. [Layer-Specific Error Handling](#layer-specific-error-handling)
4. [Error Translation Strategy](#error-translation-strategy)
5. [User-Facing Error Messages](#user-facing-error-messages)
6. [Exit Code Strategy](#exit-code-strategy)
7. [Error Context and Debugging](#error-context-and-debugging)
8. [Error Handling Patterns](#error-handling-patterns)
9. [Testing Error Scenarios](#testing-error-scenarios)

---

## Error Handling Philosophy

### Core Principles

1. **Fail Fast**: Detect and report errors as early as possible
2. **Be Specific**: Provide clear, actionable error information
3. **Hide Implementation**: Don't expose internal details to users
4. **Type Safety**: Use Swift's typed error system
5. **Graceful Degradation**: Clean up resources on failure
6. **User-Centric**: Error messages guide users to solutions

### Swift Error Handling Approach

SwiftCompress uses Swift's native error handling mechanism:
- **Protocols**: Define error types with Swift's `Error` protocol
- **Throws**: Use `throws` to propagate errors up the call stack
- **Do-Catch**: Handle errors at appropriate layer boundaries
- **Result Types**: Consider for asynchronous operations (future)

### Error Ownership by Layer

```
┌─────────────────────────────────────────────────────┐
│            CLI Layer (main.swift)                    │
│  Responsibility: Exit codes, stderr output           │
└─────────────┬───────────────────────────────────────┘
              │ Receives: UserFacingError
              │
┌─────────────▼───────────────────────────────────────┐
│         Application Layer (ErrorHandler)             │
│  Responsibility: Error translation to user messages  │
└─────────────┬───────────────────────────────────────┘
              │ Receives: Domain/Infrastructure Errors
              │ Produces: UserFacingError
              │
┌─────────────▼───────────────────────────────────────┐
│              Domain Layer                            │
│  Responsibility: Business logic errors               │
└─────────────┬───────────────────────────────────────┘
              │ Throws: DomainError types
              │
┌─────────────▼───────────────────────────────────────┐
│          Infrastructure Layer                        │
│  Responsibility: System/framework errors             │
└─────────────────────────────────────────────────────┘
              Throws: InfrastructureError types
```

---

## Error Type Hierarchy

### Root Error Protocol

```swift
/// Base protocol for all SwiftCompress errors
protocol SwiftCompressError: Error, CustomStringConvertible {
    /// Human-readable error description
    var description: String { get }

    /// Technical error code for debugging
    var errorCode: String { get }

    /// Optional underlying cause
    var underlyingError: Error? { get }
}
```

### Layer-Specific Error Types

#### 1. Infrastructure Errors

**Purpose**: Represent system-level failures

```swift
enum InfrastructureError: SwiftCompressError {
    // File System Errors
    case fileNotFound(path: String)
    case fileNotReadable(path: String, reason: String?)
    case fileNotWritable(path: String, reason: String?)
    case directoryNotFound(path: String)
    case directoryNotWritable(path: String)
    case insufficientDiskSpace(required: Int64, available: Int64)

    // I/O Errors
    case readFailed(path: String, underlyingError: Error)
    case writeFailed(path: String, underlyingError: Error)
    case streamCreationFailed(path: String)
    case streamReadFailed(underlyingError: Error)
    case streamWriteFailed(underlyingError: Error)

    // Compression Framework Errors
    case compressionInitFailed(algorithm: String, underlyingError: Error?)
    case compressionFailed(algorithm: String, reason: String?)
    case decompressionFailed(algorithm: String, reason: String?)
    case corruptedData(algorithm: String)
    case unsupportedFormat(algorithm: String)

    var description: String { ... }
    var errorCode: String { ... }
    var underlyingError: Error? { ... }
}
```

**Error Code Prefix**: `INFRA-`

**Examples**:
- `INFRA-001`: File not found
- `INFRA-002`: File not readable
- `INFRA-010`: Compression initialization failed

#### 2. Domain Errors

**Purpose**: Represent business logic violations

```swift
enum DomainError: SwiftCompressError {
    // Algorithm Errors
    case invalidAlgorithmName(name: String, supported: [String])
    case algorithmNotRegistered(name: String)

    // Path Errors
    case invalidInputPath(path: String, reason: String)
    case invalidOutputPath(path: String, reason: String)
    case inputOutputSame(path: String)
    case pathTraversalAttempt(path: String)

    // File State Errors
    case outputFileExists(path: String)
    case inputFileEmpty(path: String)
    case fileTooLarge(path: String, size: Int64, limit: Int64)

    // Validation Errors
    case missingRequiredArgument(argumentName: String)
    case invalidFlagCombination(flags: [String], reason: String)

    var description: String { ... }
    var errorCode: String { ... }
    var underlyingError: Error? { ... }
}
```

**Error Code Prefix**: `DOMAIN-`

**Examples**:
- `DOMAIN-001`: Invalid algorithm name
- `DOMAIN-010`: Output file already exists
- `DOMAIN-020`: Invalid input path

#### 3. Application Errors

**Purpose**: Represent application workflow failures

```swift
enum ApplicationError: SwiftCompressError {
    // Command Execution Errors
    case commandExecutionFailed(commandName: String, underlyingError: SwiftCompressError)
    case preconditionFailed(message: String)
    case postconditionFailed(message: String)

    // Workflow Errors
    case workflowInterrupted(stage: String, reason: String)
    case dependencyNotAvailable(dependencyName: String)

    var description: String { ... }
    var errorCode: String { ... }
    var underlyingError: Error? { ... }
}
```

**Error Code Prefix**: `APP-`

#### 4. CLI Errors

**Purpose**: Represent user input and CLI interaction errors

```swift
enum CLIError: SwiftCompressError {
    // Argument Parsing Errors
    case invalidCommand(provided: String, expected: [String])
    case missingRequiredArgument(name: String)
    case unknownFlag(flag: String)
    case invalidFlagValue(flag: String, value: String, expected: String)

    // General CLI Errors
    case helpRequested
    case versionRequested

    var description: String { ... }
    var errorCode: String { ... }
    var underlyingError: Error? { ... }
}
```

**Error Code Prefix**: `CLI-`

---

## Layer-Specific Error Handling

### Infrastructure Layer Error Handling

**Responsibility**: Catch and wrap system/framework errors

**Pattern**:
```swift
func compress(input: Data) throws -> Data {
    do {
        // Call Apple Compression Framework
        let compressed = try performCompression(input)
        return compressed
    } catch let error as NSError {
        // Translate system error to InfrastructureError
        if error.code == someSpecificCode {
            throw InfrastructureError.compressionFailed(
                algorithm: name,
                reason: error.localizedDescription
            )
        } else {
            throw InfrastructureError.compressionInitFailed(
                algorithm: name,
                underlyingError: error
            )
        }
    }
}
```

**Guidelines**:
- Catch all system/framework errors
- Translate to typed InfrastructureError
- Preserve underlying error for debugging
- Add contextual information (file paths, algorithm names)
- Never let system errors propagate unchanged

### Domain Layer Error Handling

**Responsibility**: Validate business rules and throw domain errors

**Pattern**:
```swift
func compress(inputPath: String, outputPath: String, algorithmName: String) throws {
    // Validate algorithm
    guard let algorithm = algorithmRegistry.algorithm(named: algorithmName) else {
        throw DomainError.invalidAlgorithmName(
            name: algorithmName,
            supported: algorithmRegistry.supportedAlgorithms
        )
    }

    // Validate paths
    try validationRules.validateInputPath(inputPath)
    try validationRules.validateOutputPath(outputPath)

    // Execute compression (may throw InfrastructureError)
    do {
        try streamProcessor.processCompression(...)
    } catch let error as InfrastructureError {
        // Let infrastructure errors propagate
        throw error
    }
}
```

**Guidelines**:
- Throw DomainError for business rule violations
- Let InfrastructureError propagate unchanged
- Validate early, before expensive operations
- Provide context in error messages
- Don't catch errors you can't handle

### Application Layer Error Handling

**Responsibility**: Orchestrate operations and translate errors

**Pattern**:
```swift
func execute() throws -> CommandResult {
    do {
        // Pre-execution validation
        guard fileHandler.fileExists(at: inputPath) else {
            throw DomainError.fileNotFound(path: inputPath)
        }

        // Execute compression
        try compressionEngine.compress(...)

        return .success(message: nil)

    } catch let error as DomainError {
        return .failure(error: error)
    } catch let error as InfrastructureError {
        return .failure(error: error)
    } catch {
        // Unexpected error - wrap it
        throw ApplicationError.commandExecutionFailed(
            commandName: "compress",
            underlyingError: error as? SwiftCompressError ?? DomainError.unexpectedError
        )
    }
}
```

**Guidelines**:
- Catch domain and infrastructure errors
- Return typed results (success/failure)
- Add application context to errors
- Wrap unexpected errors
- Use do-catch at command boundaries

### CLI Layer Error Handling

**Responsibility**: Convert errors to user output and exit codes

**Pattern**:
```swift
// main.swift
do {
    let parsedCommand = try argumentParser.parse(CommandLine.arguments)

    guard let command = parsedCommand else {
        // Help or version requested
        exit(0)
    }

    let result = try commandRouter.route(command)

    switch result {
    case .success(let message):
        if let message = message {
            outputFormatter.writeSuccess(message)
        }
        exit(0)

    case .failure(let error):
        let userError = errorHandler.handle(error)
        outputFormatter.writeError(userError)
        exit(userError.exitCode)
    }

} catch let error as SwiftCompressError {
    let userError = errorHandler.handle(error)
    outputFormatter.writeError(userError)
    exit(userError.exitCode)

} catch {
    // Completely unexpected error
    fputs("Error: An unexpected error occurred.\n", stderr)
    exit(1)
}
```

**Guidelines**:
- Top-level catch handles all errors
- Convert errors to user messages via ErrorHandler
- Always set appropriate exit code
- Write errors to stderr
- Never expose stack traces to users

---

## Error Translation Strategy

### ErrorHandler Implementation

**Purpose**: Translate technical errors into user-friendly messages

```swift
final class ErrorHandler: ErrorHandlerProtocol {
    func handle(_ error: Error) -> UserFacingError {
        switch error {
        // Infrastructure Errors
        case InfrastructureError.fileNotFound(let path):
            return UserFacingError(
                message: "Error: File not found: \(sanitizePath(path))",
                exitCode: 1,
                shouldPrintStackTrace: false
            )

        case InfrastructureError.fileNotReadable(let path, let reason):
            let reasonText = reason.map { ": \($0)" } ?? ""
            return UserFacingError(
                message: "Error: Cannot read file: \(sanitizePath(path))\(reasonText)",
                exitCode: 1,
                shouldPrintStackTrace: false
            )

        case InfrastructureError.insufficientDiskSpace(let required, let available):
            return UserFacingError(
                message: "Error: Insufficient disk space. Required: \(formatBytes(required)), Available: \(formatBytes(available))",
                exitCode: 1,
                shouldPrintStackTrace: false
            )

        case InfrastructureError.corruptedData(let algorithm):
            return UserFacingError(
                message: "Error: File appears to be corrupted or not compressed with \(algorithm)",
                exitCode: 1,
                shouldPrintStackTrace: false
            )

        // Domain Errors
        case DomainError.invalidAlgorithmName(let name, let supported):
            return UserFacingError(
                message: "Error: Unknown algorithm '\(name)'. Supported algorithms: \(supported.joined(separator: ", "))",
                exitCode: 1,
                shouldPrintStackTrace: false
            )

        case DomainError.outputFileExists(let path):
            return UserFacingError(
                message: "Error: Output file already exists: \(sanitizePath(path))\nUse -f flag to overwrite.",
                exitCode: 1,
                shouldPrintStackTrace: false
            )

        case DomainError.inputOutputSame(let path):
            return UserFacingError(
                message: "Error: Input and output paths are the same: \(sanitizePath(path))",
                exitCode: 1,
                shouldPrintStackTrace: false
            )

        // CLI Errors
        case CLIError.missingRequiredArgument(let name):
            return UserFacingError(
                message: "Error: Missing required argument: \(name)\nRun 'swiftcompress --help' for usage.",
                exitCode: 1,
                shouldPrintStackTrace: false
            )

        // Default case
        default:
            return UserFacingError(
                message: "Error: An unexpected error occurred: \(error.localizedDescription)",
                exitCode: 1,
                shouldPrintStackTrace: false
            )
        }
    }

    // Helper: Sanitize paths for user display (truncate home directory, etc.)
    private func sanitizePath(_ path: String) -> String {
        // Implementation
    }

    // Helper: Format bytes for human readability
    private func formatBytes(_ bytes: Int64) -> String {
        // Implementation
    }
}
```

### Translation Guidelines

1. **Be Specific**: Identify exact problem (file not found, not "I/O error")
2. **Be Actionable**: Tell user what they can do to fix it
3. **Be Concise**: One or two sentences maximum
4. **Be Consistent**: Use same format for similar errors
5. **Hide Internals**: Don't expose implementation details
6. **Provide Context**: Include relevant information (paths, algorithm names)

---

## User-Facing Error Messages

### Message Format Standard

**Format**: `Error: <specific problem>[ <additional context>][\n<actionable guidance>]`

**Examples**:

**Good Messages**:
```
Error: File not found: /path/to/file.txt

Error: Output file already exists: output.txt.lzfse
Use -f flag to overwrite.

Error: Unknown algorithm 'lz5'. Supported algorithms: lzfse, lz4, zlib, lzma

Error: Insufficient disk space. Required: 1.2 GB, Available: 500 MB
```

**Bad Messages** (avoid):
```
Error: NSFileReadNoSuchFileError: The file doesn't exist.

Error: Compression failed with status code -1

Error: Exception in CompressionEngine.compress() at line 42

Error: Something went wrong
```

### Message Quality Criteria

1. **Clarity**: User immediately understands what went wrong
2. **Actionability**: User knows what to do next
3. **Relevance**: Information is specific to their situation
4. **Brevity**: Message is concise (< 100 characters ideal)
5. **Professional**: Tone is helpful, not blaming
6. **No Jargon**: Avoid technical terms when possible

### Context Information Guidelines

**Include**:
- File paths (sanitized)
- Algorithm names
- File sizes (human-readable)
- Supported options

**Exclude**:
- Stack traces
- Memory addresses
- Internal variable names
- Source code line numbers
- System error codes (unless meaningful)

---

## Exit Code Strategy

### Exit Code Definitions

**MVP (Phase 1)**: Single error code for simplicity

```swift
enum ExitCode: Int32 {
    case success = 0
    case failure = 1
}
```

**Phase 2**: Specific error codes for scriptability

```swift
enum ExitCode: Int32 {
    case success = 0
    case generalFailure = 1
    case invalidArguments = 2
    case fileNotFound = 3
    case permissionDenied = 4
    case compressionFailed = 5
    case decompressionFailed = 6
    case outputExists = 7
    case corruptedData = 8
    case diskFull = 9
}
```

### Exit Code Mapping (Phase 2)

| Error Type | Exit Code | Scenario |
|------------|-----------|----------|
| Success | 0 | Operation completed successfully |
| General Failure | 1 | Unexpected error |
| Invalid Arguments | 2 | Bad command-line arguments |
| File Not Found | 3 | Input file doesn't exist |
| Permission Denied | 4 | Cannot read/write file |
| Compression Failed | 5 | Compression operation failed |
| Decompression Failed | 6 | Decompression operation failed |
| Output Exists | 7 | Output file exists, -f not provided |
| Corrupted Data | 8 | Input file corrupted |
| Disk Full | 9 | Insufficient disk space |

### Exit Code Guidelines

1. **Always Set**: Every execution path must set exit code
2. **Be Specific**: Use specific codes for scriptability (Phase 2)
3. **Document**: Document exit codes in --help output
4. **Be Consistent**: Same error type = same exit code
5. **Follow Conventions**: 0 = success, non-zero = failure

---

## Error Context and Debugging

### Debug Information (Development Mode)

For development and debugging, provide additional context:

```swift
struct DebugError: SwiftCompressError {
    let originalError: SwiftCompressError
    let stackTrace: String
    let context: [String: Any]

    var description: String {
        """
        Error: \(originalError.description)
        Code: \(originalError.errorCode)
        Context: \(context)
        Stack: \(stackTrace)
        """
    }
}
```

**Enable Debug Mode**: Via environment variable or flag (future feature)

```bash
# Future feature
SWIFTCOMPRESS_DEBUG=1 swiftcompress c file.txt -m lzfse
# or
swiftcompress c file.txt -m lzfse --debug
```

### Logging Strategy (Future)

**Log Levels**:
- **Error**: All errors
- **Warning**: Potential issues
- **Info**: High-level operations
- **Debug**: Detailed execution flow

**Log Destination**:
- Development: Console (stderr)
- Production: Optional log file
- Debug mode: Verbose output

**What to Log**:
- All errors with full context
- File operations (path, size)
- Algorithm selection
- Performance metrics (compression time, ratio)

---

## Error Handling Patterns

### Pattern 1: Guard-Based Validation

**Use Case**: Early validation of preconditions

```swift
func compress(...) throws {
    // Validate inputs
    guard !inputPath.isEmpty else {
        throw DomainError.invalidInputPath(path: inputPath, reason: "Path is empty")
    }

    guard fileHandler.fileExists(at: inputPath) else {
        throw InfrastructureError.fileNotFound(path: inputPath)
    }

    guard inputPath != outputPath else {
        throw DomainError.inputOutputSame(path: inputPath)
    }

    // Proceed with operation
    ...
}
```

### Pattern 2: Do-Catch Translation

**Use Case**: Translate errors at layer boundaries

```swift
func processCompression(...) throws {
    do {
        try algorithm.compressStream(input: input, output: output, bufferSize: bufferSize)
    } catch let error as NSError {
        throw InfrastructureError.compressionFailed(
            algorithm: algorithm.name,
            reason: error.localizedDescription
        )
    }
}
```

### Pattern 3: Defer for Cleanup

**Use Case**: Ensure resource cleanup on error

```swift
func compressFile(...) throws {
    let inputStream = try fileHandler.inputStream(at: inputPath)
    defer { inputStream.close() }

    let outputStream = try fileHandler.outputStream(at: outputPath)
    defer {
        outputStream.close()
        // Cleanup partial output on error
        if !success {
            try? fileHandler.deleteFile(at: outputPath)
        }
    }

    try streamProcessor.processCompression(...)
    success = true
}
```

### Pattern 4: Result Type (Future)

**Use Case**: Asynchronous operations or functional patterns

```swift
func compressAsync(...) -> Result<String, SwiftCompressError> {
    do {
        try compress(...)
        return .success(outputPath)
    } catch let error as SwiftCompressError {
        return .failure(error)
    }
}
```

### Pattern 5: Error Recovery

**Use Case**: Attempt fallback strategies

```swift
func resolveOutputPath(...) -> String {
    let defaultPath = "\(inputPath).\(algorithm)"

    // If default exists, try alternative
    if fileHandler.fileExists(at: defaultPath) {
        let alternativePath = "\(inputPath).out"
        return alternativePath
    }

    return defaultPath
}
```

---

## Testing Error Scenarios

### Unit Testing Errors

**Approach**: Test that appropriate errors are thrown

```swift
func testCompressThrowsErrorWhenFileNotFound() {
    // Arrange
    let mockFileHandler = MockFileHandler()
    mockFileHandler.fileExistsResult = false
    let command = CompressCommand(fileHandler: mockFileHandler, ...)

    // Act & Assert
    XCTAssertThrowsError(try command.execute()) { error in
        XCTAssertTrue(error is InfrastructureError)
        if case InfrastructureError.fileNotFound(let path) = error {
            XCTAssertEqual(path, testInputPath)
        } else {
            XCTFail("Wrong error type")
        }
    }
}
```

### Integration Testing Errors

**Approach**: Test error scenarios with real dependencies

```swift
func testCompressionFailsWithCorruptedFile() {
    // Arrange: Create corrupted test file
    let corruptedFile = createCorruptedCompressedFile()

    // Act
    let result = try? decompressCommand.execute()

    // Assert
    XCTAssertNil(result)
    // Verify appropriate error logged
}
```

### E2E Testing Error Output

**Approach**: Verify CLI error output and exit codes

```swift
func testCLIOutputsErrorToStderrOnFileNotFound() {
    // Arrange
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/path/to/swiftcompress")
    process.arguments = ["c", "nonexistent.txt", "-m", "lzfse"]

    let stderrPipe = Pipe()
    process.standardError = stderrPipe

    // Act
    try? process.run()
    process.waitUntilExit()

    // Assert
    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
    let stderrOutput = String(data: stderrData, encoding: .utf8)

    XCTAssertEqual(process.terminationStatus, 1)
    XCTAssertTrue(stderrOutput?.contains("Error: File not found") ?? false)
}
```

### Error Message Testing

**Approach**: Verify error message quality

```swift
func testErrorMessagesAreUserFriendly() {
    let errorHandler = ErrorHandler()

    // Test various error types
    let errors: [(SwiftCompressError, expectedSubstring: String)] = [
        (InfrastructureError.fileNotFound(path: "/test.txt"), "File not found"),
        (DomainError.invalidAlgorithmName(name: "bad", supported: ["lzfse"]), "Unknown algorithm"),
        (DomainError.outputFileExists(path: "/out.txt"), "already exists")
    ]

    for (error, expected) in errors {
        let userError = errorHandler.handle(error)
        XCTAssertTrue(userError.message.contains(expected))
        XCTAssertFalse(userError.message.contains("NSError"))  // No system errors
    }
}
```

---

## Error Handling Quality Checklist

Before considering error handling complete, verify:

**Error Types**:
- [ ] All error cases have specific error types
- [ ] Error types organized by layer
- [ ] Error types implement SwiftCompressError protocol
- [ ] Error descriptions are clear and actionable

**Error Translation**:
- [ ] Infrastructure errors caught and wrapped
- [ ] Domain errors propagate correctly
- [ ] Application errors add context
- [ ] CLI layer converts to user messages

**User Experience**:
- [ ] All error messages are user-friendly
- [ ] No stack traces or internal details exposed
- [ ] Error messages provide actionable guidance
- [ ] Consistent error message format

**Exit Codes**:
- [ ] All execution paths set exit code
- [ ] Exit codes documented in help text
- [ ] Exit codes consistent across errors

**Resource Cleanup**:
- [ ] All resources cleaned up on error
- [ ] Partial output deleted on failure
- [ ] Streams and file handles closed
- [ ] Memory properly released

**Testing**:
- [ ] All error paths have unit tests
- [ ] Integration tests cover error scenarios
- [ ] E2E tests verify CLI error output
- [ ] Error messages tested for quality

---

## Future Enhancements

### Phase 2: Enhanced Error Reporting

- Specific exit codes for each error category
- Verbose mode with detailed error context
- --debug flag for development troubleshooting

### Phase 3: Advanced Error Handling

- Error logging to file
- Structured error output (JSON format)
- Error recovery strategies
- Retry logic for transient failures

---

## Summary

This error handling strategy provides:

1. **Type Safety**: Strongly-typed errors at each layer
2. **Clear Separation**: Each layer handles its own error concerns
3. **User-Friendly**: Errors translated to actionable messages
4. **Debuggable**: Preserve context for troubleshooting
5. **Testable**: All error paths covered by tests
6. **Maintainable**: Consistent patterns throughout codebase

By following this strategy, SwiftCompress delivers a robust, user-friendly error handling experience that guides users to successful outcomes and provides developers with clear debugging information.
