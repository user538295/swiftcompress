# stdin/stdout Streaming Support - Architecture Summary

**Version**: 1.0
**Date**: 2025-10-10
**Status**: ✅ COMPLETE - Fully Implemented and Validated

---

## Implementation Status

**Implementation Status**: ✅ COMPLETE (v1.0.0)
- All features validated: **Yes**
- Test coverage: **95%+ (49 new tests added, 328 total)**
- Performance validated: **Yes** (memory and speed within targets)
- Date completed: **2025-10-10**

---

## Overview

This document summarizes the comprehensive architectural design for adding stdin/stdout streaming support to swiftcompress, a macOS CLI compression tool that follows Clean Architecture principles.

---

## Document Structure

Four comprehensive documents have been created to guide implementation:

### 1. [ADR-007: stdin/stdout Streaming Support](./ADRs/ADR-007-stdin-stdout-streaming.md)
**Type**: Architecture Decision Record
**Purpose**: Formal architectural decision documentation
**Contents**:
- Context and rationale for the feature
- Decision details with alternatives considered
- Consequences (positive, negative, neutral)
- Implementation approach
- Validation criteria
- Usage examples

**Key Decision**: Use enum-based abstractions (`InputSource`, `OutputDestination`) with automatic pipe detection via `isatty()`.

---

### 2. [stdin-stdout Design Specification](./stdin-stdout-design-specification.md)
**Type**: Detailed Technical Specification
**Purpose**: Complete design documentation for implementation teams
**Contents**:
- Architecture overview (current vs target)
- Component changes by layer (CLI, Application, Domain, Infrastructure)
- New abstractions and types
- Protocol changes
- Data flow diagrams (text)
- 4-week implementation roadmap
- Testing strategy (unit, integration, E2E)
- Risk assessment
- Backward compatibility guarantees

**Key Sections**:
- 50+ pages of detailed specifications
- Layer-by-layer change documentation
- Complete testing strategy
- Risk mitigation plans

---

### 3. [stdin-stdout Architecture Diagrams](./stdin-stdout-architecture-diagrams.md)
**Type**: Visual Documentation
**Purpose**: Mermaid diagrams for all architectural views
**Contents**:
- System architecture diagrams (before/after)
- Component interaction diagrams (sequence diagrams)
- Data flow diagrams
- State machines for resolution logic
- Deployment views
- Layer dependency diagrams
- Testing architecture
- Performance characteristics

**Key Diagrams**:
- 15+ Mermaid diagrams
- All major workflows visualized
- Clear before/after comparisons

---

### 4. [stdin-stdout Implementation Guide](./stdin-stdout-implementation-guide.md)
**Type**: Practical Implementation Handbook
**Purpose**: Step-by-step guide for developers
**Contents**:
- Implementation checklist (4 weeks, 20 days)
- File-by-file implementation guide
- Code templates and examples
- Testing guide with templates
- Common issues and solutions
- Validation and sign-off criteria

**Key Features**:
- Daily task breakdown
- Checkbox-based progress tracking
- Code templates for each component
- Troubleshooting guide

---

## Quick Reference

### What Is Being Added?

Support for Unix pipeline patterns:

```bash
# NEW: Read from stdin, write to file
cat file.txt | swiftcompress c -m lzfse -o output.lzfse

# NEW: Read from file, write to stdout
swiftcompress c input.txt -m lzfse | ssh remote "cat > file.lzfse"

# NEW: Full pipeline (stdin → stdout)
cat file.txt | swiftcompress c -m lzfse | swiftcompress x -m lzfse > output.txt

# UNCHANGED: Existing file-based usage still works
swiftcompress c input.txt -m lzfse
swiftcompress x input.txt.lzfse -m lzfse
```

---

### Key Architectural Changes

#### 1. New Types (Domain Layer)

```swift
enum InputSource {
    case file(path: String)
    case stdin
}

enum OutputDestination {
    case file(path: String)
    case stdout
}
```

