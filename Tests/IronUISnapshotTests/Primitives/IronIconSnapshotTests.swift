import SnapshotTesting
import SwiftUI
import Testing
@testable import IronUI

// MARK: - IronIcon Snapshot Tests

@Suite("IronIcon Snapshots")
struct IronIconSnapshotTests {

  @Test("Icon - All Sizes")
  @MainActor
  func iconSizes() {
    let view = HStack(spacing: 24) {
      VStack(spacing: 8) {
        IronIcon(systemName: "star.fill", size: .small, color: .primary)
        IronText("Small", style: .labelSmall, color: .secondary)
      }
      VStack(spacing: 8) {
        IronIcon(systemName: "star.fill", size: .medium, color: .primary)
        IronText("Medium", style: .labelSmall, color: .secondary)
      }
      VStack(spacing: 8) {
        IronIcon(systemName: "star.fill", size: .large, color: .primary)
        IronText("Large", style: .labelSmall, color: .secondary)
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Icon - Color Variations")
  @MainActor
  func iconColors() {
    let view = HStack(spacing: 20) {
      IronIcon(systemName: "circle.fill", size: .medium, color: .primary)
      IronIcon(systemName: "circle.fill", size: .medium, color: .secondary)
      IronIcon(systemName: "circle.fill", size: .medium, color: .success)
      IronIcon(systemName: "circle.fill", size: .medium, color: .warning)
      IronIcon(systemName: "circle.fill", size: .medium, color: .error)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Icon - Common System Icons")
  @MainActor
  func iconCommonIcons() {
    let view = HStack(spacing: 16) {
      IronIcon(systemName: "house.fill", size: .medium, color: .primary)
      IronIcon(systemName: "gear", size: .medium, color: .primary)
      IronIcon(systemName: "person.fill", size: .medium, color: .primary)
      IronIcon(systemName: "bell.fill", size: .medium, color: .primary)
      IronIcon(systemName: "heart.fill", size: .medium, color: .primary)
      IronIcon(systemName: "star.fill", size: .medium, color: .primary)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }
}
