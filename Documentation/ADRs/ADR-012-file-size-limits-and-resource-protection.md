# ADR-012: File Size Limits and Resource Protection

**Status**: Proposed
**Date**: 2025-10-12
**Deciders**: Security Architecture Team
**Related**: SECURITY_ASSESSMENT.md, SECURITY_ARCHITECTURE_PLAN.md, ADR-010, ADR-011

---

## Context

Unbounded file operations in compression/decompression tools can lead to:

1. **Disk Exhaustion**: Output files consuming all available disk space
2. **Memory Exhaustion**: Even with streaming, intermediate buffers can grow
3. **Long-Running Operations**: Hours-long operations blocking system resources
4. **Denial of Service**: System becomes unresponsive or unusable
5. **Unexpected Costs**: Cloud storage costs in server deployments

### Current State

Swiftcompress currently has:
- **Streaming architecture**: Constant memory usage (~9.6 MB peak)
- **No file size limits**: Can compress/decompress arbitrarily large files
- **No pre-validation**: Starts operations without checking sizes
- **No disk space checks**: May fail mid-operation with disk full error

While streaming protects memory, there are no protections against:
- Disk exhaustion from large output files
- Accidentally processing multi-terabyte files
- Resource exhaustion from long-running operations

### Security Assessment Recommendation

**Priority 2 (HIGH)**: Implement file size limits for all operations
- Prevents resource exhaustion
- Protects against accidental large file processing
- Provides predictable resource usage

**Security Concerns**:
- CWE-400: Uncontrolled Resource Consumption
- OWASP A04:2021: Insecure Design
- No guardrails against resource abuse

### Real-World Scenarios

**Scenario 1: Accidental Large File**
```bash
$ swiftcompress c /Volumes/Backup/vmware-image.vmdk -m lzfse
# 500 GB VM image starts compressing
# Hours later, disk full, system unusable
```

**Scenario 2: Malicious Decompression**
```bash
$ swiftcompress x malicious.lzfse -m lzfse
# Small 10 MB file
# Decompresses to 2 TB
# Disk full, data loss risk
```

**Scenario 3: Server Deployment**
```bash
# Cloud server with 100 GB disk
$ swiftcompress c database-backup.sql -m lzma
# 200 GB uncompressed database
# Fills disk, crashes applications
```

---

## Decision

Implement **configurable file size limits** with:

### 1. Pre-Operation Validation

Check file sizes **before** starting expensive operations:

```swift
// Before compression
let inputSize = try fileHandler.fileSize(at: inputPath)
try resourceLimiter.validateFileSize(inputSize, for: .compression)

// Before decompression (estimated output)
let inputSize = try fileHandler.fileSize(at: inputPath)
let estimatedOutputSize = estimateOutputSize(inputSize, algorithm)
try resourceLimiter.validateFileSize(estimatedOutputSize, for: .decompression)
```

### 2. Default Limits

**Conservative limits for general use**:

```swift
maxInputFileSize: 5 GB    // Input file size limit
maxOutputFileSize: 10 GB  // Output file size limit
```

**Rationale**:
- **5 GB input**: Covers 99% of CLI use cases
- **10 GB output**: Allows 2:1 expansion (worst case)
- **Configurable**: Can be adjusted for specialized needs

### 3. Separate Limits by Operation

```swift
protocol ResourceLimitEnforcer: SecurityPolicy {
    var maxInputFileSize: Int64 { get }
    var maxOutputFileSize: Int64 { get }

    func validateFileSize(_ size: Int64, for operation: OperationType) throws
}
```

**Compression**:
- Limit: `maxInputFileSize` (5 GB)
- Rationale: Input is known size, output typically smaller

**Decompression**:
- Limit: `maxOutputFileSize` (10 GB)
- Rationale: Output size estimated, may expand

### 4. Clear Error Messages

```swift
throw DomainError.fileSizeExceedsLimit(
    size: actualSize,
    limit: configuredLimit,
    operation: .compression
)

// User sees:
// Error: Input file size (6.2 GB) exceeds maximum limit (5.0 GB)
// To compress larger files, adjust size limits in configuration
```

### 5. Disk Space Check (Future)

```swift
func validateDiskSpace(required: Int64, at path: String) throws {
    let available = try getAvailableDiskSpace(at: path)
    guard available >= required else {
        throw InfrastructureError.insufficientDiskSpace(
            required: required,
            available: available
        )
    }
}
```