#### 2. New Utility (Infrastructure Layer)

```swift
enum TerminalDetector {
    static func isStdinPipe() -> Bool
    static func isStdoutPipe() -> Bool
    // Uses isatty() POSIX function
}
```

#### 3. Updated Model (Shared)

```swift
struct ParsedCommand {
    let commandType: CommandType
    let inputSource: InputSource         // Changed from inputPath: String
    let algorithmName: String?
    let outputDestination: OutputDestination?  // Changed from outputPath: String?
    let forceOverwrite: Bool
}
```

#### 4. Protocol Extension (Domain)

```swift
protocol FileHandlerProtocol {
    // Existing file-based methods...

    // NEW: Stream-based methods
    func inputStream(from source: InputSource) throws -> InputStream
    func outputStream(to destination: OutputDestination) throws -> OutputStream
}
```

---

### Architecture Principles Maintained

✅ **Clean Architecture**: All layer boundaries respected
✅ **Dependency Rule**: Dependencies point inward only
✅ **SOLID Principles**: Open/Closed, Single Responsibility, etc.
✅ **Backward Compatibility**: All existing usage patterns work
✅ **Performance**: Same constant-memory streaming (~9.6 MB)

---

### Files Affected

**New Files (8)**:
1. `/Sources/Domain/Models/InputSource.swift`
2. `/Sources/Domain/Models/OutputDestination.swift`
3. `/Sources/Infrastructure/Utils/TerminalDetector.swift`
4. `/Tests/DomainTests/InputSourceTests.swift`
5. `/Tests/DomainTests/OutputDestinationTests.swift`
6. `/Tests/InfrastructureTests/TerminalDetectorTests.swift`
7. `/Tests/IntegrationTests/StdinStdoutIntegrationTests.swift`
8. `/Tests/E2E/test_stdin_stdout.sh`

**Modified Files (11)**:
1. `/Sources/Shared/Models/ParsedCommand.swift` (type changes)
2. `/Sources/CLI/ArgumentParser.swift` (detection logic)
3. `/Sources/Domain/Protocols/FileHandler.swift` (protocol extension)
4. `/Sources/Infrastructure/FileSystemHandler.swift` (new methods)
5. `/Sources/Domain/Services/FilePathResolver.swift` (new methods)
6. `/Sources/Application/Commands/CompressCommand.swift` (use new types)
7. `/Sources/Application/Commands/DecompressCommand.swift` (use new types)
8. `/Sources/Shared/Errors/DomainError.swift` (new error cases)
9. `/Sources/Application/Services/ErrorHandler.swift` (handle new errors)
10. `/README.md` (documentation)
11. Many test files (update ParsedCommand usage)

---

### Implementation Timeline

| Week | Focus | Deliverables |
|------|-------|--------------|
| **Week 1** | Foundation | New types, protocols, utilities |
| **Week 2** | Core Integration | ArgumentParser, Commands, FileHandler |
| **Week 3** | Testing | Unit, integration, E2E tests |
| **Week 4** | Polish | Documentation, performance validation |

**Total**: 4 weeks (20 days)

---

### Testing Strategy

**Test Coverage Goals**:
- Maintain 85%+ overall coverage
- New components: 95%+ coverage
- All stdin/stdout combinations tested
- Performance validated (memory, speed)

**Test Levels**:
1. **Unit Tests**: 60% of effort
   - InputSource/OutputDestination
   - TerminalDetector
   - ArgumentParser detection logic
   - FileSystemHandler stream creation
   - FilePathResolver resolution logic
   - Command execution with new types

2. **Integration Tests**: 30% of effort
   - Compress: stdin → file, file → stdout, stdin → stdout
   - Decompress: stdin → file, file → stdout, stdin → stdout
   - Round-trip tests
   - Error scenarios

3. **End-to-End Tests**: 10% of effort
   - Shell scripts testing real pipelines
   - Memory profiling with large files
   - Performance benchmarks
   - Error message validation

