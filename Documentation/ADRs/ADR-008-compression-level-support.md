# ADR-008: Compression Level Support

**Status:** Implemented
**Date:** 2025-10-10
**Decision Makers:** Development Team
**Related ADRs:** ADR-001 (Clean Architecture), ADR-002 (Protocol Abstraction)

## Context

Users need an intuitive way to control the trade-off between compression speed and compression ratio. Traditional tools like gzip offer numeric compression levels (1-9), but Apple's Compression framework does not provide native level parameters for its algorithms (LZFSE, LZ4, ZLIB, LZMA).

### User Requirements
- Simple way to prioritize speed vs. compression ratio
- Backward compatibility with existing commands
- Sensible defaults for users who don't specify preferences
- Clear, intuitive flag names (not cryptic numbers)

### Technical Constraints
- Apple's Compression framework APIs do not accept compression level parameters
- Cannot modify the underlying algorithms' compression behavior
- Must maintain Clean Architecture principles
- Must work within the existing protocol structure

## Decision

We will implement **semantic compression levels** that provide an intuitive user interface while working within the constraints of Apple's framework:

### Level Definition
```swift
public enum CompressionLevel: String, CaseIterable {
    case fast = "fast"       // Prioritizes speed
    case balanced = "balanced"  // Default: good balance
    case best = "best"       // Prioritizes compression ratio
}
```

### Implementation Strategy