---

## Alternatives Considered

### Alternative 1: No Limits

**Approach**: Allow unlimited file sizes, rely on streaming.

**Pros**:
- Maximum flexibility
- No artificial restrictions
- Handles any file size

**Cons**:
- Disk exhaustion risk
- Accidental large file processing
- No protection against resource abuse
- Long-running operations with no feedback
- Unpredictable resource usage

**Decision**: Rejected - Unacceptable security posture. Limits are standard practice in robust tools.

---

### Alternative 2: Runtime Resource Monitoring Only

**Approach**: Monitor disk space during operation, abort if running low.

**Pros**:
- Adaptive to available resources
- No pre-set limits needed
- Handles varying disk configurations

**Cons**:
- Wastes resources before aborting
- Complex to implement
- Platform-specific (disk space APIs vary)
- May be too late when detected (disk 99% full)
- Doesn't prevent starting operations that will fail

**Decision**: Rejected - Fails too late. Pre-validation is simpler and more effective.

---

### Alternative 3: Progressive Size Limits

**Approach**: Different limits based on algorithm or compression level.

**Example**:
```swift
// LZMA: stricter limits (slow compression)
maxInputFileSize: 2 GB

// LZ4: permissive limits (fast compression)
maxInputFileSize: 20 GB
```

**Pros**:
- Optimized for each algorithm
- Better resource utilization
- Accounts for performance characteristics

**Cons**:
- More complex configuration
- User confusion (why different limits?)
- Harder to document
- Not significantly better than single limit

**Decision**: Deferred - Single limit for MVP, consider algorithm-specific limits in future if needed.

---

### Alternative 4: Percentage-Based Limits

**Approach**: Limit based on available disk space percentage.

**Example**:
```swift
maxOutputSize = availableDiskSpace * 0.5  // Use max 50% of free space
```

**Pros**:
- Adaptive to disk capacity
- Prevents complete disk exhaustion
- No hard-coded limits

**Cons**:
- Unpredictable (varies by system)
- Difficult for users to reason about
- May still allow very large files
- Platform-specific implementation

**Decision**: Rejected for MVP - Fixed limits are more predictable. Consider as supplementary check in future.

---

### Alternative 5: User Confirmation for Large Files

**Approach**: Prompt user to confirm operations on large files.

**Example**:
```bash
$ swiftcompress c large-file.txt -m lzfse
Warning: Input file is 8.5 GB. Continue? [y/N]
```

**Pros**:
- User control
- Flexibility for large files
- Educational (users aware of size)

**Cons**:
- Breaks scriptability (non-interactive prompts)
- CLI tools should be quiet by default
- Doesn't work in automated pipelines
- Annoying for intentional large file operations

**Decision**: Rejected - Violates CLI best practices. Limits with configuration are better.

---

## Rationale

The chosen approach provides:

### 1. Fail Fast

**Validates before expensive operations**:

```swift
func execute() throws -> CommandResult {
    // EARLY VALIDATION (fast, cheap)
    let inputSize = try fileHandler.fileSize(at: inputPath)
    try securityCoordinator.validateFileSize(inputSize, for: .compression)

    // Now safe to start expensive compression
    try compressionEngine.compress(...)
}
```

**Benefit**: Fails in milliseconds, not after minutes/hours of processing.

### 2. Predictable Behavior

**Users know the limits**:
- Input files: 5 GB
- Output files: 10 GB
- Documented, consistent, understandable

**Benefit**: No surprises, can plan accordingly.

### 3. Configurable

**Adjust for different needs**:

```swift
// Default (general use)
let limiter = DefaultResourceLimitEnforcer()

// Large file support
let limiter = DefaultResourceLimitEnforcer(
    maxInputFileSize: 100 * GB,
    maxOutputFileSize: 200 * GB
)

// Server deployment (strict)
let limiter = DefaultResourceLimitEnforcer(
    maxInputFileSize: 1 * GB,
    maxOutputFileSize: 2 * GB
)
```

**Benefit**: Flexible for different deployment scenarios.

### 4. Clear Error Messages

