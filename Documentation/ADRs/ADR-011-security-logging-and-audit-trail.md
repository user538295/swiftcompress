# ADR-011: Security Logging and Audit Trail Approach

**Status**: Proposed
**Date**: 2025-10-12
**Deciders**: Security Architecture Team
**Related**: SECURITY_ASSESSMENT.md, SECURITY_ARCHITECTURE_PLAN.md, ADR-010

---

## Context

Security events (path traversal attempts, symbolic link access, decompression bomb detection, etc.) need to be captured for:

1. **Incident Response**: Investigate security incidents after they occur
2. **Threat Detection**: Identify attack patterns and malicious behavior
3. **Compliance**: Meet audit and regulatory requirements
4. **Monitoring**: Track security posture over time
5. **Debugging**: Troubleshoot security feature behavior

### Current State

Swiftcompress currently has no security-specific logging:
- Errors are reported to users via stderr
- No audit trail of security events
- No distinction between operational and security errors
- No structured logging format

### Security Assessment Finding

**OWASP A09:2021**: Security Logging and Monitoring Failures
- No security logging implemented
- Cannot detect or respond to security incidents
- No audit trail for compliance

**Recommended Improvement (Priority 2)**:
"Implement security event logging for audit trails"

### Requirements

1. **Type Safety**: Security events must be compiler-checked
2. **Structured Format**: Machine-parseable log format
3. **Contextual**: Include relevant context with each event
4. **Configurable**: Enable/disable per environment
5. **Performance**: Negligible overhead when disabled
6. **Clean Architecture**: Security events in Domain, logging in Infrastructure
7. **Privacy**: No sensitive data in logs (PII, credentials)

---

## Decision

Implement **structured security event logging** with:

### 1. Type-Safe Security Events (Domain Layer)

```swift
enum SecurityEvent {
    // Path Security
    case pathTraversalAttempt(path: String)
    case symbolicLinkAccess(path: String)

    // Decompression Security
    case decompressionBombDetected(ratio: Double, size: Int64)
    case suspiciousCompressionRatio(ratio: Double)

    // Resource Security
    case fileSizeLimitExceeded(size: Int64, limit: Int64)

    // Integrity Security
    case integrityCheckFailed(path: String, expected: String, actual: String)

    var severity: EventSeverity { ... }
    var description: String { ... }
}

enum EventSeverity: String {
    case critical  // Immediate action required
    case high      // Investigate soon
    case medium    // Monitor
    case low       // Informational
}
```

### 2. Security Logger (Infrastructure Layer)

```swift
protocol SecurityLoggerProtocol {
    func log(event: SecurityEvent)
    func log(event: SecurityEvent, context: [String: Any])
}

final class SecurityLogger: SecurityLoggerProtocol {
    private let destination: LogDestination
    private let timestampFormatter: DateFormatter

    func log(event: SecurityEvent, context: [String: Any] = [:]) {
        let entry = formatLogEntry(event: event, context: context)
        write(entry: entry)
    }
}

enum LogDestination {
    case stderr         // Standard error output
    case file(path: String)  // File on disk
    case none          // Disabled
}
```

### 3. Structured Log Format

```
[TIMESTAMP] [SECURITY] [SEVERITY] EVENT_DESCRIPTION | context_key=value, ...
```

**Example**:
```
[2025-10-12 14:23:45.123] [SECURITY] [CRITICAL] Path traversal attempt detected: ../../../etc/passwd | operation=compress, user=jdoe, pid=12345
```

### 4. Conditional Compilation

```swift
#if DEBUG
    // Security logging always on in debug
    let logger = SecurityLogger(destination: .stderr)
#else
    // Security logging off by default in release
    let logger = SecurityLogger(destination: .none)
#endif
```

### 5. Integration Pattern

```swift
// In security validators
func validate(context: SecurityContext) throws {
    if violatesPolicy(context) {
        securityLogger.log(
            event: .pathTraversalAttempt(path: context.inputPath),
            context: [
                "operation": context.operation,
                "timestamp": Date(),
                "pid": ProcessInfo.processInfo.processIdentifier
            ]
        )
        throw DomainError.pathTraversalAttempt(path: context.inputPath)
    }
}
```

---

## Alternatives Considered

### Alternative 1: Use Existing Error Logging

**Approach**: Log security events through the existing `ErrorHandler` mechanism.

