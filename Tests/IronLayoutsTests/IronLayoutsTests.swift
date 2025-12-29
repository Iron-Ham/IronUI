import SwiftUI
import Testing
@testable import IronLayouts

// MARK: - IronContainerWidthTests

@Suite("IronContainerWidth")
struct IronContainerWidthTests {

  @Test("narrow case exists")
  func narrowCaseExists() {
    let width = IronContainerWidth.narrow
    // Verify case exists via pattern matching
    if case .narrow = width {
      #expect(Bool(true))
    } else {
      Issue.record("Expected narrow case")
    }
  }

  @Test("standard case exists")
  func standardCaseExists() {
    let width = IronContainerWidth.standard
    if case .standard = width {
      #expect(Bool(true))
    } else {
      Issue.record("Expected standard case")
    }
  }

  @Test("wide case exists")
  func wideCaseExists() {
    let width = IronContainerWidth.wide
    if case .wide = width {
      #expect(Bool(true))
    } else {
      Issue.record("Expected wide case")
    }
  }

  @Test("full case exists")
  func fullCaseExists() {
    let width = IronContainerWidth.full
    if case .full = width {
      #expect(Bool(true))
    } else {
      Issue.record("Expected full case")
    }
  }

  @Test("custom case accepts CGFloat value")
  func customCaseAcceptsValue() {
    let width = IronContainerWidth.custom(600)

    if case .custom(let value) = width {
      #expect(value == 600)
    } else {
      Issue.record("Expected custom case")
    }
  }

  @Test("is Sendable")
  func isSendable() {
    let width = IronContainerWidth.standard
    Task {
      // If this compiles, it's Sendable
      _ = width
    }
  }
}

// MARK: - IronContainerPaddingTests

@Suite("IronContainerPadding")
struct IronContainerPaddingTests {

  @Test("none case exists")
  func noneCaseExists() {
    let padding = IronContainerPadding.none
    if case .none = padding {
      #expect(Bool(true))
    } else {
      Issue.record("Expected none case")
    }
  }

  @Test("horizontal case exists")
  func horizontalCaseExists() {
    let padding = IronContainerPadding.horizontal
    if case .horizontal = padding {
      #expect(Bool(true))
    } else {
      Issue.record("Expected horizontal case")
    }
  }

  @Test("all case exists")
  func allCaseExists() {
    let padding = IronContainerPadding.all
    if case .all = padding {
      #expect(Bool(true))
    } else {
      Issue.record("Expected all case")
    }
  }

  @Test("is Sendable")
  func isSendable() {
    let padding = IronContainerPadding.all
    Task {
      _ = padding
    }
  }
}

// MARK: - IronContainerTests

@Suite("IronContainer")
@MainActor
struct IronContainerTests {

  @Test("can be instantiated with defaults")
  func canBeInstantiatedWithDefaults() {
    let container = IronContainer {
      Text("Content")
    }

    _ = container.body
  }

  @Test("can be instantiated with maxWidth")
  func canBeInstantiatedWithMaxWidth() {
    let narrow = IronContainer(maxWidth: .narrow) { Text("Narrow") }
    let standard = IronContainer(maxWidth: .standard) { Text("Standard") }
    let wide = IronContainer(maxWidth: .wide) { Text("Wide") }
    let full = IronContainer(maxWidth: .full) { Text("Full") }
    let custom = IronContainer(maxWidth: .custom(500)) { Text("Custom") }

    _ = narrow.body
    _ = standard.body
    _ = wide.body
    _ = full.body
    _ = custom.body
  }

  @Test("can be instantiated with padding styles")
  func canBeInstantiatedWithPaddingStyles() {
    let none = IronContainer(padding: .none) { Text("None") }
    let horizontal = IronContainer(padding: .horizontal) { Text("Horizontal") }
    let all = IronContainer(padding: .all) { Text("All") }

    _ = none.body
    _ = horizontal.body
    _ = all.body
  }

