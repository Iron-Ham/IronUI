# ADR-0005: Testing Strategy

## Status

Accepted

## Context

IronUI needs comprehensive testing to ensure:

1. Components behave correctly
2. Visual appearance is consistent
3. Regressions are caught early
4. Cross-platform compatibility

## Decision

Implement a multi-layered testing strategy:

### 1. Unit Tests (Swift Testing)

Use Swift Testing framework (not XCTestCase) for all unit tests:

```swift
import Testing
@testable import IronPrimitives

@Suite("IronButton")
struct IronButtonTests {
    @Test("respects disabled state")
    func disabledState() {
        // Test implementation
    }

    @Test("all variants render", arguments: IronButtonVariant.allCases)
    func variants(variant: IronButtonVariant) {
        // Parameterized test
    }
}
```

**Coverage targets:**
- IronCore: 90%+
- IronPrimitives: 80%+
- Other modules: 75%+

### 2. Snapshot Tests (PointFree swift-snapshot-testing)

Use PointFree's snapshot testing for visual regression:

```swift
import XCTest
import SnapshotTesting
@testable import IronPrimitives

final class ButtonSnapshotTests: XCTestCase {
    func testButtonVariants() {
        let view = VStack {
            ForEach(IronButtonVariant.allCases, id: \.self) { variant in
                IronButton("Button", variant: variant) { }
            }
        }
        assertSnapshot(of: view, as: .image)
    }
}
```

**Snapshot requirements:**
- All component variants
- Light and dark mode
- Different size classes (where applicable)
- Accessibility sizes (Dynamic Type)

### 3. Accessibility Audits

Integrate accessibility testing into CI:

- Use Xcode's accessibility audit APIs
- Test for proper traits, labels, and hints
- Verify contrast ratios programmatically

### 4. Integration Tests

Test module integration and umbrella exports:

```swift
@Suite("IronUI Integration")
struct IronUIIntegrationTests {
    @Test("umbrella module exposes all submodules")
    func umbrellaModuleWorks() {
        // Verify all modules accessible
    }
}
```

### Future: Demo App Catalogue

When the demo app is built, use Emerge's SnapshotPreviews for:

- Component gallery generation
- Automated preview testing
- Visual documentation

## Consequences

### Positive

- Swift Testing provides modern, expressive test syntax
- Snapshot tests catch visual regressions
- Parameterized tests reduce boilerplate
- Clear coverage targets

### Negative

- Snapshot tests can be brittle with rendering differences
- Need to maintain snapshot baselines
- Swift Testing is newer, less tooling support

### Neutral

- XCTest still required for snapshot tests (PointFree limitation)
- CI configuration needed for both frameworks

## Alternatives Considered

### XCTest Only

Use XCTestCase for everything. More established but verbose syntax.

### ViewInspector for Unit Tests

Use ViewInspector to inspect SwiftUI view hierarchies. Adds complexity, can be fragile.

## References

- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)
- [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing)
- [SnapshotPreviews](https://github.com/EmergeTools/SnapshotPreviews)
