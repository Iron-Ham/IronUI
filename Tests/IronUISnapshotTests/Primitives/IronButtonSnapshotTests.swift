import SnapshotTesting
import SwiftUI
import Testing
@testable import IronUI

// MARK: - IronButton Snapshot Tests

@Suite("IronButton Snapshots")
struct IronButtonSnapshotTests {

  @Test("Button - All Variants")
  @MainActor
  func buttonVariants() {
    let view = VStack(spacing: 16) {
      IronButton("Filled", variant: .filled) { }
      IronButton("Outlined", variant: .outlined) { }
      IronButton("Ghost", variant: .ghost) { }
      IronButton("Elevated", variant: .elevated) { }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Button - All Sizes")
  @MainActor
  func buttonSizes() {
    let view = VStack(spacing: 16) {
      IronButton("Small", size: .small) { }
      IronButton("Medium", size: .medium) { }
      IronButton("Large", size: .large) { }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Button - Disabled State")
  @MainActor
  func buttonDisabled() {
    let view = VStack(spacing: 16) {
      IronButton("Filled Disabled", variant: .filled) { }
        .disabled(true)
      IronButton("Outlined Disabled", variant: .outlined) { }
        .disabled(true)
      IronButton("Ghost Disabled", variant: .ghost) { }
        .disabled(true)
    }
    .padding()

    // Use fixed width to prevent text truncation
    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 280)
  }

  @Test("Button - Full Width")
  @MainActor
  func buttonFullWidth() {
    let view = VStack(spacing: 16) {
      IronButton("Full Width", variant: .filled, isFullWidth: true) { }
      IronButton("Full Width Outlined", variant: .outlined, isFullWidth: true) { }
    }
    .padding()

    // Full width buttons need a constrained width
    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 320)
  }

  @Test("Button - Custom Label")
  @MainActor
  func buttonCustomLabel() {
    let view = VStack(spacing: 16) {
      IronButton(variant: .filled) { } label: {
        HStack(spacing: 8) {
          Image(systemName: "arrow.up.circle")
          Text("Upload")
        }
      }

      IronButton(variant: .outlined) { } label: {
        HStack(spacing: 8) {
          Image(systemName: "trash")
          Text("Delete")
        }
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Button - Dynamic Type")
  @MainActor
  func buttonDynamicType() {
    let view = IronButton("Submit Form", variant: .filled, size: .medium) { }
      .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.forDevice(.iPhone17Pro))
  }
}