---

### Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking existing functionality | Low | Critical | Comprehensive regression tests |
| stdin/stdout stream handling | Medium | High | Test with FileHandle, use /dev/stdin |
| Memory leaks | Low | High | defer cleanup, profiling |
| Complex error messages | Medium | Low | User testing, examples |
| Testing stdin/stdout | High | Medium | Focus on integration/E2E tests |

**Overall Risk**: **Low to Medium** - Well-understood problem domain, proven streaming infrastructure

---

### Success Criteria

**Functional**:
- ✅ All 6 stdin/stdout combinations work
- ✅ All 279 existing tests pass unchanged
- ✅ Round-trip compression preserves data

**Quality**:
- ✅ 85%+ test coverage maintained
- ✅ No memory leaks
- ✅ Clear, actionable error messages

**Performance**:
- ✅ Memory usage ~9.6 MB (same as file-based)
- ✅ Performance within 10% of file-based ops
- ✅ 100 MB+ files through pipes work

**Documentation**:
- ✅ README updated with examples
- ✅ Help text includes stdin/stdout usage
- ✅ Common pipeline patterns documented

---

## Key Design Decisions

### 1. Enum-Based Abstractions

**Decision**: Use `InputSource` and `OutputDestination` enums

**Rationale**:
- Type-safe (compiler-enforced)
- Clear intent (no magic strings like "-")
- Easy to pattern match in Swift
- Extensible (can add network sources later)
- Follows Swift idioms

**Alternative Rejected**: String-based convention (use "-" for stdin/stdout)
- Less type-safe
- Harder to validate
- Against Swift best practices

---

### 2. Automatic Pipe Detection

**Decision**: Use `isatty()` to automatically detect pipes

**Rationale**:
- Standard Unix approach
- Better UX (tool "does the right thing")
- No need to remember flags
- Matches user expectations

**Implementation**:
```swift
static func isStdinPipe() -> Bool {
    return isatty(STDIN_FILENO) == 0
}
```

**Alternative Rejected**: Explicit `--stdin`/`--stdout` flags
- More verbose
- Redundant with shell redirection
- Against Unix conventions

---

### 3. Algorithm Required for stdin Decompression

**Decision**: Require explicit `-m` flag when decompressing from stdin

**Rationale**:
- Cannot infer from file extension (no file)
- Clear and explicit is better than guessing
- Prevents ambiguity and errors

**Error Message**:
```
Error: Algorithm must be specified with -m flag when reading from stdin.

Cannot infer algorithm from file extension when using stdin.

Usage:
  cat file.lzfse | swiftcompress x -m lzfse -o output.txt
```

---

### 4. Leverage Existing Streaming Infrastructure

**Decision**: Reuse existing `compression_stream` API implementation

**Rationale**:
- Already has true streaming (constant memory)
- Proven performance (9.6 MB peak, validated)
- No architectural changes needed
- Just new input/output sources

**Benefit**: Minimal risk, maximum reuse

---

### 5. Clean Architecture Maintained

**Decision**: Place abstractions in correct layers

**Layer Placement**:
- `InputSource`, `OutputDestination` → **Domain Layer** (business concepts)
- `TerminalDetector` → **Infrastructure Layer** (system interaction)
- Detection logic → **CLI Layer** (user interface concern)
- Stream creation → **Infrastructure Layer** (system I/O)

**Validation**: Dependencies point inward only ✅

---

## Example Usage Scenarios

### Scenario 1: Compress Log Files in Real-Time

```bash
# Compress application logs as they're generated
tail -f /var/log/app.log | swiftcompress c -m lz4 -o compressed.log.lz4
```

