import SnapshotTesting
import SwiftUI
import Testing
@testable import IronUI

// MARK: - IronContainerSnapshotTests

@Suite("IronContainer Snapshots")
struct IronContainerSnapshotTests {

  @Test("Container - Widths")
  @MainActor
  func containerWidths() {
    let view = VStack(spacing: 16) {
      IronContainer(maxWidth: .narrow, padding: .none) {
        IronText("Narrow (480pt)", style: .bodyMedium, color: .primary)
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.red.opacity(0.2))
      }

      IronContainer(maxWidth: .standard, padding: .none) {
        IronText("Standard (720pt)", style: .bodyMedium, color: .primary)
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.orange.opacity(0.2))
      }

      IronContainer(maxWidth: .full, padding: .none) {
        IronText("Full Width", style: .bodyMedium, color: .primary)
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue.opacity(0.2))
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 800)
  }

  @Test("Container - Padding Styles")
  @MainActor
  func containerPaddingStyles() {
    let view = VStack(spacing: 0) {
      IronContainer(maxWidth: .full, padding: .none) {
        IronText("No padding", style: .bodyMedium, color: .primary)
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.red.opacity(0.2))
      }
      .background(Color.gray.opacity(0.1))

      IronDivider()

      IronContainer(maxWidth: .full, padding: .horizontal) {
        IronText("Horizontal padding", style: .bodyMedium, color: .primary)
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.orange.opacity(0.2))
      }
      .background(Color.gray.opacity(0.1))

      IronDivider()

      IronContainer(maxWidth: .full, padding: .all) {
        IronText("Full padding", style: .bodyMedium, color: .primary)
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.green.opacity(0.2))
      }
      .background(Color.gray.opacity(0.1))
    }

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 400)
  }
}

// MARK: - IronFlowSnapshotTests

@Suite("IronFlow Snapshots")
struct IronFlowSnapshotTests {

  @Test("Flow - Basic Tags")
  @MainActor
  func flowBasicTags() {
    let tags = ["Swift", "SwiftUI", "iOS", "macOS", "Xcode", "UIKit", "Combine"]

    let view = IronFlow(horizontalSpacing: 8, verticalSpacing: 8) {
      ForEach(tags, id: \.self) { tag in
        IronChip(tag)
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 300)
  }

  @Test("Flow - Alignment")
  @MainActor
  func flowAlignment() {
    let items = ["One", "Two", "Three", "Four"]

    let view = VStack(spacing: 24) {
      VStack(alignment: .leading, spacing: 4) {
        IronText("Leading", style: .caption, color: .secondary)
        IronFlow(horizontalSpacing: 8, verticalSpacing: 8, alignment: .leading) {
          ForEach(items, id: \.self) { item in
            IronChip(item)
          }
        }
        .background(Color.gray.opacity(0.1))
      }

      VStack(alignment: .leading, spacing: 4) {
        IronText("Center", style: .caption, color: .secondary)
        IronFlow(horizontalSpacing: 8, verticalSpacing: 8, alignment: .center) {
          ForEach(items, id: \.self) { item in
            IronChip(item, variant: .outlined)
          }
        }
        .background(Color.gray.opacity(0.1))
      }

      VStack(alignment: .leading, spacing: 4) {
        IronText("Trailing", style: .caption, color: .secondary)
        IronFlow(horizontalSpacing: 8, verticalSpacing: 8, alignment: .trailing) {
          ForEach(items, id: \.self) { item in
            IronChip(item, variant: .elevated)
          }
        }
        .background(Color.gray.opacity(0.1))
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 200)
  }
}

// MARK: - IronResponsiveStackSnapshotTests

@Suite("IronResponsiveStack Snapshots")
struct IronResponsiveStackSnapshotTests {

  @Test("ResponsiveStack - Horizontal (Wide)")
  @MainActor
  func responsiveStackHorizontal() {
    let view = IronResponsiveStack(threshold: 200) {
      IronCard {
        IronText("Item 1", style: .bodyMedium, color: .primary)
          .padding()
      }
      IronCard {
        IronText("Item 2", style: .bodyMedium, color: .primary)
          .padding()
      }
    }
    .frame(height: 80)
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 400)
  }

  @Test("ResponsiveStack - Vertical (Narrow)")
  @MainActor
  func responsiveStackVertical() {
    let view = IronResponsiveStack(threshold: 400) {
      IronCard {
        IronText("Item 1", style: .bodyMedium, color: .primary)
          .padding()
      }
      IronCard {
        IronText("Item 2", style: .bodyMedium, color: .primary)
          .padding()
      }
    }
    .frame(height: 150)
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 200)
  }
}

// MARK: - IronAdaptiveStackSnapshotTests

@Suite("IronAdaptiveStack Snapshots")
struct IronAdaptiveStackSnapshotTests {

  @Test("AdaptiveStack - Buttons")
  @MainActor
  func adaptiveStackButtons() {
    let view = IronAdaptiveStack(horizontalSpacing: 12, verticalSpacing: 8) {
      IronButton("Cancel", variant: .outlined) { }
      IronButton("Save", variant: .filled) { }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }
}
