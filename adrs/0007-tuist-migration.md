# ADR 0007: Tuist Migration

## Status

Accepted

## Context

IronUI was built using Swift Package Manager (SPM) for dependency management and project structure. While SPM works well for libraries, it has limitations for complex multi-platform projects:

1. **No warnings-as-errors**: SPM does not support treating warnings as errors in `Package.swift`, making it impossible to enforce code quality through the build system.

2. **Fragmented testing**: Running tests across macOS and iOS required separate commands and the Sample app for iOS snapshot tests used a separate Xcode project.

3. **Sample app integration**: The Sample app used a standalone Xcode project with manual dependency management on IronUI modules.

4. **Shell scripts**: Several shell scripts (`run-tests.sh`, `format.sh`, `generate-docs.sh`, `export-snapshots-for-docs.sh`) were needed to orchestrate common workflows.

## Decision

Migrate to [Tuist](https://tuist.dev) for project generation while preserving `Package.swift` for external SPM consumers.

### Key Changes

1. **Project Structure**:
   - `Tuist.swift` - Root configuration
   - `Tuist/Package.swift` - External dependencies
   - `Tuist/ProjectDescriptionHelpers/` - Shared target templates and settings
   - `Project.swift` - Main library project (9 library targets + 5 test targets + CLI)
   - `Workspace.swift` - Workspace definition
   - `Apps/PreviewGallery/` - Migrated from Sample app
   - `Apps/IronUIDemo/` - New demo showcase app (content deferred)

2. **Build Settings**:
   - `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES`
   - `GCC_TREAT_WARNINGS_AS_ERRORS=YES`
   - `SWIFT_STRICT_CONCURRENCY=complete`
   - `SWIFT_VERSION=6.0`

3. **CLI Updates**:
   - Build, test, and snapshot commands now use `tuist` by default
   - `--spm` flag available for SPM-based workflows
   - Clean command removes Tuist-generated files

4. **Removed**:
   - `Sample/` directory (migrated to `Apps/PreviewGallery/`)
   - Shell scripts (superseded by CLI + Tuist)

## Consequences

### Positive

- Warnings are now treated as errors, catching potential issues at build time
- Unified testing across platforms with `tuist test --platform macos/ios`
- Better Xcode project management with generated projects
- Cleaner repository with fewer shell scripts
- Foundation for future Tuist features (caching, CI optimization)

### Negative

- Additional tooling dependency (Tuist must be installed)
- Learning curve for contributors unfamiliar with Tuist
- Generated Xcode projects should not be committed (added to `.gitignore`)

### Neutral

- `Package.swift` preserved for external SPM consumers
- Existing module structure unchanged
- Test infrastructure unchanged (Swift Testing + swift-snapshot-testing)

## References

- [GitHub Issue #48](https://github.com/Iron-Ham/IronUI/issues/48)
- [Tuist Documentation](https://docs.tuist.dev)
