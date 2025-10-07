# ADR-005: Explicit Algorithm Selection (MVP)

**Status**: Accepted (with planned evolution)

**Date**: 2025-10-07

---

## Context

SwiftCompress supports multiple compression algorithms (LZFSE, LZ4, Zlib, LZMA). Users must specify which algorithm to use when compressing files. The question arises: should the algorithm be explicitly required, or should we provide intelligent defaults and auto-detection?

### Use Cases

**Compression**:
```bash
# Explicit algorithm
swiftcompress c file.txt -m lzfse

# Question: Should we support defaults?
swiftcompress c file.txt  # Use default algorithm?
```

**Decompression**:
```bash
# Explicit algorithm
swiftcompress x file.txt.lzfse -m lzfse

# Question: Should we auto-detect from extension?
swiftcompress x file.txt.lzfse  # Infer lzfse from extension?
```

### Considerations

**Explicit Selection**:
- Clear and unambiguous
- User always knows what algorithm is used
- No surprises or unexpected behavior
- Educational (users learn algorithm names)

**Auto-Detection/Defaults**:
- More convenient for users
- Fewer keystrokes
- Better user experience for common cases
- Risk of wrong algorithm selection

---

## Decision

For **MVP (Phase 1)**, we will **require explicit algorithm selection** using the `-m` flag for both compression and decompression operations. No defaults or auto-detection in initial release.

### MVP Behavior

**Compression** (Required: `-m` flag)
```bash
# Valid
swiftcompress c file.txt -m lzfse
swiftcompress c file.txt -m lz4

# Invalid (error)
swiftcompress c file.txt
# Error: Missing required argument: -m
```

**Decompression** (Required: `-m` flag)
```bash
# Valid
swiftcompress x file.txt.lzfse -m lzfse

# Invalid (error)
swiftcompress x file.txt.lzfse
# Error: Missing required argument: -m
```

### Rationale for MVP

1. **Simplicity**: Simpler implementation, no inference logic needed
2. **Explicitness**: User intent is always clear
3. **No Wrong Assumptions**: Can't accidentally use wrong algorithm
4. **Educational**: Users learn about available algorithms
5. **Predictability**: Same command always produces same result
6. **Testing**: Fewer code paths to test initially

### Phase 2 Enhancement

After MVP validation, add **algorithm auto-detection** for decompression based on file extension:

```bash
# Phase 2: Auto-detect from extension
swiftcompress x file.txt.lzfse
# Automatically uses lzfse algorithm

swiftcompress x file.txt.lz4
# Automatically uses lz4 algorithm

# Explicit still works (and overrides)
swiftcompress x file.txt.lzfse -m lz4
# Uses lz4 even though extension suggests lzfse
```

**Extension Mapping**:
- `.lzfse` → lzfse
- `.lz4` → lz4
- `.zlib` → zlib
- `.lzma` → lzma

**Fallback**: If extension doesn't match, require explicit `-m` flag:
```bash
swiftcompress x file.compressed
# Error: Cannot infer algorithm from extension. Use -m flag.
```

### Phase 3 Consideration (Optional)

Consider **default compression algorithm** for convenience:

```bash
# Phase 3: Default to lzfse for compression
swiftcompress c file.txt
# Uses lzfse by default

# Explicit overrides default
swiftcompress c file.txt -m lz4
# Uses lz4
```

**Default Selection Criteria**:
- LZFSE: Apple's recommended algorithm
- Good balance of speed and compression ratio
- Native macOS algorithm
- Clear documentation that this is default

---

## Rationale

### Why Explicit for MVP?

**1. Principle of Least Surprise**
- Users are never surprised by algorithm choice
- Explicit is better than implicit (Python Zen)
- No hidden behavior or magic

**2. Implementation Simplicity**
- No inference logic needed
- No extension parsing
- No default management
- Faster to implement and test

**3. User Education**
- Forces users to learn algorithm options
- Encourages reading documentation
- Better understanding of tool capabilities

**4. Safety**
- Cannot accidentally use wrong algorithm
- No risk of extension-based mistakes
- Explicit verification by user

**5. Incremental Enhancement**
- Can add auto-detection later
- MVP validates core functionality first
- User feedback guides enhancements

### Why Allow Auto-Detection in Phase 2?

**1. User Convenience**
- Decompression usually obvious from extension
- Common workflow: compress with tool, decompress later
- Reduces typing for frequent operations

**2. Industry Standard**
- Most compression tools auto-detect format
- Users expect this behavior
- Example: `gzip`, `bzip2`, `xz` all auto-detect

**3. Low Risk**
- Extension clearly indicates algorithm
- Explicit flag can override if needed
- Error if ambiguous

**4. Progressive Enhancement**
- Maintains backwards compatibility (explicit still works)
- Adds convenience without removing control
- User can choose explicit or implicit