**Pros**:
- No new infrastructure needed
- Reuses existing logging code
- Simpler implementation

**Cons**:
- Security events mixed with operational errors
- Cannot distinguish security from non-security events
- Harder to generate security-specific reports
- Cannot have separate audit trail
- Difficult to apply security-specific retention policies

**Decision**: Rejected - Security events need separate treatment for compliance and analysis.

---

### Alternative 2: External Logging Library (e.g., SwiftLog)

**Approach**: Use Apple's swift-log or another logging framework.

**Pros**:
- Feature-rich (log levels, backends, formatters)
- Standard interface
- Community support
- Well-tested

**Cons**:
- External dependency (violates project principle)
- Overkill for CLI tool
- Additional learning curve
- Adds complexity to build
- May not fit Clean Architecture layering

**Decision**: Rejected - Violates "minimal dependencies" principle. SwiftCompress currently depends only on Swift standard library and ArgumentParser.

---

### Alternative 3: Always-On Logging

**Approach**: Always log security events, even in production.

**Pros**:
- Complete audit trail always available
- No configuration needed
- Catches all events

**Cons**:
- Verbose output in normal CLI usage
- Poor user experience (clutters terminal)
- May leak information in multi-user systems
- Performance overhead always incurred
- Not appropriate for CLI tool

**Decision**: Rejected - CLI tools should be quiet by default. Always-on logging is more appropriate for servers/daemons.

---

### Alternative 4: Syslog Integration

**Approach**: Log security events to macOS system log (via os_log/Logger).

**Pros**:
- Native macOS integration
- Centralized logging
- System log retention policies
- Can query via `log show`

**Cons**:
- macOS-specific (not portable)
- Requires entitlements
- More complex than needed
- May require root/admin access
- Harder to test

**Decision**: Rejected for MVP - Too platform-specific. Consider for future enhancement.

---

### Alternative 5: JSON Structured Logging

**Approach**: Log events as JSON for machine parsing.

**Pros**:
- Easily parseable by tools
- Structured data
- Good for log aggregation systems

**Cons**:
- Less human-readable
- Larger log files
- Overkill for CLI tool
- Requires JSON encoder

**Decision**: Deferred to Phase 4 - Human-readable format for now, JSON option as future enhancement.

---

## Rationale

The chosen approach provides:

### 1. Type Safety

```swift
// Compiler-checked event types
let event = SecurityEvent.pathTraversalAttempt(path: "/bad/path")
securityLogger.log(event: event)

// Compile error if wrong type:
// securityLogger.log(event: "string") // Error!
```

**Benefit**: Prevents logging errors, enables refactoring safety.

### 2. Clean Separation

**Domain Layer**:
- Defines security event types (`SecurityEvent` enum)
- No knowledge of logging implementation
- Pure, testable

**Infrastructure Layer**:
- Implements logging (`SecurityLogger`)
- Handles I/O, formatting, destinations
- Platform-specific concerns

**Benefit**: Maintains Clean Architecture dependency rules.

### 3. Structured and Consistent

All logs follow same format:
```
[timestamp] [SECURITY] [severity] description | context
```

**Benefit**: Easy to parse, search, aggregate.

### 4. Contextual Information

```swift
securityLogger.log(
    event: .decompressionBombDetected(ratio: 150.0, size: 10GB),
    context: [
        "algorithm": "lzfse",
        "file": "suspicious.lzfse",
        "user": currentUser,
        "pid": processId
    ]
)
```

**Benefit**: Rich information for incident investigation.

### 5. Configurable

```swift
// Development: Log to stderr
let logger = SecurityLogger(destination: .stderr)

// Production: Log to file
let logger = SecurityLogger(destination: .file(path: "/var/log/swiftcompress/security.log"))

// Testing: No logging
let logger = SecurityLogger(destination: .none)
```

**Benefit**: Appropriate for each environment.

### 6. Performance

```swift
enum LogDestination {
    case none  // Early return, zero overhead
    // ...
}

func log(event: SecurityEvent, context: [String: Any]) {
    guard case .none = destination else { return }
    // Rest of logging code
}
```

**Benefit**: When disabled, logging is a single guard check (negligible overhead).

### 7. Testable