```
Error: Input file size (6.2 GB) exceeds maximum limit (5.0 GB)

To compress larger files, you can:
1. Split the file into smaller chunks
2. Configure larger limits (advanced users)
3. Use a different tool designed for large files

For configuration options, see: docs/configuration.md
```

**Benefit**: User understands why and how to resolve.

### 5. Complements Bomb Detection

**Layered defense**:

| Protection Layer | Purpose | Limit |
|-----------------|---------|-------|
| File Size Limits | Pre-validation | Input: 5 GB, Output: 10 GB |
| Bomb Detection | Runtime monitoring | Ratio: 100:1, Size: 10 GB |

**Benefit**: Defense in depth, multiple safety nets.

### 6. Platform-Independent

**Pure file size checks**:
- No platform-specific APIs
- No disk space queries (simple version)
- Works on any macOS version
- Easy to test

**Benefit**: Simple, reliable, portable.

---

## Implementation Design

### Resource Limit Enforcer Protocol (Domain Layer)

```swift
/// Domain Layer - Resource limit enforcement protocol
protocol ResourceLimitEnforcer: SecurityPolicy {
    /// Maximum allowed input file size in bytes
    var maxInputFileSize: Int64 { get }

    /// Maximum allowed output file size in bytes
    var maxOutputFileSize: Int64 { get }

    /// Validate file size is within limits
    /// - Parameters:
    ///   - size: File size in bytes
    ///   - operation: Type of operation (compression/decompression)
    /// - Throws: DomainError.fileSizeExceedsLimit if size exceeds limit
    func validateFileSize(_ size: Int64, for operation: SecurityContext.OperationType) throws
}
```

### Default Implementation (Infrastructure Layer)

```swift
/// Infrastructure Layer - Default resource limit enforcer
final class DefaultResourceLimitEnforcer: ResourceLimitEnforcer {
    let name = "resource-limit-enforcer"

    let maxInputFileSize: Int64
    let maxOutputFileSize: Int64

    /// Initialize with configurable limits
    /// - Parameters:
    ///   - maxInputFileSize: Maximum input file size (default: 5 GB)
    ///   - maxOutputFileSize: Maximum output file size (default: 10 GB)
    init(
        maxInputFileSize: Int64 = 5_368_709_120,   // 5 GB
        maxOutputFileSize: Int64 = 10_737_418_240  // 10 GB
    ) {
        self.maxInputFileSize = maxInputFileSize
        self.maxOutputFileSize = maxOutputFileSize
    }

    func validateFileSize(_ size: Int64, for operation: SecurityContext.OperationType) throws {
        let limit: Int64
        let limitName: String

        switch operation {
        case .compression:
            limit = maxInputFileSize
            limitName = "input"
        case .decompression:
            limit = maxOutputFileSize
            limitName = "output"
        }

        guard size <= limit else {
            throw DomainError.fileSizeExceedsLimit(
                size: size,
                limit: limit,
                operation: operation
            )
        }
    }

    func validate(context: SecurityContext) throws {
        // Validate input size if provided
        if let inputSize = context.estimatedInputSize {
            try validateFileSize(inputSize, for: context.operation)
        }

        // Validate estimated output size if provided
        if let outputSize = context.estimatedOutputSize {
            // For output, use opposite operation limit
            let oppositeOp: SecurityContext.OperationType =
                context.operation == .compression ? .decompression : .compression
            try validateFileSize(outputSize, for: oppositeOp)
        }
    }
}
```

### Domain Error

```swift
extension DomainError {
    /// File size exceeds configured limit
    case fileSizeExceedsLimit(size: Int64, limit: Int64, operation: SecurityContext.OperationType)
}
```

### Integration in Commands

```swift
final class CompressCommand: Command {
    private let securityCoordinator: SecurityCoordinator

    func execute() throws -> CommandResult {
        // Resolve paths
        let resolvedInputPath = // ...
        let resolvedOutputPath = // ...

        // SECURITY: Validate input file size
        let inputSize = try fileHandler.fileSize(at: resolvedInputPath)

        try securityCoordinator.validateCompressionSecurity(
            inputPath: resolvedInputPath,
            outputPath: resolvedOutputPath,
            inputSize: inputSize
        )

        // Now safe to proceed with compression
        try compressionEngine.compress(...)

        return .success(message: nil)
    }
}
```

### Error Handling

