# Security Policy

**swiftcompress** is a macOS CLI tool for file compression using Apple's Compression framework. This document outlines our security approach, implemented features, vulnerability assessment, and how to report security issues.

**Current Version**: 1.2.0 (Production Ready)
**Security Status**: GOOD
**Last Security Assessment**: 2025-10-12

---

## Table of Contents

1. [Security Overview](#security-overview)
2. [Threat Model](#threat-model)
3. [Security Features](#security-features)
4. [Security Architecture](#security-architecture)
5. [Security Assessment](#security-assessment)
6. [Planned Security Enhancements](#planned-security-enhancements)
7. [Reporting Security Issues](#reporting-security-issues)
8. [Security-Related ADRs](#security-related-adrs)

---

## Security Overview

### Overall Security Posture: **GOOD**

swiftcompress demonstrates security-conscious development with proper input validation, safe memory management, and Clean Architecture providing clear security boundaries. The application is suitable for production use with its current security profile.

### Key Security Strengths

- **Robust Input Validation**: Path sanitization and null byte protection
- **Safe Memory Management**: Swift's type safety with stream-based processing (~9.6 MB peak memory for 100 MB files)
- **Clean Architecture**: Clear security boundaries between layers
- **Minimal Dependencies**: Only ArgumentParser from Apple
- **No Command Injection**: No external process execution
- **Constant Memory Footprint**: Stream-based processing prevents memory exhaustion
- **Appropriate Error Handling**: Sanitized error messages without information leakage

### Security Principles

1. **Defense in Depth**: Multiple complementary security layers
2. **Fail Securely**: Operations abort safely on validation failures
3. **Least Privilege**: Respects system file permissions
4. **Input Validation**: All user inputs validated before processing
5. **Memory Safety**: Leverages Swift's type system and stream processing

---

## Threat Model

### Assets Protected

- **User Files**: Input files being compressed/decompressed
- **Output Files**: Generated compressed/decompressed files
- **System Resources**: Memory, disk space, CPU
- **File System**: Protection against unauthorized access

### Threat Actors

1. **Malicious File Provider**: Provides crafted files to exploit vulnerabilities
2. **Local Attacker**: Has access to file system, attempts privilege escalation
3. **Accidental Misuse**: Legitimate user with malformed inputs

### Attack Vectors

| Attack Vector | Risk Level | Mitigation Status |
|---------------|------------|-------------------|
| Path Traversal | MEDIUM | ✅ Basic protection (enhancement planned) |
| Symbolic Link Attacks | MEDIUM | ⚠️ Not implemented (planned) |
| Decompression Bombs | HIGH | ⚠️ Not implemented (planned) |
| Resource Exhaustion | LOW | ✅ Stream-based processing |
| File Size Abuse | MEDIUM | ⚠️ No limits (planned) |
| Command Injection | N/A | ✅ No external commands |

### Out of Scope

- **Network-based attacks**: No network operations
- **Authentication/Authorization**: No user authentication
- **Cryptographic attacks**: No encryption features
- **Multi-user isolation**: Single-user CLI tool

---

## Security Features

### Input Validation (Implemented)

**Path Validation**:
- Empty path rejection
- Null byte injection prevention
- Basic path traversal detection (`../` patterns)
- Path normalization using `NSString.standardizingPath`

**Algorithm Validation**:
- Whitelist of supported algorithms (LZFSE, LZ4, ZLIB, LZMA)
- Registry-based algorithm lookup prevents arbitrary algorithm execution

### Memory Safety (Implemented)

**Stream-Based Processing**:
- Fixed 64 KB buffer size
- Constant memory usage regardless of file size
- Validated peak memory: ~9.6 MB for 100 MB file compression

**Safe Unsafe Operations**:
- Limited use of unsafe Swift operations
- Proper nil checks before `assumingMemoryBound`
- RAII-style resource management with `defer` blocks

### File Operations (Implemented)

**Permission Checks**:
- Verifies file readability before compression
- Verifies directory writability before output
- Respects system file permissions

**Overwrite Protection**:
- Requires explicit `-f` flag to overwrite existing files
- Prevents accidental data loss

### Error Handling (Implemented)

**Information Disclosure Prevention**:
- Sanitized error messages for users
- Stack traces only in DEBUG builds
- No sensitive system information in errors

**Graceful Failure**:
- Clean resource cleanup on errors
- No partial output files on failure
- Clear exit codes (0 = success, 1 = failure)

---

## Security Architecture

### Four-Layer Architecture

```
┌─────────────────────────────────────┐
│     CLI Interface Layer              │  ← User input validation
├─────────────────────────────────────┤
│     Application Layer                │  ← Workflow orchestration
├─────────────────────────────────────┤
│     Domain Layer                     │  ← Business logic + validation
├─────────────────────────────────────┤
│     Infrastructure Layer             │  ← System integration (I/O)
└─────────────────────────────────────┘
```

### Security Boundaries

**Domain Layer** (Zero outward dependencies):
- `ValidationRules`: Input validation, path sanitization
- `AlgorithmRegistry`: Algorithm whitelist enforcement
- `DomainError`: Security-related error types

**Infrastructure Layer** (System integration):
- `FileSystemHandler`: File operations with permission checks
- `AppleCompressionAlgorithm`: Safe wrapper around C API
- `StreamProcessor`: Memory-safe streaming operations

**Dependency Rule**: All dependencies point inward. Domain layer has no knowledge of outer layers, ensuring security rules cannot be bypassed.

---

## Security Assessment

### Assessment Overview

**Date**: 2025-10-12
**Methodology**: Static code analysis and architectural review
**Files Analyzed**: 38 source files, 18 test files

### Findings Summary

| Severity | Count | Status |
|----------|-------|--------|
| Critical | 0 | - |
| High | 1 | Planned mitigation |
| Medium | 3 | Planned mitigation |
| Low | 4 | Accepted/Planned |

### Detailed Findings

#### HIGH: Missing Decompression Bomb Protection

**Location**: `AppleCompressionAlgorithm.swift:74-101`

**Issue**: In-memory decompression allocates `inputSize * 4` bytes without checking absolute limits, potentially allowing decompression bombs (small compressed files that expand to enormous sizes).

**Impact**: Memory exhaustion, denial of service

**Mitigation Plan**: Implement multi-layered bomb detection:
- Real-time compression ratio monitoring (100:1 limit)
- Absolute size limits (10 GB output default)
- Progressive detection in streaming loop

**Status**: Planned for v1.3.0 (Priority 1)

#### MEDIUM: Path Traversal Enhancement Needed

**Location**: `ValidationRules.swift:28-31`

**Issue**: Basic string matching for `../` patterns may miss edge cases (URL-encoded, Unicode variations).

**Impact**: Potential unauthorized file access

**Current Protection**:
```swift
let normalizedPath = (path as NSString).standardizingPath
if normalizedPath.contains("../") || normalizedPath.hasPrefix("..") {
    throw DomainError.pathTraversalAttempt(path: path)
}
```

**Mitigation Plan**: Canonical path resolution using `URL.standardizedFileURL`

**Status**: Planned for v1.3.0 (Priority 2)

#### MEDIUM: Missing Symbolic Link Validation

**Location**: `FileSystemHandler.swift`

**Issue**: No explicit symbolic link detection, could lead to unintended file access or overwriting.

**Impact**: Symbolic link attacks, privilege escalation

**Mitigation Plan**: Add symlink detection using `FileManager.attributesOfItem`

**Status**: Planned for v1.3.0 (Priority 1)

#### MEDIUM: No File Size Limits

**Issue**: Unbounded file operations could lead to disk exhaustion.

**Impact**: Denial of service, disk space exhaustion

**Mitigation Plan**: Pre-operation file size validation (5 GB input, 10 GB output defaults)

**Status**: Planned for v1.3.0 (Priority 2)

### Positive Security Findings

✅ **No Command Injection**: No use of system(), exec(), or process execution
✅ **No SQL Injection**: No database operations
✅ **Safe Memory Management**: Proper resource cleanup with `defer` blocks
✅ **Minimal Dependencies**: Only trusted Apple framework (ArgumentParser)
✅ **Type Safety**: Leverages Swift's type system throughout
✅ **Stream Processing**: Constant memory regardless of file size

### Compliance Alignment

**OWASP Top 10 2021**:
- ✅ A01:2021 Broken Access Control - Proper path validation
- ✅ A03:2021 Injection - No injection vulnerabilities
- ✅ A04:2021 Insecure Design - Clean Architecture provides security
- ✅ A05:2021 Security Misconfiguration - Secure defaults
- ✅ A06:2021 Vulnerable Components - Minimal, trusted dependencies
- ⚠️ A08:2021 Data Integrity - No checksum verification (planned)
- ⚠️ A09:2021 Security Logging - No security event logging (planned)

**CWE Top 25**:
- ⚠️ CWE-22 Path Traversal - Basic protection, enhancement planned
- ⚠️ CWE-59 Link Following - No symlink protection (planned)
- ⚠️ CWE-409 Resource Exhaustion - No decompression bomb protection (planned)
- ✅ CWE-367 TOCTOU - Stream-based processing minimizes risk
- ✅ CWE-732 Incorrect Permissions - Follows system permissions

---

## Planned Security Enhancements

### Version 1.3.0 Security Roadmap

Comprehensive security enhancements planned for v1.3.0 release. Full details in:
- `Documentation/SECURITY_ARCHITECTURE_PLAN.md`
- Security-related ADRs (ADR-010, ADR-011, ADR-012)

#### Priority 1: Critical (Week 1)

**1. Decompression Bomb Protection**
- Multi-layered detection (ratio monitoring + absolute size limits)
- Real-time compression ratio tracking during decompression
- Three-tier system: safe (< 50:1), suspicious (50:1-100:1), dangerous (> 100:1)
- Default limits: 100:1 ratio, 10 GB absolute size
- See: [ADR-010: Decompression Bomb Protection Strategy](Documentation/ADRs/ADR-010-decompression-bomb-protection.md)

**2. Symbolic Link Validation**
- Pre-operation symlink detection
- Parent directory symlink checking
- Reject operations on symbolic links
- Clear error messages for security rejections

#### Priority 2: High (Week 2)

**3. Enhanced Path Traversal Validation**
- Canonical path resolution using `URL.standardizedFileURL`
- Detection of URL-encoded traversal attempts
- Unicode path normalization

**4. Security Event Logging**
- Type-safe security event system
- Structured log format: `[timestamp] [SECURITY] [severity] description`
- Configurable destinations (stderr, file, none)
- DEBUG-mode only by default
- See: [ADR-011: Security Logging and Audit Trail](Documentation/ADRs/ADR-011-security-logging-and-audit-trail.md)

**5. File Size Limits**
- Pre-operation file size validation
- Default limits: 5 GB input, 10 GB output
- Configurable for different use cases
- Fail-fast before expensive operations
- See: [ADR-012: File Size Limits and Resource Protection](Documentation/ADRs/ADR-012-file-size-limits-and-resource-protection.md)

#### Priority 3: Medium (Week 3)

**6. Integrity Verification** (Optional)
- SHA-256 checksum generation
- `.sha256` sidecar files
- Verification before decompression

**7. Security Test Suite**
- 150 new security-focused tests
- Attack simulation tests
- Boundary condition tests
- Known attack pattern tests

#### Priority 4: Low (Week 4)

**8. CI/CD Security Scanning**
- Automated dependency vulnerability checking
- SAST integration
- Security test automation

**9. Security Documentation**
- Security best practices guide
- Configuration reference
- Threat model documentation

### Implementation Principles

All security enhancements follow these principles:

1. **Zero Breaking Changes**: All enhancements are additive and backward-compatible
2. **Clean Architecture Compliance**: Security policies in Domain layer, implementations in Infrastructure layer
3. **Defense in Depth**: Multiple complementary security layers
4. **Fail Securely**: Operations abort safely on security violations
5. **Performance Conscious**: Target < 5% overhead

### Timeline

- **Week 1**: Priority 1 features (decompression bomb, symlink validation)
- **Week 2**: Priority 2 features (enhanced validation, logging, size limits)
- **Week 3**: Priority 3 features (integrity verification, security tests)
- **Week 4**: Priority 4 features (CI/CD scanning, documentation)

**Expected Release**: v1.3.0 with security posture elevated from **GOOD** to **EXCELLENT**

---

## Reporting Security Issues

### How to Report a Vulnerability

We take security seriously. If you discover a security vulnerability in swiftcompress, please follow responsible disclosure:

**DO NOT** open a public GitHub issue for security vulnerabilities.

**Instead:**

1. **Email**: Send details to the project maintainer (see repository for contact)
2. **Include**:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Affected versions
   - Any proof-of-concept code (if applicable)

### What to Expect

- **Acknowledgment**: Within 48 hours
- **Assessment**: Within 7 days
- **Fix Timeline**: Based on severity
  - Critical: 7-14 days
  - High: 14-30 days
  - Medium: 30-60 days
  - Low: 60-90 days
- **Disclosure**: Coordinated disclosure after fix is released

### Security Advisory Process

1. **Receive Report**: Security issue reported via email
2. **Validate**: Confirm vulnerability and assess severity
3. **Develop Fix**: Implement fix following Clean Architecture principles
4. **Test**: Comprehensive testing including regression tests
5. **Release**: Patch version with security fix
6. **Disclose**: Publish security advisory with CVE (if applicable)

### Hall of Fame

We recognize security researchers who responsibly disclose vulnerabilities:

- (No vulnerabilities reported yet)

---

## Security-Related ADRs

### Implemented Security ADRs

- **[ADR-001: Clean Architecture](Documentation/ADRs/ADR-001-clean-architecture.md)** - Layer separation provides security boundaries
- **[ADR-003: Stream-Based Processing](Documentation/ADRs/ADR-003-stream-processing.md)** - Constant memory usage prevents exhaustion
- **[ADR-004: Dependency Injection](Documentation/ADRs/ADR-004-dependency-injection.md)** - Testable, pluggable security components

### Planned Security ADRs (v1.3.0)

- **[ADR-010: Decompression Bomb Protection Strategy](Documentation/ADRs/ADR-010-decompression-bomb-protection.md)** - Multi-layered bomb detection
- **[ADR-011: Security Logging and Audit Trail Approach](Documentation/ADRs/ADR-011-security-logging-and-audit-trail.md)** - Structured security event logging
- **[ADR-012: File Size Limits and Resource Protection](Documentation/ADRs/ADR-012-file-size-limits-and-resource-protection.md)** - Configurable resource limits

---

## Security Configuration

### Current Version (v1.2.0)

No user-configurable security settings. All security features use secure defaults.

### Planned Version (v1.3.0)

**Default Security Configuration**:
```swift
// Decompression Bomb Protection
maxCompressionRatio: 100.0      // 100:1 ratio limit
maxDecompressedSize: 10 GB      // Absolute size limit
warningRatio: 50.0              // Warning threshold

// File Size Limits
maxInputFileSize: 5 GB          // Input file limit
maxOutputFileSize: 10 GB        // Output file limit

// Security Logging
logDestination: .stderr         // Log to stderr
debugOnly: true                 // DEBUG builds only
```

**Environment Variables** (planned):
```bash
# Security features
export SWIFTCOMPRESS_SECURITY_ENABLED=1
export SWIFTCOMPRESS_VALIDATE_SYMLINKS=1

# Thresholds
export SWIFTCOMPRESS_MAX_COMPRESSION_RATIO=100
export SWIFTCOMPRESS_MAX_INPUT_SIZE=5368709120  # 5 GB
export SWIFTCOMPRESS_MAX_OUTPUT_SIZE=10737418240  # 10 GB

# Logging
export SWIFTCOMPRESS_SECURITY_LOG=/var/log/swiftcompress/security.log
export SWIFTCOMPRESS_LOG_LEVEL=INFO
```

---

## Security Best Practices for Users

### Recommended Usage

1. **Verify File Sources**: Only compress/decompress files from trusted sources
2. **Check File Sizes**: Be cautious with unusually small compressed files
3. **Use Latest Version**: Always use the latest stable release
4. **Monitor Logs**: Check for security warnings (v1.3.0+)
5. **Review Permissions**: Ensure proper file permissions before operations

### Avoiding Common Issues

**Path Traversal**:
- ❌ DON'T: `swiftcompress c ../../../etc/passwd -m lzfse`
- ✅ DO: Use absolute paths or paths within working directory

**Overwrite Protection**:
- ❌ DON'T: Assume overwrite is safe
- ✅ DO: Use `-f` flag consciously

**Large Files**:
- ❌ DON'T: Compress system-critical files
- ✅ DO: Test with small files first

**Output Verification**:
- ❌ DON'T: Assume successful compression means valid output
- ✅ DO: Verify round-trip decompression (v1.3.0+ will add checksums)

---

## Security Resources

### Internal Documentation

- **[SECURITY_ARCHITECTURE_PLAN.md](Documentation/SECURITY_ARCHITECTURE_PLAN.md)** - Complete v1.3.0 security enhancement plan (147 pages)
- **[SECURITY_ASSESSMENT.md](SECURITY_ASSESSMENT.md)** - Detailed security assessment report (382 lines)
- **[ARCHITECTURE.md](Documentation/ARCHITECTURE.md)** - Overall architecture with security considerations

### External Standards

- **OWASP Top 10 2021**: https://owasp.org/Top10/
- **CWE Top 25**: https://cwe.mitre.org/top25/
- **Swift Security Guide**: https://www.swift.org/documentation/security/

### Related Technologies

- **Apple Compression Framework**: https://developer.apple.com/documentation/compression
- **Swift Package Manager**: https://swift.org/package-manager/

---

## Version History

| Version | Date | Security Status | Key Changes |
|---------|------|----------------|-------------|
| 1.2.0 | 2025-10-10 | GOOD | Production release with basic security |
| 1.3.0 | Planned | EXCELLENT | Comprehensive security enhancements |

---

## Contact

For security-related questions or concerns:

- **Security Issues**: Use responsible disclosure process (see above)
- **General Questions**: Open a GitHub issue (non-security topics only)
- **Documentation**: Refer to `Documentation/` directory

---

**Last Updated**: 2025-10-23
**Document Version**: 1.0
**Maintainer**: swiftcompress project team

---

*This security policy is a living document and will be updated as the project evolves.*
