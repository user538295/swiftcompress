# ADR-010: Decompression Bomb Protection Strategy

**Status**: Proposed
**Date**: 2025-10-12
**Deciders**: Security Architecture Team
**Related**: SECURITY_ASSESSMENT.md (Finding 4.1), SECURITY_ARCHITECTURE_PLAN.md

---

## Context

Swiftcompress decompresses user-provided compressed files using Apple's Compression framework. Malicious actors could craft "decompression bombs" (also known as "zip bombs") - small compressed files that expand to enormous sizes when decompressed, potentially causing:

1. **Memory Exhaustion**: Even with streaming, intermediate buffers could grow excessively
2. **Disk Exhaustion**: Decompressed output could fill available disk space
3. **Denial of Service**: System becomes unresponsive due to resource exhaustion
4. **Application Crash**: Out-of-memory or disk-full errors

### Current Implementation Vulnerability

The current implementation in `AppleCompressionAlgorithm.decompress()` (line 141):

```swift
let inputSize = input.count
let estimatedOutputSize = max(inputSize * 4, 65536)
var outputBuffer = Data(count: estimatedOutputSize)
```

This allocates `inputSize * 4` bytes without:
- Checking absolute size limits
- Monitoring actual expansion ratios
- Detecting anomalous decompression patterns

### Security Assessment Finding

**Finding 4.1 (HIGH Priority)**: Missing Decompression Bomb Protection
- **Location**: `AppleCompressionAlgorithm.decompress()`
- **Impact**: Malicious files could cause DoS via excessive memory allocation
- **Reference**: CWE-409 (Improper Handling of Highly Compressed Data)

### Example Attack Scenario

```
Compressed file: 1 MB
Decompressed size: 1 TB (1:1,000,000 ratio)

Without protection:
1. User runs: swiftcompress x bomb.lzfse
2. Decompression starts
3. System memory fills
4. Disk space exhausted
5. System becomes unresponsive
```

---

## Decision

Implement **multi-layered decompression bomb protection** using:

### Layer 1: Compression Ratio Monitoring

Monitor real-time compression ratios during streaming decompression:

```swift
ratio = decompressed_bytes / compressed_bytes
```

**Thresholds**:
- **Safe**: ratio ≤ 50:1 (normal compression)
- **Suspicious**: 50:1 < ratio ≤ 100:1 (log warning, continue)
- **Dangerous**: ratio > 100:1 (abort operation)

### Layer 2: Absolute Size Limits

Enforce maximum decompressed size regardless of ratio:

```swift
maxDecompressedSize = 10 GB (configurable)
```

If `decompressed_bytes > maxDecompressedSize`, abort operation.

### Layer 3: Progressive Detection

Check on every streaming chunk (64 KB intervals):
- Calculate current ratio
- Check absolute size
- Take action based on result

### Layer 4: Configuration

Make thresholds configurable for different use cases:

```swift
struct DecompressionBombDetectorConfig {
    let maxCompressionRatio: Double = 100.0
    let maxDecompressedSize: Int64 = 10_737_418_240  // 10 GB
    let warningRatio: Double = 50.0
}
```

---

## Alternatives Considered

### Alternative 1: Pre-Decompression Size Estimation

**Approach**: Analyze compressed file header to estimate decompressed size before starting.

**Pros**:
- Prevents any decompression of bombs
- Fails fast
- No wasted resources

**Cons**:
- Unreliable: Most compression formats don't include decompressed size
- LZFSE, LZ4, ZLIB don't have reliable size headers
- Can be spoofed in malicious files
- Doesn't work for streaming

**Decision**: Rejected - Cannot reliably estimate size for supported algorithms.

---

### Alternative 2: Memory-Based Detection Only

**Approach**: Monitor memory usage and abort if it exceeds limits.

**Pros**:
- Directly protects memory
- Platform-independent

**Cons**:
- Doesn't protect against disk exhaustion
- Memory limits vary by system
- Difficult to attribute memory to specific operation
- Streaming already limits memory usage

**Decision**: Rejected - Incomplete protection, doesn't address disk exhaustion.

---

### Alternative 3: Static Analysis of Compressed Data

**Approach**: Analyze compressed data structure to detect anomalies before decompression.

**Pros**:
- Could detect bombs without decompression
- No performance impact during decompression

**Cons**:
- Algorithm-specific, complex implementation
- Requires deep knowledge of each compression format
- Unreliable, can miss sophisticated bombs
- Can't detect all bomb types

