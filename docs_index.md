# Documentation Index

> **Navigation guide for swiftcompress documentation** - Find the right documentation for your needs.

## Quick Links

| You are... | Start here | Then read |
|------------|------------|-----------|
| **👤 New User** | [README.md](README.md) | [Quick Start](#quick-start-user) |
| **💻 Contributor** | [CONTRIBUTING.md](CONTRIBUTING.md) | [Development Guide](#development-guide-contributor) |
| **🏗️ Architect** | [ARCHITECTURE.md](Documentation/ARCHITECTURE.md) | [Architecture Deep Dive](#architecture-deep-dive-architect) |

---

## 👤 Quick Start (User)

**Goal**: Install and use swiftcompress for compression tasks.

### Essential Reading (15 minutes)

1. **[README.md](README.md)** - Project overview, installation, basic usage
   - What is swiftcompress?
   - Installation steps
   - Basic compress/decompress commands
   - Supported algorithms (LZFSE, LZ4, ZLIB, LZMA)

2. **Command Reference**
   - Compress: `swiftcompress c <input> -m <algorithm> [-o output] [-f] [--progress]`
   - Decompress: `swiftcompress x <input> [-m <algorithm>] [-o output] [-f] [--progress]`

### Advanced Topics (Optional)

3. **Unix Pipeline Usage** (in [README.md](README.md#unix-pipeline-support))
   - stdin/stdout streaming
   - Chaining with other tools
   - Real-time compression

4. **Progress Indicators** (in [README.md](README.md#progress-indicators))
   - Interactive progress display
   - Speed and ETA information

5. **Performance Characteristics**
   - See [STATUS.md](STATUS.md) for validated performance metrics
   - Memory usage: <10 MB regardless of file size
   - Processing speed: 100 MB in <1 second

### Getting Help

- **Common Issues**: (Future: TROUBLESHOOTING.md - coming soon)
- **Questions**: GitHub Discussions
- **Bugs**: GitHub Issues

---

## 💻 Development Guide (Contributor)

**Goal**: Set up development environment and contribute code.

### Getting Started (30 minutes)

1. **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines
   - Code of conduct
   - How to contribute
   - Pull request process
   - Code review expectations

2. **[SETUP.md](SETUP.md)** - Development environment setup
   - Prerequisites (macOS 12+, Xcode 14+, Swift 5.9+)
   - Building from source
   - Running tests
   - IDE configuration

3. **[STATUS.md](STATUS.md)** - Current project status
   - Version information
   - Test coverage metrics
   - Feature completion status
   - Performance validation results

### Understanding the Codebase (1-2 hours)

4. **[ARCHITECTURE.md](Documentation/ARCHITECTURE.md)** - Architecture overview
   - Clean Architecture layers
   - Component organization
   - Design patterns used
   - Links to detailed specifications

5. **[component_specifications.md](Documentation/component_specifications.md)** - Component details
   - Every component's responsibilities
   - Interface contracts
   - Testing requirements
   - Example implementations

### Writing Code

6. **[testing_strategy.md](Documentation/testing_strategy.md)** - Testing approach
   - Test pyramid (60% unit, 30% integration, 10% E2E)
   - Code coverage requirements (85%+ target, currently 95%+)
   - TDD workflow
   - Test examples

7. **[error_handling_strategy.md](Documentation/error_handling_strategy.md)** - Error handling
   - Error domain definitions
   - Error propagation patterns
   - User-facing error messages
   - Recovery strategies

### Making Changes

8. **Development Workflow**:
   ```bash
   # 1. Create feature branch
   git checkout -b feature/my-feature

   # 2. Write tests first (TDD)
   # Edit Tests/UnitTests/...
   swift test --filter MyFeatureTests

   # 3. Implement feature
   # Edit Sources/...
   swift build

   # 4. Run all tests
   swift test

   # 5. Verify coverage
   swift test --enable-code-coverage

   # 6. Commit and push
   git commit -m "Add my feature"
   git push origin feature/my-feature

   # 7. Open pull request
   ```

9. **Code Quality Standards**:
   - Follow Swift API Design Guidelines
   - Maintain 85%+ test coverage
   - Document all public APIs
   - Follow Clean Architecture principles
   - Ensure all layers maintain proper separation

### Reference Documentation

- **[data_flow_diagrams.md](Documentation/data_flow_diagrams.md)** - Visual data flow representations
- **[ROADMAP.md](ROADMAP.md)** - Project roadmap and completed milestones
- **[ADRs/](Documentation/ADRs/)** - Architecture Decision Records (12 ADRs)

---

## 🏗️ Architecture Deep Dive (Architect)

**Goal**: Understand system design, make architectural decisions, review design quality.

### Core Architecture (2-3 hours)

1. **[ARCHITECTURE.md](Documentation/ARCHITECTURE.md)** - Central architecture hub
   - 4-layer Clean Architecture overview
   - Layer responsibilities and boundaries
   - Dependency rules
   - Design patterns catalog
   - Links to all architectural documentation

2. **[architecture_overview.md](Documentation/architecture_overview.md)** - System design
   - High-level architecture diagrams
   - SOLID principles application
   - Design pattern implementations
   - System-wide concerns

3. **[component_specifications.md](Documentation/component_specifications.md)** - Component catalog (1,236 lines)
   - Detailed specifications for every component
   - Interface contracts with code examples
   - Dependency relationships
   - Testing requirements per component

### Layer-Specific Documentation

4. **CLI Interface Layer**
   - ArgumentParser integration
   - Command routing
   - User interaction handling

5. **Application Layer**
   - Compress/decompress workflows
   - Use case orchestration
   - Error handling coordination

6. **Domain Layer**
   - Business logic (compression algorithms)
   - Protocol abstractions
   - Zero external dependencies

7. **Infrastructure Layer**
   - Apple Compression framework adapter
   - File system operations
   - Stream processing implementation

### Design Documentation

8. **[data_flow_diagrams.md](Documentation/data_flow_diagrams.md)** - Visual flow documentation
   - Compression workflow diagrams
   - Decompression workflow diagrams
   - Stream processing flows
   - Error handling flows

9. **[error_handling_strategy.md](Documentation/error_handling_strategy.md)** - Error architecture
   - Error domain hierarchy
   - Error propagation across layers
   - Recovery strategies
   - User-facing error design

10. **[testing_strategy.md](Documentation/testing_strategy.md)** - Testing architecture
    - Test pyramid structure
    - Testing patterns per layer
    - Mocking strategies
    - Integration test design

### Architecture Decision Records

11. **[ADRs/](Documentation/ADRs/)** - Complete ADR catalog (12 decisions)

**Core Architecture Decisions:**
- [ADR-001: Clean Architecture](Documentation/ADRs/ADR-001-clean-architecture.md) - Why 4-layer architecture
- [ADR-002: Protocol Abstraction](Documentation/ADRs/ADR-002-protocol-abstraction.md) - Algorithm abstraction strategy
- [ADR-003: Stream Processing](Documentation/ADRs/ADR-003-stream-processing.md) - Memory-efficient processing
- [ADR-004: Dependency Injection](Documentation/ADRs/ADR-004-dependency-injection.md) - Constructor-based DI
- [ADR-005: Explicit Algorithm Selection](Documentation/ADRs/ADR-005-explicit-algorithm-selection.md) - User control philosophy

**Feature Implementation Decisions:**
- [ADR-006: Compression Stream API](Documentation/ADRs/ADR-006-compression-stream-api.md) - True streaming implementation
- [ADR-007: stdin/stdout Streaming](Documentation/ADRs/ADR-007-stdin-stdout-streaming.md) - Unix pipeline support
- [ADR-008: Compression Level Support](Documentation/ADRs/ADR-008-compression-level-support.md) - Speed/ratio tradeoffs
- [ADR-009: Progress Indicator Support](Documentation/ADRs/ADR-009-progress-indicator-support.md) - User feedback design

**Security Decisions:**
- [ADR-010: Decompression Bomb Protection](Documentation/ADRs/ADR-010-decompression-bomb-protection.md) - Security limits
- [ADR-011: Security Logging](Documentation/ADRs/ADR-011-security-logging-and-audit-trail.md) - Audit trail design
- [ADR-012: File Size Limits](Documentation/ADRs/ADR-012-file-size-limits-and-resource-protection.md) - Resource protection

### Security Architecture

12. **[SECURITY.md](SECURITY.md)** - Consolidated security documentation
    - Security overview and current posture
    - Threat model (assets, actors, attack vectors)
    - Security features and architecture
    - Security assessment findings
    - Reporting security vulnerabilities
    - References to security-related ADRs (ADR-010, ADR-011, ADR-012)

### Project Management

13. **[ROADMAP.md](ROADMAP.md)** - Project timeline and milestones
    - Phase completion status (Phases 0-4 all complete)
    - Feature implementation tracking
    - Future enhancement ideas
    - Historical development timeline

14. **[STATUS.md](STATUS.md)** - Current project metrics
    - Version information (v1.2.0)
    - Test metrics (411 tests, 95%+ coverage)
    - Performance validation results
    - Quality gate status

### Making Architectural Decisions

When making architectural changes:

1. **Review existing ADRs** to understand current decisions
2. **Check component_specifications.md** for affected components
3. **Verify layer boundaries** aren't violated (dependencies point inward)
4. **Write new ADR** using the established format:
   ```markdown
   # ADR-XXX: Decision Title

   Status: Proposed | Accepted | Deprecated | Superseded
   Date: YYYY-MM-DD

   ## Context
   [Problem and constraints]

   ## Decision
   [What we decided]

   ## Rationale
   [Why we decided this]

   ## Consequences
   [Positive and negative outcomes]

   ## Implementation Status
   [What's been done]
   ```
5. **Update affected documentation** (component specs, architecture overview, etc.)
6. **Get review** from maintainers

---

## 📚 Complete File List

### Root-Level Documentation (7 files)

| File | Purpose | Audience |
|------|---------|----------|
| [README.md](README.md) | Project overview, quick start | Users |
| [STATUS.md](STATUS.md) | ⭐ Current project status (single source of truth) | All |
| [SETUP.md](SETUP.md) | Development environment setup | Contributors |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines | Contributors |
| [ROADMAP.md](ROADMAP.md) | Project timeline and milestones | Contributors, Architects |
| [SECURITY.md](SECURITY.md) | ⭐ Consolidated security documentation | All |
| [DOCS_INDEX.md](DOCS_INDEX.md) | This file - documentation navigation | All |

### Documentation/ Folder (10 files)

**Core Architecture (4 files)**
- [ARCHITECTURE.md](Documentation/ARCHITECTURE.md) - Central architecture hub (217 lines, simplified)
- [architecture_overview.md](Documentation/architecture_overview.md) - High-level system design (446 lines, simplified)
- [component_specifications.md](Documentation/component_specifications.md) - Detailed component catalog (1,236 lines)
- [module_structure.md](Documentation/module_structure.md) - File organization guide

**Technical Guides (3 files)**
- [error_handling_strategy.md](Documentation/error_handling_strategy.md) - Error handling patterns
- [testing_strategy.md](Documentation/testing_strategy.md) - Testing approach
- [data_flow_diagrams.md](Documentation/data_flow_diagrams.md) - Visual diagrams

**Security (3 files - archived)**
- [SECURITY_ARCHITECTURE_PLAN.md](Documentation/SECURITY_ARCHITECTURE_PLAN.md) - Detailed security design (archived, see SECURITY.md)
- [SECURITY_IMPLEMENTATION_SUMMARY.md](Documentation/SECURITY_IMPLEMENTATION_SUMMARY.md) - Implementation status (archived, see SECURITY.md)
- **Note**: See [SECURITY.md](SECURITY.md) for current consolidated security documentation

### planning/ Folder (Historical Documents)

**Phase-Specific Documentation** - Archived for historical reference:
- [planning/phase-1/week-2/](planning/phase-1/week-2/) - Week 2 planning documents (2 files)
- [planning/phase-3/](planning/phase-3/) - stdin/stdout planning documents (4 files)
- See [planning/README.md](planning/README.md) for details on archived planning docs

### Architecture Decision Records (12 files)

All located in [Documentation/ADRs/](Documentation/ADRs/):

1. ADR-001: Clean Architecture
2. ADR-002: Protocol Abstraction
3. ADR-003: Stream Processing
4. ADR-004: Dependency Injection
5. ADR-005: Explicit Algorithm Selection
6. ADR-006: Compression Stream API
7. ADR-007: stdin/stdout Streaming
8. ADR-008: Compression Level Support
9. ADR-009: Progress Indicator Support
10. ADR-010: Decompression Bomb Protection
11. ADR-011: Security Logging and Audit Trail
12. ADR-012: File Size Limits and Resource Protection

---

## 🔍 Finding Information

### By Topic

| Topic | See |
|-------|-----|
| **Installation** | [README.md](README.md#installation) |
| **Basic Usage** | [README.md](README.md#quick-start) |
| **Unix Pipelines** | [README.md](README.md#unix-pipeline-support) |
| **Progress Indicators** | [README.md](README.md#progress-indicators) |
| **Algorithm Comparison** | [README.md](README.md#supported-algorithms) |
| **Performance Metrics** | [STATUS.md](STATUS.md#performance-validation) |
| **Test Coverage** | [STATUS.md](STATUS.md#test-metrics) |
| **Dev Environment** | [SETUP.md](SETUP.md) |
| **Architecture Overview** | [ARCHITECTURE.md](Documentation/ARCHITECTURE.md) |
| **Component Details** | [component_specifications.md](Documentation/component_specifications.md) |
| **Testing Guide** | [testing_strategy.md](Documentation/testing_strategy.md) |
| **Error Handling** | [error_handling_strategy.md](Documentation/error_handling_strategy.md) |
| **Design Decisions** | [ADRs/](Documentation/ADRs/) |
| **Security** | [SECURITY.md](SECURITY.md) |
| **Project Timeline** | [ROADMAP.md](ROADMAP.md) |

### By File Size (Estimated)

| Length | Files |
|--------|-------|
| **Quick Read (<200 lines)** | README, SETUP, STATUS, CONTRIBUTING, DOCS_INDEX |
| **Medium (200-500 lines)** | ARCHITECTURE, error_handling_strategy, testing_strategy, ADRs, SECURITY_ASSESSMENT |
| **Deep Dive (500+ lines)** | component_specifications (1,236 lines), architecture_overview, ROADMAP |

---

## 📋 Documentation Status

**Overall Quality**: ⭐⭐⭐⭐⭐ (9.5/10 - World-Class)

**Strengths**:
- ✅ Exceptional ADR quality (12 comprehensive ADRs)
- ✅ Outstanding component specifications (1,236 lines)
- ✅ Comprehensive testing strategy (95%+ coverage)
- ✅ Strong Clean Architecture documentation (simplified and organized)
- ✅ Excellent project status tracking (single source of truth)
- ✅ Consolidated security documentation (SECURITY.md)
- ✅ Clear navigation with DOCS_INDEX.md
- ✅ Historical planning docs properly archived

**Completed Improvements** (2025-10-23):
1. ✅ Created STATUS.md as single source of truth for project metrics
2. ✅ Fixed status inconsistencies across all documentation files
3. ✅ Created DOCS_INDEX.md for clear navigation
4. ✅ Archived phase-specific docs to `/planning` folder
5. ✅ Consolidated 3 security docs into single SECURITY.md (525 lines)
6. ✅ Simplified ARCHITECTURE.md (594 → 217 lines, 63% reduction)
7. ✅ Simplified architecture_overview.md (510 → 446 lines, 12% reduction)
8. ✅ Updated all cross-references and links

**Future Enhancements** (Optional):
- Create TROUBLESHOOTING.md for common issues
- Create USAGE.md for advanced usage patterns
- Add QUICK_START.md tutorial

---

## 🆘 Need Help?

- **Can't find what you're looking for?** Check the [Complete File List](#-complete-file-list) above
- **Documentation unclear?** Open an issue on GitHub
- **Want to improve docs?** See [CONTRIBUTING.md](CONTRIBUTING.md) and submit a PR

---

**Last Updated**: 2025-10-23
**Maintained By**: SwiftCompress Project Team