```swift
// Unit test
func testPathTraversal_LogsSecurityEvent() {
    let mockLogger = MockSecurityLogger()
    let validator = DefaultSymbolicLinkValidator(logger: mockLogger)

    XCTAssertThrowsError(try validator.validate(symlinkPath))

    XCTAssertEqual(mockLogger.loggedEvents.count, 1)
    guard case .symbolicLinkAccess(let path) = mockLogger.loggedEvents[0] else {
        XCTFail("Wrong event type")
        return
    }
    XCTAssertEqual(path, symlinkPath)
}
```

**Benefit**: All logging behavior is testable.

---

## Implementation Design

### Security Event Enum (Domain Layer)

```swift
/// Domain Layer - Security event types
enum SecurityEvent {
    // MARK: - Path Security Events
    case pathTraversalAttempt(path: String)
    case symbolicLinkAccess(path: String)

    // MARK: - Decompression Security Events
    case decompressionBombDetected(ratio: Double, size: Int64)
    case suspiciousCompressionRatio(ratio: Double)

    // MARK: - Resource Security Events
    case fileSizeLimitExceeded(size: Int64, limit: Int64)

    // MARK: - Integrity Security Events
    case integrityCheckFailed(path: String, expected: String, actual: String)

    /// Event severity level for prioritization
    var severity: EventSeverity {
        switch self {
        case .pathTraversalAttempt, .decompressionBombDetected:
            return .critical
        case .symbolicLinkAccess, .fileSizeLimitExceeded:
            return .high
        case .suspiciousCompressionRatio, .integrityCheckFailed:
            return .medium
        }
    }

    /// Human-readable event description
    var description: String {
        switch self {
        case .pathTraversalAttempt(let path):
            return "Path traversal attempt detected: \(sanitizePath(path))"

        case .symbolicLinkAccess(let path):
            return "Symbolic link access attempt: \(sanitizePath(path))"

        case .decompressionBombDetected(let ratio, let size):
            return "Decompression bomb detected: ratio=\(String(format: "%.1f", ratio)):1, size=\(size.formattedBytes)"

        case .suspiciousCompressionRatio(let ratio):
            return "Suspicious compression ratio detected: \(String(format: "%.1f", ratio)):1"

        case .fileSizeLimitExceeded(let size, let limit):
            return "File size limit exceeded: \(size.formattedBytes) > \(limit.formattedBytes)"

        case .integrityCheckFailed(let path, let expected, let actual):
            return "Integrity check failed for \(sanitizePath(path)): expected=\(expected), actual=\(actual)"
        }
    }

    /// Sanitize path for logging (remove sensitive info)
    private func sanitizePath(_ path: String) -> String {
        // Replace home directory with ~
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(homeDir) {
            return path.replacingOccurrences(of: homeDir, with: "~")
        }
        return path
    }
}

/// Event severity levels
enum EventSeverity: String, CaseIterable {
    case critical = "CRITICAL"
    case high = "HIGH"
    case medium = "MEDIUM"
    case low = "LOW"
}
```

### Security Logger Protocol (Infrastructure Layer)

```swift
/// Infrastructure Layer - Security logging protocol
protocol SecurityLoggerProtocol {
    /// Log a security event without additional context
    func log(event: SecurityEvent)

    /// Log a security event with additional context
    func log(event: SecurityEvent, context: [String: Any])
}
```

### Security Logger Implementation