**Decision**: Rejected - Too complex, low reliability, high maintenance burden.

---

### Alternative 4: Timeout-Based Detection

**Approach**: Abort decompression if it takes too long.

**Pros**:
- Simple to implement
- Prevents indefinite resource consumption

**Cons**:
- Doesn't prevent resource exhaustion during timeout period
- Legitimate large files may be rejected
- Timeout duration difficult to tune
- Doesn't address root cause

**Decision**: Rejected - Treats symptoms, not cause. May be added as supplementary measure in future.

---

### Alternative 5: Sandbox/Container-Based Isolation

**Approach**: Decompress in isolated environment with resource limits.

**Pros**:
- Complete isolation
- System-level protection

**Cons**:
- Requires containerization/sandboxing infrastructure
- Complex setup for CLI tool
- Performance overhead
- macOS sandboxing limitations
- Out of scope for CLI tool

**Decision**: Rejected - Overkill for CLI tool, better suited for server applications.

---

## Rationale

The chosen multi-layered approach provides:

1. **Real-Time Protection**
   - Detects bombs **during** decompression
   - Works with streaming architecture
   - No pre-analysis required

2. **Comprehensive Coverage**
   - Protects against memory exhaustion (ratio monitoring)
   - Protects against disk exhaustion (absolute size limit)
   - Handles both fast and slow bombs

3. **Minimal False Positives**
   - Three-tier system (safe/suspicious/dangerous)
   - Warning level for legitimate high-compression
   - Configurable thresholds for specialized use cases

4. **Performance Efficient**
   - Arithmetic only (division per chunk)
   - No additional I/O
   - Overhead: ~1-2%

5. **Clean Architecture Compliance**
   - Protocol in Domain layer (`DecompressionBombDetector`)
   - Implementation in Infrastructure layer
   - Dependency injection for testability
   - Zero coupling to outer layers

6. **Testability**
   - Unit tests with mock data
   - Integration tests with real bombs
   - Predictable, deterministic behavior

7. **User Experience**
   - Clear error messages
   - Operation aborted cleanly
   - Partial output cleaned up

---

## Implementation Design

### Domain Layer

```swift
/// Domain Layer Protocol
protocol DecompressionBombDetector {
    func checkForBomb(
        compressedSize: Int64,
        decompressedSoFar: Int64,
        estimatedTotal: Int64?
    ) -> BombDetectionResult
}

enum BombDetectionResult: Equatable {
    case safe
    case suspicious(reason: String, ratio: Double)
    case dangerous(reason: String, ratio: Double)
}
```

### Infrastructure Layer

```swift
/// Infrastructure Implementation
final class DefaultDecompressionBombDetector: DecompressionBombDetector, SecurityPolicy {
    let name = "decompression-bomb-detector"

    private let maxCompressionRatio: Double
    private let maxDecompressedSize: Int64
    private let warningRatio: Double

    init(
        maxCompressionRatio: Double = 100.0,
        maxDecompressedSize: Int64 = 10_737_418_240,  // 10 GB
        warningRatio: Double = 50.0
    ) {
        self.maxCompressionRatio = maxCompressionRatio
        self.maxDecompressedSize = maxDecompressedSize
        self.warningRatio = warningRatio
    }

    func checkForBomb(
        compressedSize: Int64,
        decompressedSoFar: Int64,
        estimatedTotal: Int64?
    ) -> BombDetectionResult {
        // Guard against division by zero
        guard compressedSize > 0 else {
            return .safe
        }

        let ratio = Double(decompressedSoFar) / Double(compressedSize)

        // Check 1: Absolute size limit
        if decompressedSoFar > maxDecompressedSize {
            return .dangerous(
                reason: "Decompressed size (\(decompressedSoFar.formattedBytes)) exceeds maximum limit (\(maxDecompressedSize.formattedBytes))",
                ratio: ratio
            )
        }

        // Check 2: Compression ratio limits
        if ratio > maxCompressionRatio {
            return .dangerous(
                reason: "Compression ratio (\(String(format: "%.1f", ratio)):1) exceeds safe threshold (\(String(format: "%.1f", maxCompressionRatio)):1)",
                ratio: ratio
            )
        }

        if ratio > warningRatio {
            return .suspicious(
                reason: "Compression ratio (\(String(format: "%.1f", ratio)):1) is unusually high",
                ratio: ratio
            )
        }

        return .safe
    }
}
```