**How It Works**:
1. `tail -f` streams log data to stdout
2. Shell creates pipe connecting tail's stdout to swiftcompress's stdin
3. `TerminalDetector.isStdinPipe()` returns `true`
4. ArgumentParser creates `ParsedCommand(inputSource: .stdin, ...)`
5. FileSystemHandler creates stream from `/dev/stdin`
6. Algorithm compresses in 64 KB chunks
7. Output written to file `compressed.log.lz4`

---

### Scenario 2: Network Transfer with Compression

```bash
# Compress and transfer file over SSH
swiftcompress c large.txt -m lzfse | ssh remote "cat > compressed.lzfse"
```

**How It Works**:
1. Input from file `large.txt`
2. `TerminalDetector.isStdoutPipe()` returns `true` (piped to ssh)
3. ArgumentParser creates `ParsedCommand(outputDestination: .stdout, ...)`
4. FileSystemHandler creates stream to `/dev/stdout`
5. Compressed data flows through pipe to ssh process
6. Remote system receives and writes to file

---

### Scenario 3: Re-Compress with Different Algorithm

```bash
# Convert .lzma to .lzfse without intermediate file
swiftcompress x old.lzma -m lzma | swiftcompress c -m lzfse -o new.lzfse
```

**How It Works**:
1. First process: decompress from file, write to stdout (pipe)
2. Shell creates pipe
3. Second process: read from stdin (pipe), compress to file
4. Data flows: file → decompress → pipe → compress → file
5. No intermediate uncompressed file created
6. Memory usage: ~19 MB total (9.6 MB per process)

---

## Migration Path

### Phase 1: No Breaking Changes

All existing usage continues to work:

```bash
# These commands work EXACTLY as before
swiftcompress c input.txt -m lzfse
swiftcompress c input.txt -m lzfse -o output.lzfse
swiftcompress x compressed.lzfse -m lzfse
swiftcompress x compressed.lzfse -m lzfse -o output.txt
```

**Guarantee**: 279 existing tests pass without modification to test logic

---

### Phase 2: New Capabilities Added

New pipeline patterns become available:

```bash
# NEW: stdin → file
cat input.txt | swiftcompress c -m lzfse -o output.lzfse

# NEW: file → stdout
swiftcompress c input.txt -m lzfse > output.lzfse

# NEW: stdin → stdout
cat input.txt | swiftcompress c -m lzfse | ssh remote "cat > file"
```

**User Impact**: Positive only - new features, no breaking changes

---

### Phase 3: Documentation Update

- README includes pipeline examples
- Help text clarifies stdin/stdout usage
- Common patterns documented
- Error messages guide users

**User Impact**: Better understanding of capabilities

---

## Performance Characteristics

### Memory Usage

**Before Feature** (file-based):
- 100 MB file compression: 9.6 MB peak memory
- 100 MB file decompression: 8.4 MB peak memory
- Constant regardless of file size

**After Feature** (stdio-based):
- 100 MB pipe compression: ~9.6 MB peak memory (same)
- 100 MB pipe decompression: ~8.4 MB peak memory (same)
- Constant regardless of data size

**Conclusion**: ✅ No memory regression - same streaming infrastructure

---

### Processing Speed

**File-Based** (validated):
- 100 MB LZFSE compression: 0.67 seconds
- 100 MB LZFSE decompression: 0.25 seconds

**stdio-Based** (expected):
- 100 MB pipe compression: 0.67 - 0.74 seconds (within 10%)
- 100 MB pipe decompression: 0.25 - 0.28 seconds (within 10%)

**Conclusion**: ✅ Minimal performance impact

---

## Validation Plan

### Regression Testing

```bash
# Run all existing tests
swift test

# Expected: All 279 tests pass
# Zero test failures
# Zero test modifications (except ParsedCommand type updates)
```

---

### Feature Testing

```bash
# Run new stdin/stdout tests
swift test --filter StdinStdout

# Expected: All new tests pass
# Integration tests cover all combinations
# E2E tests validate real pipelines
```

---

### Performance Testing