**1. Algorithm Recommendation**
- **Fast**: Uses LZ4 (fastest algorithm, moderate ratio)
- **Balanced**: Uses LZFSE (Apple's balanced algorithm) - **default**
- **Best**: Uses LZMA (highest compression ratio)

**2. Buffer Size Optimization**
- **Fast**: 256 KB buffers (larger chunks for speed)
- **Balanced**: 64 KB buffers (standard size)
- **Best**: 64 KB buffers (LZMA benefits from standard size)

**3. CLI Flags**
```bash
# Using level flags (algorithm inferred from level)
swiftcompress c file.txt --fast      # Uses LZ4
swiftcompress c file.txt --best      # Uses LZMA
swiftcompress c file.txt             # Uses LZFSE (balanced, default)

# Explicit algorithm overrides level recommendation
swiftcompress c file.txt --fast -m zlib   # Fast mode with ZLIB
```

### Architecture Integration

**Domain Layer**
- `CompressionLevel` enum with business logic
- Protocol updated with `compressionLevel` parameter
- Algorithms accept level but currently don't use it (future-proof)

**Application Layer**
- `CompressCommand` accepts and passes compression level
- Buffer size determined from level

**CLI Layer**
- `--fast` and `--best` flags (mutually exclusive)
- Default to `balanced` when neither flag specified
- Level determines algorithm if `-m` not specified

## Alternatives Considered

### Alternative 1: Numeric Levels (1-9)
**Rejected:** Requires arbitrary mapping to 4 algorithms. Users wouldn't understand what level 5 means for LZFSE vs. LZMA.

```bash
# Confusing - what does level 5 mean?
swiftcompress c file.txt -m lzfse --level 5
```

### Alternative 2: Do Nothing / Wait for Apple
**Rejected:** Users need this feature now. Waiting for Apple to add native support (if ever) leaves a feature gap.

### Alternative 3: Percentage-Based (0-100)
**Rejected:** Even more arbitrary than 1-9. A "50% compression" is meaningless to users.

### Alternative 4: Algorithm-Specific Flags
**Rejected:** Too complex. Would require different flags for each algorithm.

```bash
# Too many flags to remember
swiftcompress c file.txt -m lzfse --lzfse-level 3
swiftcompress c file.txt -m lzma --lzma-dict-size 64
```

## Rationale

### Why Semantic Levels?

1. **Intuitive**: "fast" and "best" clearly communicate intent
2. **Simple**: Three levels are easier to understand than 9 numeric ones
3. **Practical**: Maps well to our 4 algorithms' characteristics
4. **Future-Proof**: If Apple adds native levels, we can layer them underneath

### Why Algorithm Recommendation?

Since we can't tune individual algorithms, we leverage the fact that different algorithms have inherently different speed/ratio characteristics:

| Algorithm | Speed | Ratio | Best For |
|-----------|-------|-------|----------|
| LZ4 | Fastest | Moderate | `--fast` |
| LZFSE | Balanced | Good | default |
| LZMA | Slow | Best | `--best` |
| ZLIB | Moderate | Moderate | explicit use |

### Why Buffer Size Tuning?

Larger buffers reduce overhead and increase throughput, beneficial for speed-prioritized compression. LZMA's dictionary-based approach works well with standard 64 KB chunks.

## Consequences

### Positive
- **User-Friendly**: Clear, intuitive interface
- **Backward Compatible**: Existing commands work unchanged
- **Future-Proof**: Ready for native levels if Apple adds them
- **Flexible**: Users can override recommendations
- **Performance**: Buffer size optimization provides measurable benefits

### Negative
- **Not True Levels**: We're recommending algorithms, not tuning them
- **Limited Granularity**: Only 3 levels vs. traditional 9
- **Education**: Users might expect numeric tuning like gzip

### Neutral
- **Documentation**: Must clearly explain what levels do
- **Algorithm Property**: `supportsCustomLevels = false` indicates future extensibility
- **Level Parameter**: Accepted but unused by algorithms (reserved for future use)

## Implementation Checklist

- [x] Create `CompressionLevel` enum in Domain layer
- [x] Update `CompressionAlgorithmProtocol` with `compressionLevel` parameter
- [x] Update all 4 algorithm implementations (LZFSE, LZ4, Zlib, LZMA)
- [x] Add `supportsCustomLevels` property to all algorithms
- [x] Update `ParsedCommand` with `compressionLevel` field
- [x] Update `CompressCommand` to accept and use compression level
- [x] Add `--fast` and `--best` flags to CLI ArgumentParser
- [x] Implement mutually exclusive flag validation
- [x] Update `CommandRouter` to pass compression level
- [x] Add `conflictingFlags` error case to `CLIError`
- [x] Update help text with level flag documentation
- [x] Write unit tests for `CompressionLevel` enum (25 tests)
- [x] Write unit tests for ArgumentParser level flags (16 tests)
- [x] Write unit tests for CompressCommand with levels
- [x] Update integration tests
- [x] Update mock algorithms in test infrastructure
- [x] Verify backward compatibility

## Validation Criteria

### Functional Tests
- [x] `--fast` flag uses LZ4
- [x] `--best` flag uses LZMA
- [x] Default (no flag) uses LZFSE
- [x] `--fast --best` together produces error
- [x] `--fast -m zlib` uses ZLIB (explicit override works)
- [x] Existing commands without level flags still work

### Non-Functional Tests
- [x] All existing tests pass
- [x] No breaking changes to API
- [x] Clean Architecture maintained
- [x] Buffer sizes correctly applied

## Future Considerations

### If Apple Adds Native Levels

If Apple's Compression framework adds native compression level support in the future, we can enhance our implementation:

```swift
// Future potential enhancement
func compressStream(..., compressionLevel: CompressionLevel) throws {
    if supportsCustomLevels {
        // Map semantic level to native level
        let nativeLevel = compressionLevel.toNativeLevel(for: algorithm)
        // Use native compression with level parameter
    } else {
        // Current implementation
    }
}
```

### Additional Levels

Could add intermediate levels if user feedback indicates need:
- `fastest`: LZ4 with largest buffers
- `balanced-fast`: LZFSE with larger buffers
- `balanced-best`: LZFSE with smaller buffers
- `extreme`: LZMA with maximum effort

### Algorithm-Specific Tuning

For algorithms that support it (outside Apple's framework), could add advanced flags:
```bash
--lzma-dict-size 128    # LZMA dictionary size
--zlib-strategy filtered  # ZLIB compression strategy
```

## References

- Apple Compression Framework Documentation
- gzip compression levels (1-9)
- LZ4 and LZMA algorithm characteristics
- User feedback on compression tool UX
- ADR-001: Clean Architecture for CLI Tool
- ADR-002: Protocol-Based Algorithm Abstraction

## Notes

This ADR represents a pragmatic solution to providing compression level control within the constraints of Apple's framework. The semantic levels provide value to users while maintaining architectural integrity and leaving room for future enhancements if native level support becomes available.