```swift
extension ErrorHandler {
    func handle(_ error: Error) -> UserFacingError {
        switch error {
        case DomainError.fileSizeExceedsLimit(let size, let limit, let operation):
            let opName = operation == .compression ? "Input" : "Output"
            let message = """
            Error: \(opName) file size (\(size.formattedBytes)) exceeds maximum limit (\(limit.formattedBytes))

            For large files, consider:
            1. Splitting the file into smaller chunks
            2. Using a tool designed for large files
            3. Configuring larger limits (advanced users - see documentation)
            """
            return UserFacingError(
                message: message,
                exitCode: 1,
                shouldPrintStackTrace: false
            )

        // ... other errors
        }
    }
}
```

---

## Consequences

### Positive

1. **Resource Protection**
   - Prevents disk exhaustion
   - Prevents accidental large file processing
   - Predictable resource usage

2. **Fail Fast**
   - Validates before expensive operations
   - Saves time and resources
   - Clear error messages

3. **User Experience**
   - Clear feedback on file size issues
   - Actionable error messages
   - Predictable behavior

4. **Security**
   - Prevents resource exhaustion attacks
   - Limits impact of malicious files
   - Complements decompression bomb protection

5. **Configurable**
   - Adjustable for different use cases
   - No hard-coded limits in code
   - Dependency-injected

6. **Testable**
   - Easy to unit test
   - Predictable behavior
   - No platform-specific code

7. **Clean Architecture**
   - Protocol in Domain layer
   - Implementation in Infrastructure
   - Maintains dependency direction

### Negative

1. **Artificial Limits**
   - Rejects legitimate large files
   - Users with large files must reconfigure
   - **Mitigation**: Sensible defaults, clear documentation, easy configuration

2. **Configuration Complexity**
   - Users need to understand limits
   - May need environment-specific configuration
   - **Mitigation**: Sensible defaults cover 99% of use cases

3. **False Sense of Security**
   - Size limits don't guarantee available disk space
   - File system may have less free space
   - **Mitigation**: Future enhancement to check available space

4. **Output Size Estimation**
   - Cannot predict exact output size for compression
   - Estimation may be inaccurate
   - **Mitigation**: Conservative estimates, separate output limit (10 GB)

### Neutral

1. **Documentation Required**
   - Need to document limits
   - Need to explain configuration
   - Standard requirement

2. **Breaking Change Potential**
   - New limits may break workflows with large files
   - **Mitigation**: Version 1.3.0 announcement, clear release notes

---

## Implementation Effort

### Development (1.5 days)

**Day 1 (4 hours)**:
- Define `ResourceLimitEnforcer` protocol (0.5 hour)
- Implement `DefaultResourceLimitEnforcer` (1 hour)
- Add `DomainError.fileSizeExceedsLimit` (0.5 hour)
- Add to `SecurityPolicy` composition (0.5 hour)
- Integrate in `SecurityCoordinator` (1 hour)
- Wire through dependency injection (0.5 hour)

**Day 2 (4 hours)**:
- Integrate in `CompressCommand` (1 hour)
- Integrate in `DecompressCommand` (1 hour)
- Update `ErrorHandler` with new error type (0.5 hour)
- Add helper functions (size formatting, estimates) (1 hour)
- Code review and refactoring (0.5 hour)

### Testing (1 day)

**Unit Tests (4 hours)**:
- Test enforcer with various sizes (1 hour)
- Test boundary conditions (0.5 hour)
- Test error messages (0.5 hour)
- Test security context validation (0.5 hour)
- Test integration with commands (1 hour)
- Test error handler formatting (0.5 hour)

**Integration Tests (2 hours)**:
- Test with real large files (1 hour)
- Test with files at boundary limits (0.5 hour)
- Test error output (0.5 hour)

**E2E Tests (2 hours)**:
- Test CLI with oversized files (1 hour)
- Test CLI with files at limits (0.5 hour)
- Test error messages in terminal (0.5 hour)

### Documentation (0.5 day)

**Documentation (4 hours)**:
- Configuration guide (1 hour)
- Error message reference (0.5 hour)
- Large file handling guide (1 hour)
- FAQ for common issues (0.5 hour)
- Update architecture docs (1 hour)

**Total Effort**: 3 days

---

## Compliance Mapping

### CWE Coverage