### Integration in Streaming

```swift
/// Enhanced AppleCompressionAlgorithm
extension AppleCompressionAlgorithm {
    func decompressStream(
        input: InputStream,
        output: OutputStream,
        bufferSize: Int,
        bombDetector: DecompressionBombDetector? = nil,
        securityLogger: SecurityLoggerProtocol? = nil
    ) throws {
        // ... setup code ...

        var totalCompressed: Int64 = 0
        var totalDecompressed: Int64 = 0

        while input.hasBytesAvailable {
            let bytesRead = input.read(inputBuffer, maxLength: bufferSize)
            guard bytesRead > 0 else { break }

            totalCompressed += Int64(bytesRead)

            // ... compression stream processing ...

            totalDecompressed += Int64(decompressedBytes)

            // SECURITY: Check for decompression bomb
            if let detector = bombDetector {
                let result = detector.checkForBomb(
                    compressedSize: totalCompressed,
                    decompressedSoFar: totalDecompressed,
                    estimatedTotal: nil
                )

                switch result {
                case .dangerous(let reason, let ratio):
                    securityLogger?.log(
                        event: .decompressionBombDetected(ratio: ratio, size: totalDecompressed),
                        context: [
                            "algorithm": name,
                            "compressed_bytes": totalCompressed,
                            "decompressed_bytes": totalDecompressed
                        ]
                    )
                    throw DomainError.decompressionBombDetected(
                        reason: reason,
                        compressionRatio: ratio
                    )

                case .suspicious(let reason, let ratio):
                    securityLogger?.log(
                        event: .suspiciousCompressionRatio(ratio: ratio),
                        context: [
                            "algorithm": name,
                            "compressed_bytes": totalCompressed,
                            "decompressed_bytes": totalDecompressed,
                            "reason": reason
                        ]
                    )
                    // Continue but log warning

                case .safe:
                    break
                }
            }

            // Write decompressed data
            if decompressedBytes > 0 {
                output.write(outputBuffer, maxLength: decompressedBytes)
            }
        }
    }
}
```

---

## Consequences

### Positive

1. **Security**
   - Prevents memory exhaustion attacks
   - Prevents disk exhaustion attacks
   - Detects bombs in real-time
   - Graceful failure with cleanup

2. **Performance**
   - Minimal overhead (~1-2%)
   - Arithmetic only, no additional I/O
   - Compatible with streaming architecture
   - Constant memory usage maintained

3. **Usability**
   - Clear error messages
   - Explains why operation was aborted
   - Provides compression ratio in error
   - No impact on normal operations

4. **Architecture**
   - Clean separation of concerns
   - Protocol-based, dependency-injected
   - Fully testable
   - Maintains streaming design

5. **Compliance**
   - Addresses CWE-409
   - OWASP A04:2021 compliance
   - Industry best practice

### Negative

1. **False Positives**
   - May reject legitimate highly-compressible data
   - Example: Large files of repeated zeros (rare but valid)
   - **Mitigation**: Configurable thresholds, warning tier

2. **Configuration Complexity**
   - Users with specialized needs must adjust thresholds
   - Requires documentation
   - **Mitigation**: Sensible defaults, clear docs, future CLI flags

3. **Testing Complexity**
   - Need to generate real decompression bombs for testing
   - Boundary condition testing required
   - **Mitigation**: Comprehensive test suite included

### Neutral

1. **Documentation Required**
   - Users need to understand compression ratios
   - Configuration options need explanation
   - Error messages should guide users

2. **Monitoring Needed**
   - Log suspicious events for analysis
   - May need threshold tuning based on usage
   - Future: telemetry for threshold optimization

---

## Implementation Effort

### Development (2 days)

- Day 1: Protocol and implementation
  - Define `DecompressionBombDetector` protocol
  - Implement `DefaultDecompressionBombDetector`
  - Add configuration struct
  - Add to `SecurityPolicy` composition

- Day 2: Integration
  - Enhance `AppleCompressionAlgorithm.decompressStream()`
  - Add bomb detection in streaming loop
  - Wire through dependency injection
  - Add cleanup on bomb detection

### Testing (2 days)

- Day 1: Unit tests
  - Test detector with various ratios
  - Test absolute size limits
  - Test threshold boundaries
  - Test edge cases (zero sizes, etc.)

