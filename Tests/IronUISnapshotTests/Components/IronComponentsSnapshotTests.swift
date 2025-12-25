import SnapshotTesting
import SwiftUI
import Testing
@testable import IronUI

// MARK: - IronAvatarSnapshotTests

@Suite("IronAvatar Snapshots")
struct IronAvatarSnapshotTests {

  @Test("Avatar - Initials")
  @MainActor
  func avatarInitials() {
    let view = HStack(spacing: 16) {
      IronAvatar(name: "John Doe")
      IronAvatar(name: "Alice Smith")
      IronAvatar(name: "Bob")
      IronAvatar(name: "")
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Avatar - Sizes")
  @MainActor
  func avatarSizes() {
    let view = HStack(spacing: 16) {
      IronAvatar(name: "JD", size: .small)
      IronAvatar(name: "JD", size: .medium)
      IronAvatar(name: "JD", size: .large)
      IronAvatar(name: "JD", size: .xlarge)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Avatar - Status Badges")
  @MainActor
  func avatarStatusBadges() {
    let view = HStack(spacing: 16) {
      IronAvatar(name: "Online", size: .large, status: .online)
      IronAvatar(name: "Away", size: .large, status: .away)
      IronAvatar(name: "Busy", size: .large, status: .busy)
      IronAvatar(name: "Offline", size: .large, status: .offline)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Avatar - Inner Borders")
  @MainActor
  func avatarInnerBorders() {
    let view = HStack(spacing: 16) {
      IronAvatar(name: "No Border", size: .large)
      IronAvatar(name: "Solid", size: .large, innerBorder: .solid(color: .black.opacity(0.2)))
      IronAvatar(name: "Gradient", size: .large, innerBorder: .gradient(color: .black, opacity: 0.2))
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Avatar - Custom Badge")
  @MainActor
  func avatarCustomBadge() {
    let view = HStack(spacing: 16) {
      // Full-bleed SF Symbol badge
      IronAvatar(name: "Verified", size: .large) {
        IronAvatarImageBadge {
          Image(systemName: "checkmark.seal.fill")
            .resizable()
            .foregroundStyle(.blue)
        }
      }

      // Badge with colored background
      IronAvatar(name: "Pro User", size: .large) {
        IronAvatarBadge(backgroundColor: .yellow) {
          Image(systemName: "star.fill")
            .resizable()
            .foregroundStyle(.white)
        }
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }
}

// MARK: - IronChipSnapshotTests

@Suite("IronChip Snapshots")
struct IronChipSnapshotTests {

  @Test("Chip - Variants")
  @MainActor
  func chipVariants() {
    let view = HStack(spacing: 8) {
      IronChip("Filled", variant: .filled)
      IronChip("Outlined", variant: .outlined)
      IronChip("Elevated", variant: .elevated)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Chip - Sizes")
  @MainActor
  func chipSizes() {
    let view = HStack(spacing: 8) {
      IronChip("Small", size: .small)
      IronChip("Medium", size: .medium)
      IronChip("Large", size: .large)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Chip - With Icons")
  @MainActor
  func chipWithIcons() {
    let view = HStack(spacing: 8) {
      IronChip("Location", icon: "mappin")
      IronChip("Calendar", icon: "calendar")
      IronChip("Settings", icon: "gear", variant: .outlined)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Chip - Dismissible")
  @MainActor
  func chipDismissible() {
    let view = HStack(spacing: 8) {
      IronChip("Swift") { }
      IronChip("SwiftUI", variant: .outlined) { }
      IronChip("iOS", variant: .elevated) { }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Chip - Selectable States")
  @MainActor
  func chipSelectableStates() {
    let view = HStack(spacing: 8) {
      IronChip("Not Selected", isSelected: .constant(false))
      IronChip("Selected", isSelected: .constant(true))
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }
}

// MARK: - SegmentOption

private enum SegmentOption: String, CaseIterable, CustomStringConvertible {
  case posts
  case photos
  case videos

  var description: String {
    rawValue.capitalized
  }
}

// MARK: - IronSegmentedControlSnapshotTests

@Suite("IronSegmentedControl Snapshots")
struct IronSegmentedControlSnapshotTests {

  @Test("SegmentedControl - Basic")
  @MainActor
  func segmentedControlBasic() {
    let view = IronSegmentedControl(
      selection: .constant(SegmentOption.posts),
      options: SegmentOption.allCases,
    )
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 300)
  }

  @Test("SegmentedControl - Sizes")
  @MainActor
  func segmentedControlSizes() {
    let view = VStack(spacing: 24) {
      IronSegmentedControl(
        selection: .constant(SegmentOption.posts),
        options: SegmentOption.allCases,
        size: .small,
      )
      IronSegmentedControl(
        selection: .constant(SegmentOption.photos),
        options: SegmentOption.allCases,
        size: .medium,
      )
      IronSegmentedControl(
        selection: .constant(SegmentOption.videos),
        options: SegmentOption.allCases,
        size: .large,
      )
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 300)
  }

  @Test("SegmentedControl - Two Options")
  @MainActor
  func segmentedControlTwoOptions() {
    enum Mode: String, CaseIterable, CustomStringConvertible {
      case list, grid
      var description: String {
        rawValue.capitalized
      }
    }

    let view = IronSegmentedControl(
      selection: .constant(Mode.list),
      options: Mode.allCases,
    )
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 200)
  }
}

// MARK: - IronMenuSnapshotTests

@Suite("IronMenu Snapshots")
struct IronMenuSnapshotTests {

  @Test("Menu - Basic Trigger")
  @MainActor
  func menuBasicTrigger() {
    // Snapshot the menu trigger (label) - menu content is a system popover
    let view = IronMenu("Options") {
      IronMenuItem("Edit", icon: "pencil") { }
      IronMenuItem("Delete", icon: "trash", role: .destructive) { }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Menu - Trigger With Icon")
  @MainActor
  func menuTriggerWithIcon() {
    let view = IronMenu("Sort By", icon: "arrow.up.arrow.down") {
      IronMenuItem("Name") { }
      IronMenuItem("Date") { }
      IronMenuItem("Size") { }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Menu - Multiple Triggers")
  @MainActor
  func menuMultipleTriggers() {
    let view = HStack(spacing: 12) {
      IronMenu("Actions") {
        IronMenuItem("Edit") { }
      }
      IronMenu("Filter", icon: "line.3.horizontal.decrease") {
        IronMenuItem("All") { }
      }
      IronMenu("Sort", icon: "arrow.up.arrow.down") {
        IronMenuItem("Name") { }
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }
}

// MARK: - IronSkeletonSnapshotTests

@Suite("IronSkeleton Snapshots")
struct IronSkeletonSnapshotTests {

  @Test("Skeleton - Shapes")
  @MainActor
  func skeletonShapes() {
    let view = VStack(spacing: 24) {
      IronSkeleton(shape: .text(), isAnimated: false)
        .frame(width: 200)

      IronSkeleton(shape: .circle(size: 48), isAnimated: false)

      IronSkeleton(shape: .rectangle(width: 150, height: 100), isAnimated: false)

      IronSkeleton(shape: .rounded(width: 120, height: 40, radius: 8), isAnimated: false)

      IronSkeleton(shape: .capsule(width: 100, height: 32), isAnimated: false)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Skeleton - Text Lines")
  @MainActor
  func skeletonTextLines() {
    let view = IronSkeletonText(lines: 3)
      .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 250)
  }

  @Test("Skeleton - Card")
  @MainActor
  func skeletonCard() {
    let view = IronSkeletonCard()
      .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 320)
  }

  @Test("Skeleton - List")
  @MainActor
  func skeletonList() {
    let view = IronSkeletonList(count: 3)
      .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }

}