**CWE-400: Uncontrolled Resource Consumption**
- **Mitigation**: Explicit file size limits
- **Status**: ✅ Fully addressed

**CWE-770: Allocation of Resources Without Limits**
- **Mitigation**: Pre-operation validation with limits
- **Status**: ✅ Addressed

### OWASP Top 10 Coverage

**A04:2021 - Insecure Design**
- **Mitigation**: Security designed into resource management
- **Status**: ✅ Addressed

**A05:2021 - Security Misconfiguration**
- **Mitigation**: Secure defaults, configurable limits
- **Status**: ✅ Addressed

---

## Configuration Reference

### Default Configuration

```swift
let enforcer = DefaultResourceLimitEnforcer()
// maxInputFileSize: 5 GB
// maxOutputFileSize: 10 GB
```

**Use Case**: General CLI usage, personal computers

### Conservative Configuration (Server/Multi-User)

```swift
let enforcer = DefaultResourceLimitEnforcer(
    maxInputFileSize: 1_073_741_824,   // 1 GB
    maxOutputFileSize: 2_147_483_648   // 2 GB
)
```

**Use Case**: Shared servers, strict resource control

### Permissive Configuration (Workstation/High-End)

```swift
let enforcer = DefaultResourceLimitEnforcer(
    maxInputFileSize: 107_374_182_400,   // 100 GB
    maxOutputFileSize: 214_748_364_800   // 200 GB
)
```

**Use Case**: High-end workstations, large file processing

### Unlimited Configuration (Not Recommended)

```swift
let enforcer = DefaultResourceLimitEnforcer(
    maxInputFileSize: Int64.max,
    maxOutputFileSize: Int64.max
)
```

**Use Case**: Special cases, advanced users only
**Risk**: No protection against resource exhaustion

### Future: Environment Variable Configuration

```bash
# Set custom limits
export SWIFTCOMPRESS_MAX_INPUT_SIZE=10737418240  # 10 GB
export SWIFTCOMPRESS_MAX_OUTPUT_SIZE=21474836480  # 20 GB

# Unlimited (not recommended)
export SWIFTCOMPRESS_MAX_INPUT_SIZE=unlimited
export SWIFTCOMPRESS_MAX_OUTPUT_SIZE=unlimited
```

---

## Testing Strategy

### Unit Tests (12 tests)