```swift
/// Infrastructure Layer - Concrete security logger
final class SecurityLogger: SecurityLoggerProtocol {
    private let destination: LogDestination
    private let timestampFormatter: DateFormatter
    private let fileHandle: FileHandle?

    init(destination: LogDestination = .stderr) {
        self.destination = destination
        self.timestampFormatter = DateFormatter()
        self.timestampFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        self.timestampFormatter.timeZone = TimeZone.current

        // Initialize file handle if logging to file
        if case .file(let path) = destination {
            self.fileHandle = Self.createFileHandle(at: path)
        } else {
            self.fileHandle = nil
        }
    }

    deinit {
        fileHandle?.closeFile()
    }

    func log(event: SecurityEvent) {
        log(event: event, context: [:])
    }

    func log(event: SecurityEvent, context: [String: Any]) {
        // Early return if logging disabled
        guard case .none = destination else {
            return
        }

        let logEntry = formatLogEntry(event: event, context: context)
        write(entry: logEntry)
    }

    // MARK: - Private Methods

    private func formatLogEntry(event: SecurityEvent, context: [String: Any]) -> String {
        let timestamp = timestampFormatter.string(from: Date())
        let severity = event.severity.rawValue
        let description = event.description

        var entry = "[\(timestamp)] [SECURITY] [\(severity)] \(description)"

        // Append context if present
        if !context.isEmpty {
            let contextStr = context
                .sorted { $0.key < $1.key }  // Consistent ordering
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: ", ")
            entry += " | \(contextStr)"
        }

        return entry
    }

    private func write(entry: String) {
        switch destination {
        case .stderr:
            // Only write in DEBUG builds to avoid cluttering user's terminal
            #if DEBUG
            fputs("\(entry)\n", stderr)
            fflush(stderr)
            #endif

        case .file:
            guard let handle = fileHandle else { return }
            if let data = "\(entry)\n".data(using: .utf8) {
                handle.seekToEndOfFile()
                handle.write(data)
            }

        case .none:
            // No-op
            break
        }
    }

    private static func createFileHandle(at path: String) -> FileHandle? {
        let fileManager = FileManager.default

        // Create parent directory if needed
        let parentDir = (path as NSString).deletingLastPathComponent
        if !fileManager.fileExists(atPath: parentDir) {
            try? fileManager.createDirectory(
                atPath: parentDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        // Create file if it doesn't exist
        if !fileManager.fileExists(atPath: path) {
            fileManager.createFile(atPath: path, contents: nil, attributes: nil)
        }

        // Open file handle
        return FileHandle(forWritingAtPath: path)
    }
}

/// Log destination options
enum LogDestination: Equatable {
    case stderr               // Log to standard error (DEBUG only)
    case file(path: String)   // Log to file
    case none                 // Logging disabled
}
```

### Integration Example

```swift
/// Example: Integration in SymbolicLinkValidator
final class DefaultSymbolicLinkValidator: SymbolicLinkValidator, SecurityPolicy {
    let name = "symbolic-link-validator"
    private let fileManager: FileManager
    private let securityLogger: SecurityLoggerProtocol

    init(
        fileManager: FileManager = .default,
        securityLogger: SecurityLoggerProtocol
    ) {
        self.fileManager = fileManager
        self.securityLogger = securityLogger
    }

    func validateNotSymbolicLink(at path: String) throws {
        guard fileManager.fileExists(atPath: path) else {
            return  // File doesn't exist, will be caught by other validator
        }

        let attributes = try fileManager.attributesOfItem(atPath: path)

        if let fileType = attributes[.type] as? FileAttributeType,
           fileType == .typeSymbolicLink {
            // SECURITY: Log symbolic link access attempt
            securityLogger.log(
                event: .symbolicLinkAccess(path: path),
                context: [
                    "operation": "validateNotSymbolicLink",
                    "timestamp": Date().timeIntervalSince1970,
                    "pid": ProcessInfo.processInfo.processIdentifier
                ]
            )

            throw DomainError.symbolicLinkNotAllowed(path: path)
        }
    }
}
```

---

## Consequences

### Positive

1. **Security Visibility**
   - All security events captured
   - Complete audit trail
   - Enable incident response

2. **Type Safety**
   - Compiler-checked event types
   - Refactoring-safe
   - No typos in event names

3. **Structured Data**
   - Consistent log format
   - Easy to parse and analyze
   - Supports log aggregation

4. **Clean Architecture**
   - Events in Domain layer (no dependencies)
   - Logging in Infrastructure layer
   - Dependency direction correct

5. **Performance**
   - Negligible overhead when disabled
   - Single guard check in hot path
   - No string formatting unless logging active

6. **Testability**
   - Mock logger for unit tests
   - Verify events logged correctly
   - Assert on log content

7. **Privacy**
   - Path sanitization (~ for home dir)
   - No credentials logged
   - No PII in standard events

8. **Compliance**
   - Addresses OWASP A09:2021
   - Provides audit trail
   - Supports security reviews

### Negative

1. **Logging Overhead**
   - Small overhead even when logging to file
   - I/O operations on each log
   - **Mitigation**: Asynchronous logging in future, buffering

2. **Log Management**
   - Logs can grow large over time
   - Need rotation strategy
   - **Mitigation**: Document log rotation, consider logrotate integration (future)