- Day 2: Integration and E2E tests
  - Create real decompression bombs
  - Test with legitimate high-compression data
  - Test cleanup on detection
  - Test CLI error output

### Documentation (1 day)

- Security documentation
- Configuration guide
- Error message reference
- Troubleshooting guide

**Total Effort**: 5 days (1 developer week)

---

## Compliance Mapping

### CWE Coverage

**CWE-409: Improper Handling of Highly Compressed Data (Decompression of File)**
- **Mitigation**: Real-time ratio monitoring, absolute size limits
- **Status**: ✅ Fully addressed

**CWE-400: Uncontrolled Resource Consumption**
- **Mitigation**: Enforced limits, graceful abort
- **Status**: ✅ Fully addressed

### OWASP Top 10 Coverage

**A04:2021 - Insecure Design**
- **Mitigation**: Security designed into decompression workflow
- **Status**: ✅ Addressed

**A05:2021 - Security Misconfiguration**
- **Mitigation**: Secure defaults, configurable for specialized needs
- **Status**: ✅ Addressed

---

## Configuration Reference

### Default Configuration

```swift
let detector = DefaultDecompressionBombDetector()
// maxCompressionRatio: 100.0 (100:1)
// maxDecompressedSize: 10 GB
// warningRatio: 50.0 (50:1)
```

### Conservative Configuration

```swift
let detector = DefaultDecompressionBombDetector(
    maxCompressionRatio: 50.0,
    maxDecompressedSize: 5_368_709_120,  // 5 GB
    warningRatio: 25.0
)
```

### Permissive Configuration

```swift
let detector = DefaultDecompressionBombDetector(
    maxCompressionRatio: 200.0,
    maxDecompressedSize: 53_687_091_200,  // 50 GB
    warningRatio: 100.0
)
```

### Disable Detection (Not Recommended)

```swift
// Pass nil to decompressStream
try algorithm.decompressStream(
    input: input,
    output: output,
    bufferSize: bufferSize,
    bombDetector: nil  // No bomb detection
)
```

---

## Rollout Strategy

### Phase 1: Opt-In (Week 1)

- Bomb detector available but not enabled by default
- Users can enable via build flag
- Gather feedback on thresholds

### Phase 2: Opt-Out (Week 2)

- Enabled by default
- Users can disable via build flag
- Monitor for false positives

### Phase 3: Always-On (Week 3+)

- Always enabled, no opt-out
- Production standard
- Configurable thresholds only

---

## Testing Strategy

### Unit Tests (20 tests)

```swift
func testNormalRatio_ReturnsSafe()
func testSuspiciousRatio_ReturnsSuspicious()
func testDangerousRatio_ReturnsDangerous()
func testAbsoluteSizeLimit_ReturnsDangerous()
func testZeroCompressedSize_ReturnsSafe()
func testProgressiveExpansion_TracksCorrectly()
func testBoundaryConditions_HandledCorrectly()
```

### Integration Tests (5 tests)

```swift
func testRealBomb_DetectedAndAborted()
func testLegitimateHighCompression_Succeeds()
func testPartialOutputCleanedUp_OnDetection()
func testErrorMessage_IsUserFriendly()
func testSecurityEvent_IsLogged()
```

### E2E Tests (3 tests)

```swift
func testCLI_RejectsBomb_WithClearError()
func testCLI_AcceptsLegitimateFile()
func testCLI_LogsSecurityEvent()
```

---

## Future Enhancements

### Dynamic Threshold Adjustment

Based on file characteristics:
- Text files: Lower thresholds (less compressible)
- Binary files: Higher thresholds (more compressible)
- Algorithm-specific: LZMA allows higher ratios than LZ4

### Telemetry

Collect anonymous statistics:
- Actual compression ratios in the wild
- False positive rate
- Optimal threshold values

### User Feedback

On suspicious detection:
```
Warning: Unusually high compression ratio detected (75:1).
This file may be legitimate but appears suspicious.
Continue? [y/N]
```

---

## Related Documents

- **SECURITY_ASSESSMENT.md**: Security finding that motivated this ADR
- **SECURITY_ARCHITECTURE_PLAN.md**: Complete security enhancement plan
- **ADR-011**: Security Logging and Audit Trail Approach
- **ADR-012**: File Size Limits and Resource Protection

---

## Approval

**Proposed**: 2025-10-12
**Review Period**: 1 week
**Expected Acceptance**: 2025-10-19

---

**END OF ADR-010**