```swift
class ResourceLimitEnforcerTests: XCTestCase {
    var enforcer: DefaultResourceLimitEnforcer!

    func testSmallFile_BelowLimit_DoesNotThrow() {
        // Size: 1 GB (below 5 GB limit)
        XCTAssertNoThrow(try enforcer.validateFileSize(1_073_741_824, for: .compression))
    }

    func testLargeFile_ExceedsLimit_ThrowsError() {
        // Size: 10 GB (exceeds 5 GB limit)
        XCTAssertThrowsError(try enforcer.validateFileSize(10_737_418_240, for: .compression)) { error in
            guard case DomainError.fileSizeExceedsLimit(let size, let limit, let op) = error else {
                XCTFail("Wrong error type")
                return
            }
            XCTAssertEqual(size, 10_737_418_240)
            XCTAssertEqual(limit, 5_368_709_120)
            XCTAssertEqual(op, .compression)
        }
    }

    func testExactlyAtLimit_DoesNotThrow() {
        // Size: Exactly 5 GB
        XCTAssertNoThrow(try enforcer.validateFileSize(5_368_709_120, for: .compression))
    }

    func testOneByteOverLimit_ThrowsError() {
        // Size: 5 GB + 1 byte
        XCTAssertThrowsError(try enforcer.validateFileSize(5_368_709_121, for: .compression))
    }

    func testZeroSize_DoesNotThrow() {
        XCTAssertNoThrow(try enforcer.validateFileSize(0, for: .compression))
    }

    func testNegativeSize_HandledGracefully() {
        // Edge case: negative size (shouldn't happen in practice)
        // Should not throw (negative is less than limit)
        XCTAssertNoThrow(try enforcer.validateFileSize(-1, for: .compression))
    }

    func testCompressionOperation_UsesInputLimit() {
        // Compression should check against input limit (5 GB)
        let size: Int64 = 6_000_000_000  // 6 GB
        XCTAssertThrowsError(try enforcer.validateFileSize(size, for: .compression))
    }

    func testDecompressionOperation_UsesOutputLimit() {
        // Decompression should check against output limit (10 GB)
        let size: Int64 = 6_000_000_000  // 6 GB (below 10 GB output limit)
        XCTAssertNoThrow(try enforcer.validateFileSize(size, for: .decompression))

        let largeSize: Int64 = 15_000_000_000  // 15 GB (exceeds 10 GB output limit)
        XCTAssertThrowsError(try enforcer.validateFileSize(largeSize, for: .decompression))
    }

    func testCustomLimits_AreRespected() {
        let customEnforcer = DefaultResourceLimitEnforcer(
            maxInputFileSize: 1_073_741_824,   // 1 GB
            maxOutputFileSize: 2_147_483_648   // 2 GB
        )

        // 1.5 GB (below default 5 GB but above custom 1 GB)
        XCTAssertThrowsError(try customEnforcer.validateFileSize(1_500_000_000, for: .compression))
    }

    func testSecurityContextValidation_ValidatesInputSize() {
        let context = SecurityContext(
            inputPath: "/test/input.txt",
            outputPath: "/test/output.lzfse",
            operation: .compression,
            estimatedInputSize: 10_737_418_240,  // 10 GB
            estimatedOutputSize: nil,
            compressionRatio: nil
        )

        XCTAssertThrowsError(try enforcer.validate(context: context))
    }

    func testSecurityContextValidation_ValidatesEstimatedOutputSize() {
        let context = SecurityContext(
            inputPath: "/test/input.lzfse",
            outputPath: "/test/output.txt",
            operation: .decompression,
            estimatedInputSize: 100_000_000,  // 100 MB compressed
            estimatedOutputSize: 15_000_000_000,  // 15 GB decompressed (exceeds 10 GB limit)
            compressionRatio: 150.0
        )

        XCTAssertThrowsError(try enforcer.validate(context: context))
    }

    func testErrorMessage_IsDescriptive() {
        do {
            try enforcer.validateFileSize(10_737_418_240, for: .compression)
            XCTFail("Should have thrown error")
        } catch let error as DomainError {
            if case .fileSizeExceedsLimit(let size, let limit, _) = error {
                // Verify error contains sizes
                XCTAssertEqual(size, 10_737_418_240)
                XCTAssertEqual(limit, 5_368_709_120)
            } else {
                XCTFail("Wrong error case")
            }
        } catch {
            XCTFail("Wrong error type")
        }
    }
}
```

### Integration Tests (5 tests)

```swift
class ResourceLimitIntegrationTests: XCTestCase {
    func testCompressOversizedFile_FailsImmediately() throws {
        // Create 6 GB test file
        let testFile = createLargeTestFile(size: 6 * GB)

        let command = CompressCommand(
            // ... with default resource limits
        )

        // Should fail immediately, not after reading entire file
        let start = Date()
        XCTAssertThrowsError(try command.execute())
        let elapsed = Date().timeIntervalSince(start)

        // Should fail in < 1 second (just file size check)
        XCTAssertLessThan(elapsed, 1.0)
    }

    func testCompressAtLimit_Succeeds() throws {
        // Create 5 GB test file (exactly at limit)
        let testFile = createLargeTestFile(size: 5 * GB)

        let command = CompressCommand(/* ... */)

        // Should succeed
        XCTAssertNoThrow(try command.execute())
    }

    func testDecompressWithLargeEstimatedOutput_Fails() {
        // Create compressed file that would decompress to > 10 GB
        let testFile = createDecompressionBomb(
            compressedSize: 100 * MB,
            estimatedDecompressed: 15 * GB
        )

        let command = DecompressCommand(/* ... */)

        XCTAssertThrowsError(try command.execute())
    }

    func testCustomLimits_InRealCommand() throws {
        let permissiveEnforcer = DefaultResourceLimitEnforcer(
            maxInputFileSize: 100 * GB,
            maxOutputFileSize: 200 * GB
        )

        // Create 10 GB file (would fail with default limits)
        let testFile = createLargeTestFile(size: 10 * GB)

        let command = CompressCommand(
            // ... with permissive enforcer
        )

        // Should succeed with custom limits
        XCTAssertNoThrow(try command.execute())
    }

    func testErrorMessage_IsUserFriendly() {
        let testFile = createLargeTestFile(size: 10 * GB)

        let command = CompressCommand(/* ... */)

        do {
            try command.execute()
            XCTFail("Should have thrown")
        } catch {
            let errorHandler = ErrorHandler()
            let userError = errorHandler.handle(error)

            // Verify user-friendly message
            XCTAssertTrue(userError.message.contains("exceeds maximum limit"))
            XCTAssertTrue(userError.message.contains("10") || userError.message.contains("10.0 GB"))
            XCTAssertTrue(userError.message.contains("5") || userError.message.contains("5.0 GB"))
        }
    }
}
```