3. **Verbosity**
   - Many security events may clutter logs
   - Needs filtering for analysis
   - **Mitigation**: Severity levels, future filtering options

4. **Conditional Compilation**
   - DEBUG vs RELEASE behavior differs
   - May miss production issues
   - **Mitigation**: Document how to enable in production, environment variable (future)

### Neutral

1. **Configuration**
   - Default is no logging in production
   - Users must opt-in for audit trail
   - Document how to enable

2. **Log Format**
   - Human-readable but not JSON
   - Trade-off: readability vs machine-parseability
   - Future: Add JSON format option

3. **Testing**
   - Need to test logging in multiple destinations
   - Need to verify log content
   - Standard testing, no special challenges

---

## Implementation Effort

### Development (1.5 days)

**Day 1 (6 hours)**:
- Define `SecurityEvent` enum in Domain layer (1 hour)
- Define `SecurityLoggerProtocol` in Infrastructure (0.5 hour)
- Implement `SecurityLogger` with all destinations (2 hours)
- Implement `LogDestination` enum (0.5 hour)
- Add path sanitization and formatting helpers (1 hour)
- Wire logger through dependency injection (1 hour)

**Day 2 (3 hours)**:
- Integrate logging in all security validators (2 hours)
- Add context information collection (1 hour)

### Testing (1 day)

**Unit Tests (4 hours)**:
- Test event description formatting (1 hour)
- Test severity assignment (0.5 hour)
- Test logger with different destinations (1 hour)
- Test path sanitization (0.5 hour)
- Test context inclusion (0.5 hour)
- Test conditional compilation (0.5 hour)

**Integration Tests (2 hours)**:
- Test logging in real security validators (1 hour)
- Test log file creation and writing (0.5 hour)
- Test stderr output (0.5 hour)

**E2E Tests (2 hours)**:
- Test CLI with security logging enabled (1 hour)
- Verify log content after security violations (1 hour)

### Documentation (0.5 day)

**Documentation (4 hours)**:
- Security logging guide (1 hour)
- Event catalog reference (1 hour)
- Log analysis examples (1 hour)
- Configuration options (1 hour)

**Total Effort**: 3 days

---

## Compliance Mapping

### OWASP Top 10 Coverage

**A09:2021 - Security Logging and Monitoring Failures**
- **Mitigation**: Comprehensive security event logging
- **Status**: ✅ Fully addressed

### CWE Coverage

**CWE-778: Insufficient Logging**
- **Mitigation**: All security events logged with context
- **Status**: ✅ Addressed

**CWE-532: Insertion of Sensitive Information into Log File**
- **Mitigation**: Path sanitization, no credentials logged
- **Status**: ✅ Addressed

---

## Configuration Reference

### Default Configuration (Development)

```swift
#if DEBUG
    let logger = SecurityLogger(destination: .stderr)
#else
    let logger = SecurityLogger(destination: .none)
#endif
```

**Behavior**: Logs to stderr in debug builds, disabled in release builds.

### Production Configuration (File Logging)

```swift
let logPath = "/var/log/swiftcompress/security.log"
let logger = SecurityLogger(destination: .file(path: logPath))
```

**Behavior**: Logs to file, suitable for production audit trail.

### Testing Configuration

```swift
let logger = SecurityLogger(destination: .none)
```

**Behavior**: Logging disabled, no output.

### Future: Environment Variable Configuration

```bash
# Enable security logging to file
export SWIFTCOMPRESS_SECURITY_LOG=/var/log/swiftcompress/security.log

# Enable security logging to stderr
export SWIFTCOMPRESS_SECURITY_LOG=stderr

# Disable security logging
export SWIFTCOMPRESS_SECURITY_LOG=none
```

---

## Log Examples

### Path Traversal Attempt

```
[2025-10-12 14:23:45.123] [SECURITY] [CRITICAL] Path traversal attempt detected: ../../../etc/passwd | operation=compress, pid=12345, timestamp=1697123025.123
```

### Symbolic Link Access

```
[2025-10-12 14:24:10.456] [SECURITY] [HIGH] Symbolic link access attempt: ~/suspicious/link.txt | operation=inputStream, pid=12345, timestamp=1697123050.456
```

### Decompression Bomb Detection

