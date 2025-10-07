# 🎯 Product Goal

Deliver a macOS-only CLI tool (`swiftcompress`) that can **compress and
decompress single files** using Apple's Compression framework
algorithms.

It should:\
- be explicit in algorithm choice (`-m lzfse`, `-m lz4`, etc.)\
- provide predictable default output filenames\
- fail gracefully with useful error messages\
- be scriptable (exit codes, stdout/stderr conventions)

Tech info:
- In the implementation we use apple's compression solution: https://developer.apple.com/documentation/Compression
- The app written in Swift language.
- Swift Package Manager used for dependencies (Swift ArgumentParser for CLI)

------------------------------------------------------------------------

# 🌐 Product Overview

-   **Binary name**: `swiftcompress`\
-   **Primary commands**:
    -   `c` → compress\
    -   `x` → extract/decompress\
-   **Arguments**:
    -   `inputfile` (required)\
    -   `-m <algorithm>` (required, one of `lzfse`, `lz4`, `zlib`,
        `lzma`)\
    -   `-o <outputfile>` (optional, default derived automatically)\
    -   `-f` (optional, force overwrite)

Default behavior:\
- On compression: `inputfile.ext → inputfile.ext.<method>`\
- On decompression: `inputfile.ext.<method> → inputfile.ext` (or
`inputfile.ext.out` if file exists and `-f` not provided)

------------------------------------------------------------------------

# 📋 User Stories (incremental roadmap)

## 🟢 MVP --- Core functionality

1.  **As a user,** I can compress a single file with
    `swiftcompress c file.txt -m lzfse`, and get `file.txt.lzfse`.\
2.  **As a user,** I can decompress a single file with
    `swiftcompress x file.txt.lzfse -m lzfse`, and get `file.txt`.\
3.  **As a user,** I can override the output filename with `-o`, so I
    control where the result goes.\
4.  **As a user,** I see clear error messages (file not found, wrong
    algorithm, corrupted data). Non-zero exit codes indicate failure.

------------------------------------------------------------------------

## 🟡 Usability improvements

5.  **As a user,** I can run `swiftcompress --help` to see usage
    examples, supported algorithms, and options.\
6.  **As a user,** I don't accidentally overwrite files unless I add
    `-f`.\
7.  **As a user,** I can omit `-m` when decompressing if the algorithm
    can be auto-detected from the extension (e.g. `.lzfse` → LZFSE).

------------------------------------------------------------------------

## 🟠 Later niceties

8.  **As a user,** I can stream data via `stdin/stdout` for use in shell
    pipelines.\
9.  **As a user,** I can choose compression level flags (`--fast`,
    `--best`) where the algorithm supports tuning.

------------------------------------------------------------------------

# ✅ Output policy (MVP)

-   Quiet by default → success produces no stdout\
-   Errors print to stderr\
-   Exit codes: `0` = success, `1` = generic failure, other codes
    reserved