### E2E Tests (3 tests)

```swift
class ResourceLimitE2ETests: XCTestCase {
    func testCLI_RejectsOversizedFile() throws {
        let testFile = createLargeTestFile(size: 10 * GB)

        let process = Process()
        process.executableURL = swiftcompressBinary
        process.arguments = ["c", testFile, "-m", "lzfse"]

        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        // Should exit with error
        XCTAssertEqual(process.terminationStatus, 1)

        // Check error message
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        XCTAssertTrue(stderr?.contains("exceeds maximum limit") ?? false)
    }

    func testCLI_AcceptsFileAtLimit() throws {
        let testFile = createLargeTestFile(size: 5 * GB)

        let process = Process()
        process.executableURL = swiftcompressBinary
        process.arguments = ["c", testFile, "-m", "lzfse"]

        try process.run()
        process.waitUntilExit()

        // Should succeed
        XCTAssertEqual(process.terminationStatus, 0)
    }

    func testCLI_ErrorMessage_IsHelpful() throws {
        let testFile = createLargeTestFile(size: 10 * GB)

        let process = Process()
        process.executableURL = swiftcompressBinary
        process.arguments = ["c", testFile, "-m", "lzfse"]

        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        // Check for helpful information
        XCTAssertTrue(stderr.contains("10") || stderr.contains("10.0 GB"))  // Actual size
        XCTAssertTrue(stderr.contains("5") || stderr.contains("5.0 GB"))    // Limit
        XCTAssertTrue(stderr.contains("split") || stderr.contains("chunk") || stderr.contains("configuration"))  // Guidance
    }
}
```

---

## Future Enhancements

### Phase 2: Available Disk Space Check

```swift
func validateDiskSpace(required: Int64, at path: String) throws {
    let attributes = try FileManager.default.attributesOfFileSystem(forPath: path)
    guard let freeSpace = attributes[.systemFreeSize] as? Int64 else {
        return  // Can't determine, skip check
    }

    guard freeSpace >= required else {
        throw InfrastructureError.insufficientDiskSpace(
            required: required,
            available: freeSpace
        )
    }
}
```

### Phase 3: Progressive Limit System

```swift
enum ResourceTier {
    case small   // < 100 MB: Always allowed
    case medium  // 100 MB - 1 GB: Allowed
    case large   // 1 GB - 5 GB: Check disk space
    case xlarge  // > 5 GB: Require confirmation or config
}
```

### Phase 4: Algorithm-Specific Limits

```swift
struct AlgorithmResourceLimits {
    let lz4MaxInput: Int64 = 50 * GB      // Fast, allow larger
    let lzmaMaxInput: Int64 = 1 * GB      // Slow, stricter limit
    let lzfseMaxInput: Int64 = 10 * GB    // Balanced
    let zlibMaxInput: Int64 = 10 * GB     // Balanced
}
```

---

## Related Documents

- **SECURITY_ASSESSMENT.md**: Resource exhaustion finding
- **SECURITY_ARCHITECTURE_PLAN.md**: Complete security plan
- **ADR-010**: Decompression Bomb Protection Strategy
- **ADR-011**: Security Logging and Audit Trail Approach

---

## Rollout Strategy

### Phase 1: Opt-In (Week 1)

- Limits available but not enforced by default
- Enable via build flag
- Gather feedback on appropriate default limits

### Phase 2: Warnings (Week 2)

- Log warnings for oversized files
- Still allow operation
- Track how often limits would be exceeded

### Phase 3: Enforced (Week 3+)

- Limits enforced by default
- Clear error messages
- Configuration options documented

---

## Approval

**Proposed**: 2025-10-12
**Review Period**: 1 week
**Expected Acceptance**: 2025-10-19

---

**END OF ADR-012**
