# SwiftCompress Component Specifications

**Version**: 1.0
**Last Updated**: 2025-10-07

This document provides detailed specifications for each component in the SwiftCompress architecture, defining responsibilities, interfaces, interactions, and implementation guidance.

---

## Table of Contents

1. [CLI Interface Layer Components](#cli-interface-layer-components)
2. [Application Layer Components](#application-layer-components)
3. [Domain Layer Components](#domain-layer-components)
4. [Infrastructure Layer Components](#infrastructure-layer-components)

---

## CLI Interface Layer Components

### 1. main.swift (Entry Point)

**Responsibility**: Application entry point and dependency injection setup

**Key Functions**:
- Initialize application dependencies
- Configure dependency injection container
- Invoke ArgumentParser with command-line arguments
- Set process exit code based on execution result
- Handle top-level exceptions

**Interactions**:
- Creates and configures all concrete implementations
- Instantiates CommandRouter with dependencies
- Catches unhandled exceptions and sets exit code 1

**Error Handling**:
- Catch all exceptions at top level
- Log to stderr for unexpected errors
- Always set appropriate exit code

**Testing Notes**:
- E2E tests execute the full binary
- Integration tests bypass main.swift and test CommandRouter directly

**Implementation Guidelines**:
- Keep minimal logic in main.swift
- All configuration should be explicit and readable
- Use protocol-based dependency injection
- Initialize infrastructure components (FileSystemHandler, AppleCompressionAdapter)
- Wire dependencies into domain and application layers

---

### 2. ArgumentParser

**Responsibility**: Parse and validate command-line arguments

**Key Functions**:
- Parse command-line arguments into structured data
- Validate argument combinations
- Handle --help and --version flags
- Provide usage information on invalid input

**Interface Contract**:

```swift
protocol ArgumentParserProtocol {
    /// Parse arguments and return structured command data
    /// Returns nil if --help or --version requested
    func parse(_ arguments: [String]) throws -> ParsedCommand?
}

struct ParsedCommand {
    let commandType: CommandType  // .compress or .decompress
    let inputPath: String
    let algorithmName: String?    // Optional for decompression
    let outputPath: String?       // Optional, defaults applied later
    let forceOverwrite: Bool
}

enum CommandType {
    case compress
    case decompress
}
```

**Interactions**:
- Receives raw command-line arguments from main.swift
- Returns ParsedCommand to CommandRouter
- Throws ArgumentParsingError on invalid input

**Validation Rules**:
- Ensure command is either 'c' or 'x'
- Ensure inputPath is provided
- For compression: -m flag is required in MVP
- For decompression: -m is optional (can be inferred)
- Validate algorithm name against known values if provided
- Validate flag combinations

**Error Cases**:
- Missing required arguments
- Invalid command type
- Unknown algorithm name
- Conflicting flags
- Invalid file path characters

**Testing Strategy**:
- Unit test all argument combinations
- Test error cases with invalid inputs
- Verify --help and --version handling
- Test default value application

**Implementation Guidelines**:
- Use Swift ArgumentParser for CLI parsing
- Translate library-specific errors to domain errors
- Keep parsing logic separate from validation logic
- Provide clear error messages for each failure case

---

### 3. CommandRouter

**Responsibility**: Route parsed commands to appropriate command handlers

**Key Functions**:
- Create appropriate command handler based on command type
- Inject dependencies into command handlers
- Execute command and return result
- Handle command-level errors

**Interface Contract**:

```swift
protocol CommandRouterProtocol {
    /// Route and execute the parsed command
    func route(_ command: ParsedCommand) throws -> CommandResult
}

enum CommandResult {
    case success(message: String?)
    case failure(error: SwiftCompressError)
}
```

**Interactions**:
- Receives ParsedCommand from ArgumentParser
- Creates CompressCommand or DecompressCommand
- Delegates execution to CommandExecutor
- Returns CommandResult to main.swift

**Routing Logic**:
- Map CommandType.compress → CompressCommand
- Map CommandType.decompress → DecompressCommand
- Inject all required dependencies

**Error Handling**:
- Catch and wrap command execution errors
- Ensure errors are properly typed

**Testing Strategy**:
- Unit test routing logic with mocked commands
- Verify correct command instantiation
- Test error propagation

**Implementation Guidelines**:
- Use factory pattern for command creation
- Keep routing logic simple and declarative
- All dependencies should be injected via constructor

---

### 4. OutputFormatter

**Responsibility**: Format output messages for terminal display

**Key Functions**:
- Format success messages for stdout
- Format error messages for stderr
- Apply consistent formatting and styling
- Handle quiet mode (success produces no output)

**Interface Contract**:

```swift
protocol OutputFormatterProtocol {
    /// Write success message to stdout (typically empty in quiet mode)
    func writeSuccess(_ message: String?)

    /// Write error message to stderr
    func writeError(_ error: SwiftCompressError)

    /// Write help text to stdout
    func writeHelp(_ helpText: String)
}
```

**Interactions**:
- Called by main.swift based on CommandResult
- Writes to stdout for success
- Writes to stderr for errors

**Formatting Rules**:
- Success: No output by default (quiet mode)
- Errors: "Error: <message>" format to stderr
- Help: Formatted usage information to stdout

**Error Message Format**:
- Clear, actionable error descriptions
- No stack traces or internal details
- Include relevant context (file names, algorithm names)

**Testing Strategy**:
- Capture stdout/stderr in tests
- Verify message format and content
- Test error message clarity

**Implementation Guidelines**:
- Use Swift print() for stdout
- Use FileHandle.standardError for stderr
- Keep formatting simple and consistent
- Consider future colorized output as extension point

---

## Application Layer Components

### 5. CompressCommand

**Responsibility**: Orchestrate file compression workflow

**Key Functions**:
- Resolve output file path with defaults
- Check for existing file and handle overwrite logic
- Coordinate compression operation via CompressionEngine
- Handle application-level errors

**Interface Contract**:

```swift
protocol Command {
    func execute() throws -> CommandResult
}

final class CompressCommand: Command {
    let inputPath: String
    let algorithmName: String
    let outputPath: String?
    let forceOverwrite: Bool

    // Injected dependencies
    let compressionEngine: CompressionEngine
    let pathResolver: FilePathResolver
    let fileHandler: FileHandlerProtocol
}
```

**Execution Workflow**:

1. **Resolve Output Path**
   - If outputPath provided, use it
   - Otherwise, generate: `<inputPath>.<algorithmName>`
   - Delegate to FilePathResolver

2. **Validate Input File**
   - Check input file exists
   - Check input file is readable
   - Check input file size (future: size limits)

3. **Check Output File**
   - If output exists and forceOverwrite=false, throw error
   - If output exists and forceOverwrite=true, proceed
   - Ensure output directory exists and is writable

4. **Execute Compression**
   - Invoke CompressionEngine.compress()
   - Pass input path, output path, algorithm name
   - Handle errors from domain layer

5. **Return Result**
   - Return success with no message (quiet mode)
   - On error, return failure with translated error

**Error Scenarios**:
- Input file not found
- Input file not readable
- Output file exists without -f flag
- Output directory not writable
- Compression operation failure
- Disk full during write

**Testing Strategy**:
- Unit test with mocked dependencies
- Test each workflow step independently
- Test error handling for each scenario
- Verify default output path generation

**Implementation Guidelines**:
- Keep orchestration logic clear and sequential
- Delegate all business logic to domain layer
- Validate preconditions before invoking engine
- Ensure atomic operations (cleanup on failure)

---

### 6. DecompressCommand

**Responsibility**: Orchestrate file decompression workflow

**Key Functions**:
- Resolve output file path with defaults
- Infer algorithm from extension if not specified
- Check for existing file and handle overwrite logic
- Coordinate decompression operation via CompressionEngine

**Interface Contract**:

```swift
final class DecompressCommand: Command {
    let inputPath: String
    let algorithmName: String?  // Optional: can be inferred
    let outputPath: String?
    let forceOverwrite: Bool

    // Injected dependencies
    let compressionEngine: CompressionEngine
    let pathResolver: FilePathResolver
    let fileHandler: FileHandlerProtocol
}
```

**Execution Workflow**:

1. **Determine Algorithm**
   - If algorithmName provided, use it
   - Otherwise, infer from file extension (e.g., .lzfse → lzfse)
   - Throw error if cannot determine algorithm

2. **Resolve Output Path**
   - If outputPath provided, use it
   - Otherwise, strip algorithm extension from input
   - If stripped file exists, append ".out"
   - Delegate to FilePathResolver

3. **Validate Input File**
   - Check input file exists
   - Check input file is readable
   - Validate file has expected format (header check if possible)

4. **Check Output File**
   - If output exists and forceOverwrite=false, throw error
   - If output exists and forceOverwrite=true, proceed
   - Ensure output directory exists and is writable

5. **Execute Decompression**
   - Invoke CompressionEngine.decompress()
   - Pass input path, output path, algorithm name
   - Handle errors from domain layer

6. **Return Result**
   - Return success with no message (quiet mode)
   - On error, return failure with translated error

**Algorithm Inference Rules** (MVP: Phase 2 feature):
- `.lzfse` → lzfse
- `.lz4` → lz4
- `.zlib` → zlib
- `.lzma` → lzma
- If extension doesn't match, require explicit -m flag

**Error Scenarios**:
- Input file not found
- Cannot infer algorithm from extension
- Corrupted compressed data
- Output file exists without -f flag
- Decompression operation failure

**Testing Strategy**:
- Unit test algorithm inference logic
- Test output path resolution with various inputs
- Test error handling for each scenario
- Verify .out suffix logic for conflicts

**Implementation Guidelines**:
- Algorithm inference should be delegated to FilePathResolver
- Keep workflow similar to CompressCommand for consistency
- Handle corrupted data gracefully with clear error messages
- Validate compressed data format before decompression

---

### 7. CommandExecutor

**Responsibility**: Coordinate command execution and error handling

**Key Functions**:
- Execute command with consistent error handling
- Translate domain errors to application errors
- Ensure proper resource cleanup
- Log execution metadata (future: for verbose mode)

**Interface Contract**:

```swift
protocol CommandExecutorProtocol {
    func execute(_ command: Command) throws -> CommandResult
}

final class CommandExecutor: CommandExecutorProtocol {
    let errorHandler: ErrorHandlerProtocol
}
```

**Execution Pattern**:

1. **Pre-execution**
   - Validate command is properly configured
   - Setup error handling context

2. **Execute Command**
   - Invoke command.execute()
   - Catch and categorize errors

3. **Post-execution**
   - Ensure resource cleanup
   - Translate errors via ErrorHandler
   - Return standardized result

**Error Translation Flow**:
- Domain errors → Application errors
- Infrastructure errors → User-friendly messages
- Unexpected errors → Generic failure message

**Testing Strategy**:
- Unit test with various command outcomes
- Test error translation for each error type
- Verify resource cleanup on failure

**Implementation Guidelines**:
- Use do-catch for structured error handling
- Delegate error translation to ErrorHandler
- Keep execution logic generic and reusable
- Consider adding execution timing for verbose mode (future)

---

### 8. ErrorHandler

**Responsibility**: Translate errors to user-friendly messages and exit codes

**Key Functions**:
- Map domain errors to user-facing error messages
- Assign appropriate exit codes
- Provide contextual error information
- Sanitize error messages (no sensitive data)

**Interface Contract**:

```swift
protocol ErrorHandlerProtocol {
    /// Translate an error into user-facing format
    func handle(_ error: Error) -> UserFacingError
}

struct UserFacingError {
    let message: String
    let exitCode: Int
    let shouldPrintStackTrace: Bool  // false in production
}
```

**Error Categories and Exit Codes**:

- **Exit Code 0**: Success
- **Exit Code 1**: Generic failure (catch-all)
- **Exit Code 2**: Invalid arguments (reserved for future)
- **Exit Code 3**: File not found (reserved for future)
- **Exit Code 4**: Permission denied (reserved for future)
- **Exit Code 5**: Compression/decompression failed (reserved for future)

**MVP**: Use exit code 1 for all failures; specific codes in Phase 2

**Error Message Guidelines**:
- Be specific about what went wrong
- Provide actionable guidance when possible
- Don't expose internal implementation details
- Include relevant context (file names, algorithm names)

**Error Mapping Examples**:

| Domain Error | User Message | Exit Code |
|--------------|--------------|-----------|
| FileNotFoundError | "Error: File not found: <path>" | 1 |
| FileNotReadableError | "Error: Cannot read file: <path>" | 1 |
| OutputExistsError | "Error: Output file exists. Use -f to overwrite." | 1 |
| InvalidAlgorithmError | "Error: Unknown algorithm: <name>. Supported: lzfse, lz4, zlib, lzma" | 1 |
| CompressionFailedError | "Error: Compression failed: <reason>" | 1 |
| CorruptedDataError | "Error: File appears to be corrupted or not compressed with <algorithm>" | 1 |

**Testing Strategy**:
- Unit test error translation for each error type
- Verify message quality and clarity
- Test exit code assignment
- Validate no sensitive data in messages

**Implementation Guidelines**:
- Use switch statement for error type mapping
- Provide default generic message for unknown errors
- Consider localization hooks for future internationalization
- Keep messages consistent in tone and format

---

## Domain Layer Components

### 9. CompressionEngine

**Responsibility**: Core business logic for compression and decompression operations

**Key Functions**:
- Orchestrate compression workflow
- Orchestrate decompression workflow
- Select appropriate algorithm from registry
- Apply business rules and validation
- Coordinate between algorithm and file operations

**Interface Contract**:

```swift
protocol CompressionEngineProtocol {
    /// Compress a file using specified algorithm
    func compress(
        inputPath: String,
        outputPath: String,
        algorithmName: String
    ) throws

    /// Decompress a file using specified algorithm
    func decompress(
        inputPath: String,
        outputPath: String,
        algorithmName: String
    ) throws
}

final class CompressionEngine: CompressionEngineProtocol {
    let algorithmRegistry: AlgorithmRegistry
    let streamProcessor: StreamProcessorProtocol
}
```

**Compression Workflow**:

1. **Algorithm Selection**
   - Lookup algorithm in registry by name
   - Throw error if algorithm not found

2. **Validate Inputs**
   - Delegate to ValidationRules
   - Check file size constraints (future)

3. **Stream Processing**
   - Open input file stream
   - Initialize compression algorithm
   - Process data in chunks
   - Write compressed data to output
   - Close streams and cleanup

4. **Error Handling**
   - Handle I/O errors during processing
   - Handle compression algorithm errors
   - Ensure cleanup on failure

**Decompression Workflow**:

1. **Algorithm Selection**
   - Lookup algorithm in registry by name
   - Throw error if algorithm not found

2. **Validate Inputs**
   - Check compressed file format (header validation)
   - Verify algorithm compatibility

3. **Stream Processing**
   - Open input file stream
   - Initialize decompression algorithm
   - Process data in chunks
   - Write decompressed data to output
   - Close streams and cleanup

4. **Error Handling**
   - Handle corrupted data errors
   - Handle I/O errors during processing
   - Ensure cleanup on failure

**Business Rules**:
- Compression should be lossless (verified by algorithm)
- Output file should not be created if operation fails
- Partial output should be cleaned up on error
- Stream processing should use configurable buffer size

**Testing Strategy**:
- Unit test with mocked StreamProcessor and AlgorithmRegistry
- Test algorithm selection logic
- Test error handling for each failure scenario
- Integration test with real algorithms and temp files

**Implementation Guidelines**:
- Keep compression/decompression logic symmetric
- Use resource management (defer for cleanup)
- Process files in chunks, never load entire file
- Validate assumptions with assertions
- Make buffer size configurable (default: 64KB)

---

### 10. AlgorithmRegistry

**Responsibility**: Maintain registry of available compression algorithms

**Key Functions**:
- Register compression algorithms
- Lookup algorithms by name
- Provide list of supported algorithms
- Validate algorithm names

**Interface Contract**:

```swift
protocol AlgorithmRegistryProtocol {
    /// Register a compression algorithm
    func register(_ algorithm: CompressionAlgorithmProtocol)

    /// Retrieve algorithm by name
    func algorithm(named: String) -> CompressionAlgorithmProtocol?

    /// Get list of all supported algorithm names
    var supportedAlgorithms: [String] { get }
}

final class AlgorithmRegistry: AlgorithmRegistryProtocol {
    private var algorithms: [String: CompressionAlgorithmProtocol] = [:]
}
```

**Registration Pattern**:
- Algorithms registered at application startup in main.swift
- Registry is immutable after initialization
- Thread-safe for concurrent lookups (future consideration)

**Supported Algorithms (MVP)**:
- `lzfse`: LZFSE algorithm
- `lz4`: LZ4 algorithm
- `zlib`: Zlib/Deflate algorithm
- `lzma`: LZMA algorithm

**Lookup Logic**:
- Case-insensitive algorithm name matching
- Return nil if algorithm not found
- Fast O(1) lookup using dictionary

**Testing Strategy**:
- Unit test registration and lookup
- Test case-insensitive matching
- Test missing algorithm scenarios
- Verify supported algorithms list

**Implementation Guidelines**:
- Use dictionary for O(1) lookups
- Normalize algorithm names to lowercase
- Make registry immutable after initial setup
- Consider registry freezing to prevent runtime modifications

---

### 11. FilePathResolver

**Responsibility**: Resolve file paths with default naming conventions

**Key Functions**:
- Generate default output path for compression
- Generate default output path for decompression
- Infer algorithm from file extension
- Handle output file conflicts with .out suffix

**Interface Contract**:

```swift
protocol FilePathResolverProtocol {
    /// Resolve output path for compression
    /// Returns: <inputPath>.<algorithmName> if outputPath is nil
    func resolveCompressOutputPath(
        inputPath: String,
        algorithmName: String,
        outputPath: String?
    ) -> String

    /// Resolve output path for decompression
    /// Returns: inputPath with algorithm extension stripped
    /// If conflict, appends .out suffix
    func resolveDecompressOutputPath(
        inputPath: String,
        algorithmName: String,
        outputPath: String?,
        fileExists: (String) -> Bool
    ) -> String

    /// Infer algorithm from file extension
    /// Returns: Algorithm name or nil if cannot infer
    func inferAlgorithm(from filePath: String) -> String?
}
```

**Compression Output Path Logic**:
- If outputPath provided: return outputPath as-is
- Otherwise: return `<inputPath>.<algorithmName>`
- Example: `file.txt` + `lzfse` → `file.txt.lzfse`

**Decompression Output Path Logic**:
- If outputPath provided: return outputPath as-is
- Otherwise: strip algorithm extension from inputPath
- If stripped path exists: append `.out` suffix
- Example: `file.txt.lzfse` → `file.txt` (or `file.txt.out` if exists)

**Algorithm Inference Logic** (Phase 2 feature):
- Extract file extension
- Map extension to algorithm name:
  - `.lzfse` → `lzfse`
  - `.lz4` → `lz4`
  - `.zlib` → `zlib`
  - `.lzma` → `lzma`
- Return nil if extension doesn't match known algorithms

**Edge Cases**:
- Input files without extensions
- Multiple dots in filename
- Hidden files (starting with .)
- Paths with directories

**Testing Strategy**:
- Unit test all path resolution scenarios
- Test edge cases (no extension, multiple dots, etc.)
- Test algorithm inference for each supported extension
- Verify .out suffix logic

**Implementation Guidelines**:
- Use Foundation URL/NSString path manipulation
- Handle path edge cases (relative paths, trailing slashes)
- Make algorithm-to-extension mapping configurable
- Keep logic pure (no I/O, just string manipulation)

---

### 12. ValidationRules

**Responsibility**: Implement business validation rules

**Key Functions**:
- Validate file paths
- Validate algorithm names
- Validate file sizes (future)
- Apply business constraints

**Interface Contract**:

```swift
protocol ValidationRulesProtocol {
    /// Validate input file path
    func validateInputPath(_ path: String) throws

    /// Validate output file path
    func validateOutputPath(_ path: String) throws

    /// Validate algorithm name
    func validateAlgorithmName(_ name: String, registry: AlgorithmRegistryProtocol) throws

    /// Validate file size constraints (future)
    func validateFileSize(_ size: Int64) throws
}
```

**Validation Rules**:

**Input Path Validation**:
- Path must not be empty
- Path must not contain null bytes
- Path must not attempt directory traversal attacks
- Path must be absolute or resolvable

**Output Path Validation**:
- Path must not be empty
- Path must not be same as input path
- Path must not contain null bytes
- Directory portion must be writable

**Algorithm Name Validation**:
- Name must not be empty
- Name must exist in registry
- Name must match supported algorithm (case-insensitive)

**File Size Validation** (Future):
- File size must not exceed maximum limit
- Available disk space check for compression

**Security Considerations**:
- Prevent path traversal attacks (../)
- Validate against symbolic link attacks
- Ensure paths are within allowed boundaries

**Testing Strategy**:
- Unit test each validation rule independently
- Test security scenarios (path traversal, etc.)
- Test edge cases (empty strings, special characters)
- Verify appropriate error types are thrown

**Implementation Guidelines**:
- Throw specific validation error types
- Keep rules pure and side-effect free
- Make validation order deterministic
- Consider performance for frequently called validations

---

## Infrastructure Layer Components

### 13. AppleCompressionAdapter

**Responsibility**: Integrate with Apple Compression Framework

**Key Functions**:
- Compress data using Apple algorithms
- Decompress data using Apple algorithms
- Handle compression framework errors
- Provide streaming compression interface

**Interface Contract**:

```swift
protocol CompressionAlgorithmProtocol {
    var name: String { get }

    /// Compress data
    func compress(input: Data) throws -> Data

    /// Decompress data
    func decompress(input: Data) throws -> Data

    /// Stream-based compression (for large files)
    func compressStream(
        input: InputStream,
        output: OutputStream,
        bufferSize: Int
    ) throws

    /// Stream-based decompression (for large files)
    func decompressStream(
        input: InputStream,
        output: OutputStream,
        bufferSize: Int
    ) throws
}
```

**Algorithm Implementations**:
- LZFSEAlgorithm: Wraps COMPRESSION_LZFSE
- LZ4Algorithm: Wraps COMPRESSION_LZ4
- ZlibAlgorithm: Wraps COMPRESSION_ZLIB
- LZMAAlgorithm: Wraps COMPRESSION_LZMA

**Apple Framework Integration**:
- Use compression_stream_init() for stream setup
- Use compression_stream_process() for data processing
- Use compression_stream_destroy() for cleanup
- Handle COMPRESSION_STATUS_ERROR appropriately

**Error Scenarios**:
- Compression initialization failure
- Data corruption during decompression
- Insufficient buffer size
- Memory allocation failures

**Testing Strategy**:
- Unit test each algorithm with known test vectors
- Test round-trip compression/decompression
- Integration test with real files
- Test error handling for corrupted data

**Implementation Guidelines**:
- Each algorithm is a separate class implementing protocol
- Use defer for proper resource cleanup
- Wrap Apple framework errors in domain error types
- Optimize buffer sizes for performance
- Consider compression level tuning (future)

---

### 14. FileSystemHandler

**Responsibility**: Perform file system operations

**Key Functions**:
- Check file existence
- Read file data
- Write file data
- Create directories
- Check file permissions
- Delete files (for cleanup)

**Interface Contract**:

```swift
protocol FileHandlerProtocol {
    /// Check if file exists at path
    func fileExists(at path: String) -> Bool

    /// Check if file is readable
    func isReadable(at path: String) -> Bool

    /// Check if directory is writable
    func isWritable(at path: String) -> Bool

    /// Get file size
    func fileSize(at path: String) throws -> Int64

    /// Create input stream for reading
    func inputStream(at path: String) throws -> InputStream

    /// Create output stream for writing
    func outputStream(at path: String) throws -> OutputStream

    /// Delete file at path
    func deleteFile(at path: String) throws

    /// Create directory if needed
    func createDirectory(at path: String) throws
}
```

**FileManager Integration**:
- Wrap FileManager operations
- Translate FileManager errors to domain errors
- Handle permissions and access control
- Manage file attributes

**Stream Management**:
- Create and configure input/output streams
- Ensure proper stream opening/closing
- Handle stream errors gracefully
- Use buffered streams for performance

**Error Scenarios**:
- File not found
- Permission denied
- Disk full
- Invalid path
- I/O errors during read/write

**Testing Strategy**:
- Unit test with temporary directories
- Test permission scenarios
- Test disk space handling
- Mock FileManager for isolated testing

**Implementation Guidelines**:
- Use FileManager.default for operations
- Wrap all FileManager calls in error handling
- Use defer for stream cleanup
- Ensure thread-safety for concurrent operations (future)
- Make paths absolute before operations

---

### 15. StreamProcessor

**Responsibility**: Handle binary data streaming for compression operations

**Key Functions**:
- Process data in chunks
- Coordinate between input stream, algorithm, and output stream
- Handle streaming errors
- Manage buffer allocation

**Interface Contract**:

```swift
protocol StreamProcessorProtocol {
    /// Process compression stream
    func processCompression(
        input: InputStream,
        output: OutputStream,
        algorithm: CompressionAlgorithmProtocol,
        bufferSize: Int
    ) throws

    /// Process decompression stream
    func processDecompression(
        input: InputStream,
        output: OutputStream,
        algorithm: CompressionAlgorithmProtocol,
        bufferSize: Int
    ) throws
}
```

**Processing Algorithm**:

1. **Initialize**
   - Allocate input and output buffers
   - Open input and output streams
   - Initialize compression algorithm

2. **Process Loop**
   - Read chunk from input stream
   - Process chunk through algorithm
   - Write result to output stream
   - Repeat until input exhausted

3. **Finalize**
   - Flush any remaining data
   - Close streams
   - Deallocate buffers
   - Handle errors and cleanup

**Buffer Management**:
- Default buffer size: 64KB (configurable)
- Reuse buffers for efficiency
- Handle partial reads/writes
- Ensure proper deallocation

**Error Handling**:
- Handle read errors from input stream
- Handle write errors to output stream
- Handle algorithm processing errors
- Ensure cleanup on any error

**Testing Strategy**:
- Unit test with mock streams
- Test various buffer sizes
- Test error scenarios (read failure, write failure)
- Integration test with real files

**Implementation Guidelines**:
- Use Data for buffer allocation
- Process data in fixed-size chunks
- Handle stream state transitions properly
- Use defer for cleanup guarantees
- Consider async/await for future streaming (Phase 3)

---

### 16. Algorithm Implementations (LZFSEAlgorithm, LZ4Algorithm, etc.)

**Responsibility**: Concrete implementations of compression algorithms

**Key Functions**:
- Implement CompressionAlgorithmProtocol for each algorithm
- Wrap Apple Compression Framework specific algorithm
- Configure algorithm-specific parameters

**Implementation Pattern** (for each algorithm):

```swift
final class LZFSEAlgorithm: CompressionAlgorithmProtocol {
    let name = "lzfse"

    func compress(input: Data) throws -> Data {
        // Use COMPRESSION_LZFSE with Apple framework
    }

    func decompress(input: Data) throws -> Data {
        // Use COMPRESSION_LZFSE with Apple framework
    }

    func compressStream(...) throws {
        // Stream-based compression with COMPRESSION_LZFSE
    }

    func decompressStream(...) throws {
        // Stream-based decompression with COMPRESSION_LZFSE
    }
}
```

**Algorithm-Specific Details**:

**LZFSE**:
- Apple's proprietary algorithm
- Good balance of speed and compression ratio
- Default recommendation for macOS applications

**LZ4**:
- Extremely fast compression/decompression
- Lower compression ratio
- Good for time-sensitive operations

**Zlib**:
- Industry standard (compatible with gzip)
- Wide compatibility
- Moderate speed and compression ratio

**LZMA**:
- Highest compression ratio
- Slower compression speed
- Fast decompression

**Testing Strategy**:
- Test each algorithm independently
- Verify round-trip compression/decompression
- Test with various data types (text, binary, already compressed)
- Benchmark performance characteristics

**Implementation Guidelines**:
- Each algorithm is independent class
- Share common logic in base implementation if needed
- Handle algorithm-specific error codes
- Document algorithm characteristics in comments
- Make algorithm selection data-driven (future: from config)

---

## Component Interaction Patterns

### Dependency Injection Flow

```
main.swift
  │
  ├─> Creates FileSystemHandler
  ├─> Creates AppleCompressionAdapter (for each algorithm)
  ├─> Creates AlgorithmRegistry
  ├─> Registers algorithms
  ├─> Creates StreamProcessor
  ├─> Creates CompressionEngine (with registry, stream processor)
  ├─> Creates FilePathResolver
  ├─> Creates ValidationRules
  ├─> Creates ErrorHandler
  ├─> Creates CommandExecutor (with error handler)
  ├─> Creates ArgumentParser
  ├─> Creates CommandRouter (with all dependencies)
  └─> Executes CommandRouter.route()
```

### Error Propagation Pattern

```
Infrastructure Error (FileManager, Compression Framework)
         ↓
Domain Error Translation (via throws)
         ↓
Application Error Handling (ErrorHandler)
         ↓
User-Facing Error (OutputFormatter)
         ↓
Exit Code (main.swift)
```

### Data Flow Pattern

```
User Input → Parse → Validate → Execute → Process → Output
     ↓         ↓         ↓          ↓         ↓        ↓
   CLI      ArgParser  Validation  Command  Engine  Formatter
```

---

## Implementation Priority and Dependencies

### Phase 1: Foundation (Week 1)

**Priority 1** (No dependencies):
- Protocol definitions (all protocols)
- ValidationRules (pure logic)
- FilePathResolver (pure logic)
- Error type definitions

**Priority 2** (Depends on Priority 1):
- FileSystemHandler (basic file operations)
- AppleCompressionAdapter (algorithm implementations)
- AlgorithmRegistry

**Priority 3** (Depends on Priority 2):
- StreamProcessor
- CompressionEngine

### Phase 2: Application Logic (Week 2)

**Priority 4** (Depends on Phase 1):
- ErrorHandler
- CommandExecutor
- CompressCommand
- DecompressCommand

### Phase 3: CLI Interface (Week 3)

**Priority 5** (Depends on Phase 2):
- ArgumentParser (with Swift ArgumentParser integration)
- CommandRouter
- OutputFormatter
- main.swift

### Phase 4: Testing and Refinement (Week 4)

- Unit tests for all components
- Integration tests
- E2E tests
- Documentation and refinements

---

## Quality Gates

Each component must meet these criteria before completion:

1. **Functionality**: Implements all specified interface methods
2. **Error Handling**: Handles all specified error scenarios
3. **Testing**: Has comprehensive unit tests (>80% coverage)
4. **Documentation**: Has clear inline documentation
5. **SOLID Compliance**: Adheres to SOLID principles
6. **Code Review**: Passes peer review
7. **Integration**: Successfully integrates with dependent components

---

## Next Steps

Implementation teams should:
1. Review protocol definitions and interfaces
2. Implement components in priority order
3. Write unit tests alongside implementation
4. Conduct integration testing at phase boundaries
5. Refer to testing_strategy.md for detailed test specifications
6. Refer to error_handling_strategy.md for error type definitions

This component specification provides the foundation for building a well-architected, maintainable CLI compression tool.