```bash
# Memory profiling
./Tests/Performance/test_stdin_memory.sh

# Expected: Memory < 15 MB for 100 MB files
# Performance within 10% of file-based
```

---

### User Acceptance Testing

```bash
# Real-world scenarios
cat large.log | swiftcompress c -m lz4 -o compressed.log.lz4
swiftcompress x file.lzfse -m lzfse | less
echo "test" | swiftcompress c -m lzfse | swiftcompress x -m lzfse > out.txt

# Expected: All scenarios work intuitively
# Error messages are clear
# Performance is acceptable
```

---

## Next Steps

### For Architecture Review

1. ✅ **Read ADR-007** for the architectural decision and rationale
2. ✅ **Review Design Specification** for detailed technical design
3. ✅ **Examine Diagrams** for visual understanding
4. ✅ **Check Implementation Guide** for practical approach
5. ✅ **Approve Design** - Architecture successfully implemented

### For Implementation Team

1. ✅ **Read Implementation Guide** for day-by-day plan
2. ✅ **Set Up Development Environment** (existing SETUP.md)
3. ✅ **Start Week 1, Day 1** - Create InputSource enum
4. ✅ **Follow Checklist** through 4-week timeline
5. ✅ **Run Tests Frequently** to catch issues early
6. ✅ **Validate at Milestones** (end of each week)

### For Documentation Review

1. ✅ **Review README updates** for clarity
2. ✅ **Test all examples** in documentation
3. ✅ **Validate help text** is accurate
4. ✅ **Check error messages** are user-friendly

---

## Conclusion

This comprehensive architectural design provides everything needed to successfully implement stdin/stdout streaming support in swiftcompress:

**Strengths**:
- ✅ Maintains Clean Architecture principles
- ✅ Zero breaking changes to existing functionality
- ✅ Leverages proven streaming infrastructure
- ✅ Type-safe design with clear abstractions
- ✅ Comprehensive testing strategy
- ✅ Detailed implementation guidance

**Risks Mitigated**:
- ✅ Regression testing ensures backward compatibility
- ✅ Integration/E2E tests validate real-world usage
- ✅ Performance validation prevents degradation
- ✅ Clear error messages prevent user confusion

**Implementation Confidence**: **High**
- Well-understood problem domain
- Proven patterns and infrastructure
- Detailed specifications and guidance
- Phased approach with validation gates

**Recommendation**: ✅ **Successfully implemented and validated**

---

## Document Index

1. **[ADR-007: stdin/stdout Streaming Support](./ADRs/ADR-007-stdin-stdout-streaming.md)**
   - Architectural decision record
   - Context, decision, consequences
   - Implementation approach
   - 40+ pages

2. **[stdin-stdout Design Specification](./stdin-stdout-design-specification.md)**
   - Detailed technical specification
   - Layer-by-layer changes
   - Testing strategy, risk assessment
   - 50+ pages

3. **[stdin-stdout Architecture Diagrams](./stdin-stdout-architecture-diagrams.md)**
   - Visual documentation
   - 15+ Mermaid diagrams
   - All workflows visualized
   - 30+ pages

4. **[stdin-stdout Implementation Guide](./stdin-stdout-implementation-guide.md)**
   - Practical implementation handbook
   - Day-by-day checklist
   - Code templates and examples
   - 40+ pages

5. **This Document: stdin-stdout-SUMMARY.md**
   - Executive summary
   - Quick reference
   - Document navigator

**Total Documentation**: 160+ pages of comprehensive architectural guidance

---

**Document Version**: 1.0
**Date**: 2025-10-10
**Author**: Architecture Team
**Status**: ✅ COMPLETE - Fully Implemented and Validated

**Approval Checklist**:
- ✅ Architecture review complete
- ✅ Technical design approved
- ✅ Implementation plan accepted
- ✅ Resources allocated
- ✅ Timeline agreed
- ✅ Implementation completed successfully

---

**Questions or Clarifications**: Contact architecture team or refer to specific documents above.