### Why Compression Stays Explicit (Even Phase 2+)?

**1. No Clear Default**
- Different algorithms suited for different data
- LZFSE good general purpose
- LZ4 better for speed
- LZMA better for size
- Zlib for compatibility

**2. Educational Value**
- Users should think about algorithm choice
- Compression is one-time, decompression may be many times
- Worth extra effort to choose right algorithm

**3. Explicit Intent**
- Compression creates new file format
- Important decision that should be conscious
- Decompression just reverses known format

### Alternative Approaches Considered

**1. Always Auto-Detect (Even MVP)**

**Rejected Because**:
- Adds complexity to MVP
- More testing required
- Risk of wrong inference
- Want to validate core functionality first

**2. Default Algorithm (LZFSE) for Compression in MVP**

**Rejected Because**:
- May not be best choice for all use cases
- Users might not know they can change it
- Could create compression "monoculture"
- Better to require explicit choice

**3. Content-Based Algorithm Selection**
```bash
swiftcompress c file.txt  # Analyzes content, chooses algorithm
```

**Rejected Because**:
- Computationally expensive (must read file)
- Unpredictable behavior
- Hard to test
- Not transparent to user

**4. Configuration File with Defaults**
```yaml
# ~/.swiftcompress.yml
default_algorithm: lzfse
```

**Rejected for MVP (Consider for Phase 3)**:
- Adds complexity
- Another file to manage
- MVP should be simple
- Could add later if user feedback suggests need

---

## Consequences

### Positive (MVP)

1. **Simple Implementation**
   - No inference logic needed in MVP
   - Straightforward validation
   - Easy to test

2. **Predictable Behavior**
   - Same command always does same thing
   - No surprises
   - Easy to document

3. **Clear User Intent**
   - Algorithm choice is explicit
   - No ambiguity in what will happen
   - Users understand tool better

4. **Educational**
   - Users learn about algorithms
   - Encourages reading documentation
   - Better tool understanding

5. **Safe**
   - Cannot use wrong algorithm accidentally
   - No risk of misinterpretation
   - Explicit verification

### Negative (MVP)

1. **Less Convenient**
   - More typing required
   - Tedious for repeated operations
   - Not as user-friendly as auto-detection

2. **Learning Curve**
   - New users must learn algorithm names
   - Must remember `-m` flag
   - More to type in tutorials

3. **Decompression Redundancy**
   - Extension often clearly indicates algorithm
   - Requiring `-m` seems redundant
   - Extra work for obvious cases

### Positive (Phase 2+)

1. **User Convenience**
   - Auto-detection for decompression saves typing
   - More user-friendly
   - Matches industry standards

2. **Backwards Compatible**
   - Explicit `-m` still works
   - No breaking changes
   - Users can choose explicit or implicit

3. **Best of Both Worlds**
   - Convenience for common case
   - Explicit control when needed
   - Progressive enhancement

### Neutral

1. **Incremental Rollout**
   - Can gather user feedback on MVP
   - Adjust Phase 2 based on real usage
   - Validates assumptions

---

## Implementation Guide

### MVP Implementation

**Step 1: Argument Parser Validation**

```swift
// ArgumentParser.swift
func parse(_ arguments: [String]) throws -> ParsedCommand? {
    // ...

    // Validate -m flag present
    guard let algorithmName = parsedArgs.algorithmName else {
        throw CLIError.missingRequiredArgument(name: "-m")
    }

    return ParsedCommand(
        commandType: commandType,
        inputPath: inputPath,
        algorithmName: algorithmName,  // Never nil in MVP
        outputPath: outputPath,
        forceOverwrite: forceOverwrite
    )
}
```

**Step 2: Help Text**

```
USAGE:
    swiftcompress c <input> -m <algorithm> [-o <output>] [-f]
    swiftcompress x <input> -m <algorithm> [-o <output>] [-f]

OPTIONS:
    -m <algorithm>    Compression algorithm (required)
                      Supported: lzfse, lz4, zlib, lzma

    -o <output>       Output file path (optional)
                      Default: <input>.<algorithm> for compression
                               <input> without extension for decompression

    -f                Force overwrite existing output file

EXAMPLES:
    swiftcompress c file.txt -m lzfse
    swiftcompress x file.txt.lzfse -m lzfse -o recovered.txt
```

### Phase 2 Implementation

**Step 1: Extend FilePathResolver**

```swift
// Domain/FilePathResolver.swift
extension FilePathResolver {
    func inferAlgorithm(from filePath: String) -> String? {
        let extensionMapping: [String: String] = [
            ".lzfse": "lzfse",
            ".lz4": "lz4",
            ".zlib": "zlib",
            ".lzma": "lzma"
        ]

        let url = URL(fileURLWithPath: filePath)
        let ext = url.pathExtension

        return extensionMapping[".\(ext)"]
    }
}
```