```
[2025-10-12 14:25:30.789] [SECURITY] [CRITICAL] Decompression bomb detected: ratio=150.0:1, size=10.0 GB | algorithm=lzfse, compressed_bytes=71582788, decompressed_bytes=10737418240, file=bomb.lzfse, pid=12345
```

### Suspicious Compression Ratio

```
[2025-10-12 14:26:00.012] [SECURITY] [MEDIUM] Suspicious compression ratio detected: 60.0:1 | algorithm=lzfse, compressed_bytes=1048576, decompressed_bytes=62914560, file=suspicious.lzfse
```

### File Size Limit Exceeded

```
[2025-10-12 14:27:15.345] [SECURITY] [HIGH] File size limit exceeded: 6.0 GB > 5.0 GB | operation=compression, file=huge.txt, pid=12345
```

---

## Testing Strategy

### Unit Tests (10 tests)

```swift
class SecurityLoggerTests: XCTestCase {
    func testLogToStderr_ContainsEventDescription()
    func testLogToFile_WritesEntry()
    func testLogWithContext_IncludesContext()
    func testSeverityLevels_FormattedCorrectly()
    func testPathSanitization_ReplacesHomeDirectory()
    func testDestinationNone_NoOutput()
    func testTimestampFormat_IsCorrect()
    func testEventOrdering_ConsistentContextOrder()
    func testFileCreation_CreatesParentDirectory()
    func testMultipleEvents_AllWritten()
}
```

### Integration Tests (5 tests)

```swift
class SecurityLoggingIntegrationTests: XCTestCase {
    func testValidator_LogsSecurityViolation()
    func testBombDetector_LogsSuspiciousEvent()
    func testMultipleValidators_LogMultipleEvents()
    func testLogFileGrowth_HandlesConcurrentWrites()
    func testErrorDuringLogging_DoesNotAffectOperation()
}
```

### Mock Logger for Testing

```swift
class MockSecurityLogger: SecurityLoggerProtocol {
    private(set) var loggedEvents: [SecurityEvent] = []
    private(set) var loggedContexts: [[String: Any]] = []

    func log(event: SecurityEvent) {
        log(event: event, context: [:])
    }

    func log(event: SecurityEvent, context: [String: Any]) {
        loggedEvents.append(event)
        loggedContexts.append(context)
    }

    func reset() {
        loggedEvents.removeAll()
        loggedContexts.removeAll()
    }
}
```

---

## Future Enhancements

### Phase 2: Advanced Logging Features

1. **Asynchronous Logging**
   - Queue logs for background writing
   - Reduce I/O impact on main thread
   - Buffer logs and flush periodically

2. **Log Rotation**
   - Automatic rotation based on size/time
   - Configurable retention policy
   - Integration with system logrotate

3. **JSON Format Option**
   ```json
   {
     "timestamp": "2025-10-12T14:23:45.123Z",
     "level": "SECURITY",
     "severity": "CRITICAL",
     "event": "pathTraversalAttempt",
     "path": "../../../etc/passwd",
     "context": {
       "operation": "compress",
       "pid": 12345
     }
   }
   ```

4. **Log Aggregation**
   - Send logs to centralized system (e.g., syslog, Splunk)
   - Support for structured logging protocols
   - Cloud logging integration

5. **Event Filtering**
   - Filter by severity level
   - Filter by event type
   - Configurable filters

6. **Rate Limiting**
   - Prevent log flooding
   - Throttle repeated events
   - Protect against log-based DoS

---

## Related Documents

- **SECURITY_ASSESSMENT.md**: OWASP A09:2021 finding
- **SECURITY_ARCHITECTURE_PLAN.md**: Complete security plan
- **ADR-010**: Decompression Bomb Protection Strategy
- **ADR-012**: File Size Limits and Resource Protection

---

## Rollout Strategy

### Phase 1: Opt-In (Week 1)

- Logging available but disabled by default
- Enable via build flag: `-DSECURITY_LOGGING_ENABLED`
- Gather feedback on log format and content

### Phase 2: DEBUG Default (Week 2)

- Enabled by default in DEBUG builds
- Still disabled in release builds
- Monitor for issues

### Phase 3: Production Option (Week 3+)

- Document how to enable in production
- Provide example configurations
- Consider environment variable support

---

## Approval

**Proposed**: 2025-10-12
**Review Period**: 1 week
**Expected Acceptance**: 2025-10-19

---

**END OF ADR-011**