  @Test("can be instantiated with alignment")
  func canBeInstantiatedWithAlignment() {
    let leading = IronContainer(alignment: .leading) { Text("Leading") }
    let center = IronContainer(alignment: .center) { Text("Center") }
    let trailing = IronContainer(alignment: .trailing) { Text("Trailing") }

    _ = leading.body
    _ = center.body
    _ = trailing.body
  }

  @Test("can be instantiated with all parameters")
  func canBeInstantiatedWithAllParameters() {
    let container = IronContainer(
      maxWidth: .wide,
      padding: .horizontal,
      alignment: .leading,
    ) {
      VStack {
        Text("Title")
        Text("Content")
      }
    }

    _ = container.body
  }
}

// MARK: - IronFlowTests

@Suite("IronFlow")
struct IronFlowTests {

  @Test("can be instantiated with defaults")
  func canBeInstantiatedWithDefaults() {
    let flow = IronFlow()

    // Default values
    #expect(true) // Compilation success
  }

  @Test("can be instantiated with spacing")
  func canBeInstantiatedWithSpacing() {
    let flow = IronFlow(
      horizontalSpacing: 12,
      verticalSpacing: 16,
    )

    _ = flow
  }

  @Test("can be instantiated with alignment")
  func canBeInstantiatedWithAlignment() {
    let leading = IronFlow(alignment: .leading)
    let center = IronFlow(alignment: .center)
    let trailing = IronFlow(alignment: .trailing)

    _ = leading
    _ = center
    _ = trailing
  }

  @Test("CacheData initializes with empty collections")
  func cacheDataInitializesEmpty() {
    let cache = IronFlow.CacheData()

    #expect(cache.rows.isEmpty)
    #expect(cache.sizes.isEmpty)
  }

  @Test("conforms to Layout protocol")
  func conformsToLayoutProtocol() {
    let flow: any Layout = IronFlow()
    _ = flow
  }
}

// MARK: - IronResponsiveStackTests

@Suite("IronResponsiveStack")
@MainActor
struct IronResponsiveStackTests {

  @Test("can be instantiated with defaults")
  func canBeInstantiatedWithDefaults() {
    let stack = IronResponsiveStack {
      Text("Item 1")
      Text("Item 2")
    }

    _ = stack.body
  }

  @Test("can be instantiated with threshold")
  func canBeInstantiatedWithThreshold() {
    let stack = IronResponsiveStack(threshold: 400) {
      Text("Responsive")
    }

    _ = stack.body
  }

  @Test("can be instantiated with spacing")
  func canBeInstantiatedWithSpacing() {
    let stack = IronResponsiveStack(
      horizontalSpacing: 20,
      verticalSpacing: 16,
    ) {
      Text("Spaced")
    }

    _ = stack.body
  }

  @Test("can be instantiated with alignments")
  func canBeInstantiatedWithAlignments() {
    let stack = IronResponsiveStack(
      horizontalAlignment: .top,
      verticalAlignment: .leading,
    ) {
      Text("Aligned")
    }

    _ = stack.body
  }

  @Test("can be instantiated with all parameters")
  func canBeInstantiatedWithAllParameters() {
    let stack = IronResponsiveStack(
      threshold: 500,
      horizontalSpacing: 16,
      verticalSpacing: 12,
      horizontalAlignment: .center,
      verticalAlignment: .center,
    ) {
      Text("Full config")
    }

    _ = stack.body
  }
}

// MARK: - IronAdaptiveStackTests

@Suite("IronAdaptiveStack")
@MainActor
struct IronAdaptiveStackTests {

  @Test("can be instantiated with defaults")
  func canBeInstantiatedWithDefaults() {
    let stack = IronAdaptiveStack {
      Button("Cancel") { }
      Button("Save") { }
    }

    _ = stack.body
  }

  @Test("can be instantiated with spacing")
  func canBeInstantiatedWithSpacing() {
    let stack = IronAdaptiveStack(
      horizontalSpacing: 16,
      verticalSpacing: 8,
    ) {
      Text("A")
      Text("B")
    }

    _ = stack.body
  }