**Step 2: Update Argument Parser**

```swift
func parse(_ arguments: [String]) throws -> ParsedCommand? {
    // ...

    var algorithmName = parsedArgs.algorithmName

    // Phase 2: Auto-detect for decompression if -m not provided
    if commandType == .decompress && algorithmName == nil {
        algorithmName = pathResolver.inferAlgorithm(from: inputPath)

        if algorithmName == nil {
            throw CLIError.cannotInferAlgorithm(
                path: inputPath,
                suggestion: "Use -m flag to specify algorithm"
            )
        }
    } else if commandType == .compress && algorithmName == nil {
        // Compression still requires explicit -m
        throw CLIError.missingRequiredArgument(name: "-m")
    }

    return ParsedCommand(
        commandType: commandType,
        inputPath: inputPath,
        algorithmName: algorithmName!,  // Never nil after validation
        outputPath: outputPath,
        forceOverwrite: forceOverwrite
    )
}
```

**Step 3: Update Help Text**

```
USAGE:
    swiftcompress c <input> -m <algorithm> [-o <output>] [-f]
    swiftcompress x <input> [-m <algorithm>] [-o <output>] [-f]

OPTIONS:
    -m <algorithm>    Compression algorithm
                      Required for compression
                      Optional for decompression (auto-detected from extension)
                      Supported: lzfse, lz4, zlib, lzma

EXAMPLES:
    # Compression (explicit algorithm required)
    swiftcompress c file.txt -m lzfse

    # Decompression (algorithm auto-detected)
    swiftcompress x file.txt.lzfse

    # Decompression (explicit algorithm overrides auto-detection)
    swiftcompress x file.txt.lzfse -m lz4
```

---

## Validation Criteria

### MVP Validation

This decision is successfully implemented when:

1. **Required Flag**: `-m` flag is required for both compress and decompress
2. **Clear Errors**: Missing `-m` produces clear error message
3. **Help Text**: Documentation clearly states `-m` is required
4. **Test Coverage**: All paths tested (with and without `-m`)
5. **User Feedback**: Gather feedback on whether auto-detection is desired

### Phase 2 Validation

Enhancement is successful when:

1. **Auto-Detection Works**: Decompression infers algorithm from extension
2. **Explicit Override**: `-m` flag overrides auto-detection
3. **Clear Errors**: Ambiguous extensions produce clear error
4. **Backwards Compatible**: Explicit `-m` still works as before
5. **Test Coverage**: All inference paths tested
6. **Documentation**: Help text clearly explains auto-detection

---

## User Stories

### MVP User Stories

**User Story 1**: As a user, I explicitly specify the compression algorithm so I know exactly what format my file will be in.

```bash
swiftcompress c document.pdf -m lzfse
# Output: document.pdf.lzfse
```

**User Story 2**: As a user, I get a clear error if I forget to specify the algorithm.

```bash
swiftcompress c document.pdf
# Error: Missing required argument: -m
# Run 'swiftcompress --help' for usage.
```

### Phase 2 User Stories

**User Story 3**: As a user, I can decompress a file without specifying the algorithm if the extension is clear.

```bash
swiftcompress x document.pdf.lzfse
# Automatically uses lzfse algorithm
# Output: document.pdf
```

**User Story 4**: As a user, I can override auto-detection by explicitly specifying the algorithm.

```bash
swiftcompress x file.compressed -m lzfse
# Uses lzfse even though extension is .compressed
```

---

## Migration Path (MVP → Phase 2)

### Backwards Compatibility

Phase 2 changes are **additive only**:
- All MVP commands continue to work
- Explicit `-m` always honored
- No breaking changes

### Communication Strategy

When releasing Phase 2:
1. **Release Notes**: Clearly document new auto-detection feature
2. **Examples**: Show both explicit and implicit usage
3. **Recommendation**: Suggest explicit `-m` for scripts (predictability)
4. **Blog Post**: Explain reasoning and how to use new feature

---

## Related Decisions

- **ADR-002**: Protocol-Based Algorithm Abstraction (enables algorithm registry lookup)
- **ADR-001**: Clean Architecture (FilePathResolver in domain layer handles inference)

---

## References

- [GNU Coding Standards - Option Parsing](https://www.gnu.org/prep/standards/html_node/Option-Table.html)
- [Command Line Interface Guidelines](https://clig.dev/)
- [Principle of Least Surprise](https://en.wikipedia.org/wiki/Principle_of_least_astonishment)

---

## Review and Approval

**Proposed by**: Architecture Team
**Reviewed by**: Development Team, UX Team
**Approved by**: Technical Lead, Product Owner
**Date**: 2025-10-07

**Decision**: Start with explicit algorithm selection for MVP, gather user feedback, and implement auto-detection in Phase 2 based on validated need.

**Next Review**: After MVP release, review user feedback to confirm Phase 2 implementation.