  @Test("can be instantiated with alignments")
  func canBeInstantiatedWithAlignments() {
    let stack = IronAdaptiveStack(
      horizontalAlignment: .top,
      verticalAlignment: .trailing,
    ) {
      Text("Aligned")
    }

    _ = stack.body
  }
}

// MARK: - IronSizeClassStackTests

@Suite("IronSizeClassStack")
@MainActor
struct IronSizeClassStackTests {

  @Test("LayoutDirection cases exist")
  func layoutDirectionCasesExist() {
    let horizontal = IronSizeClassStack<Text>.LayoutDirection.horizontal
    let vertical = IronSizeClassStack<Text>.LayoutDirection.vertical

    // Verify via pattern matching since enum may not conform to Equatable
    if case .horizontal = horizontal {
      #expect(Bool(true))
    } else {
      Issue.record("Expected horizontal case")
    }

    if case .vertical = vertical {
      #expect(Bool(true))
    } else {
      Issue.record("Expected vertical case")
    }
  }

  @Test("LayoutDirection is Sendable")
  func layoutDirectionIsSendable() {
    let direction = IronSizeClassStack<Text>.LayoutDirection.horizontal
    Task {
      _ = direction
    }
  }

  @Test("can be instantiated with defaults")
  func canBeInstantiatedWithDefaults() {
    let stack = IronSizeClassStack {
      Text("Sidebar")
      Text("Content")
    }

    _ = stack.body
  }

  @Test("can be instantiated with layout directions")
  func canBeInstantiatedWithLayoutDirections() {
    let stack = IronSizeClassStack(
      compactLayout: .vertical,
      regularLayout: .horizontal,
    ) {
      Text("Item")
    }

    _ = stack.body
  }

  @Test("can be instantiated with spacing")
  func canBeInstantiatedWithSpacing() {
    let stack = IronSizeClassStack(
      horizontalSpacing: 24,
      verticalSpacing: 16,
    ) {
      Text("Spaced")
    }

    _ = stack.body
  }

  @Test("can be instantiated with all parameters")
  func canBeInstantiatedWithAllParameters() {
    let stack = IronSizeClassStack(
      compactLayout: .horizontal,
      regularLayout: .vertical,
      horizontalSpacing: 20,
      verticalSpacing: 12,
    ) {
      Text("Full config")
    }

    _ = stack.body
  }
}

// MARK: - IronLayoutsIntegrationTests

@Suite("IronLayouts - Integration Scenarios")
@MainActor
struct IronLayoutsIntegrationTests {

  @Test("container with flow layout")
  func containerWithFlowLayout() {
    let view = IronContainer(maxWidth: .standard) {
      IronFlow(horizontalSpacing: 8, verticalSpacing: 8) {
        ForEach(["Tag 1", "Tag 2", "Tag 3"], id: \.self) { tag in
          Text(tag)
        }
      }
    }

    _ = view.body
  }

  @Test("responsive stack in container")
  func responsiveStackInContainer() {
    let view = IronContainer(maxWidth: .wide, padding: .all) {
      IronResponsiveStack(threshold: 600) {
        Text("Left")
        Text("Right")
      }
    }

    _ = view.body
  }

  @Test("size class stack with flow")
  func sizeClassStackWithFlow() {
    let view = IronSizeClassStack {
      IronFlow {
        ForEach(0 ..< 5) { i in
          Text("Item \(i)")
        }
      }
      Text("Detail")
    }

    _ = view.body
  }

  @Test("nested containers")
  func nestedContainers() {
    let view = IronContainer(maxWidth: .wide, padding: .horizontal) {
      VStack {
        IronContainer(maxWidth: .narrow) {
          Text("Narrow section")
        }
        IronContainer(maxWidth: .standard) {
          Text("Standard section")
        }
      }
    }

    _ = view.body
  }
}
