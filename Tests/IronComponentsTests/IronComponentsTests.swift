import SwiftUI
import Testing
@testable import IronComponents

// MARK: - IronComponentsTests

@Suite("IronComponents")
struct IronComponentsTests {
  @Test("version is defined")
  func versionIsDefined() {
    #expect(!IronComponents.version.isEmpty)
  }
}

// MARK: - IronAvatarSizeTests

@Suite("IronAvatarSize")
struct IronAvatarSizeTests {
  @Test("all sizes are available")
  func allSizesAvailable() {
    let sizes = IronAvatarSize.allCases
    #expect(sizes.count == 4)
    #expect(sizes.contains(.small))
    #expect(sizes.contains(.medium))
    #expect(sizes.contains(.large))
    #expect(sizes.contains(.xlarge))
  }
}

// MARK: - IronAvatarStatusTests

@Suite("IronAvatarStatus")
struct IronAvatarStatusTests {
  @Test("all statuses are available")
  func allStatusesAvailable() {
    let statuses = IronAvatarStatus.allCases
    #expect(statuses.count == 4)
    #expect(statuses.contains(.online))
    #expect(statuses.contains(.away))
    #expect(statuses.contains(.busy))
    #expect(statuses.contains(.offline))
  }

  @Test("statuses have correct raw values")
  func statusRawValues() {
    #expect(IronAvatarStatus.online.rawValue == "online")
    #expect(IronAvatarStatus.away.rawValue == "away")
    #expect(IronAvatarStatus.busy.rawValue == "busy")
    #expect(IronAvatarStatus.offline.rawValue == "offline")
  }
}

// MARK: - IronAvatarTests

@Suite("IronAvatar")
@MainActor
struct IronAvatarTests {

  @Test("can be created with name")
  func createWithName() {
    _ = IronAvatar(name: "John Doe")
    // Avatar created successfully
  }

  @Test("can be created with image")
  func createWithImage() {
    _ = IronAvatar(image: Image(systemName: "person.fill"))
    // Avatar created successfully
  }

  @Test("can be created with URL")
  func createWithURL() throws {
    _ = IronAvatar(url: try #require(URL(string: "https://example.com/avatar.jpg")))
    // Avatar created successfully
  }

  @Test("can be created with URL and fallback name")
  func createWithURLAndFallback() throws {
    _ = IronAvatar(url: try #require(URL(string: "https://example.com/avatar.jpg")), name: "John Doe")
    // Avatar created successfully
  }

  @Test("supports all sizes", arguments: IronAvatarSize.allCases)
  func supportsSize(size: IronAvatarSize) {
    _ = IronAvatar(name: "Test", size: size)
    // Avatar created successfully with size
  }

  @Test("supports all statuses", arguments: IronAvatarStatus.allCases)
  func supportsStatus(status: IronAvatarStatus) {
    _ = IronAvatar(name: "Test", status: status)
    // Avatar created successfully with status
  }

  @Test("supports combined configuration")
  func supportsCombinedConfiguration() {
    _ = IronAvatar(name: "John Doe", size: .large, status: .online)
    // Avatar created successfully with all options
  }
}

// MARK: - IronChipVariantTests

@Suite("IronChipVariant")
struct IronChipVariantTests {
  @Test("all variants are available")
  func allVariantsAvailable() {
    let variants = IronChipVariant.allCases
    #expect(variants.count == 3)
    #expect(variants.contains(.filled))
    #expect(variants.contains(.outlined))
    #expect(variants.contains(.elevated))
  }
}

// MARK: - IronChipSizeTests

@Suite("IronChipSize")
struct IronChipSizeTests {
  @Test("all sizes are available")
  func allSizesAvailable() {
    let sizes = IronChipSize.allCases
    #expect(sizes.count == 3)
    #expect(sizes.contains(.small))
    #expect(sizes.contains(.medium))
    #expect(sizes.contains(.large))
  }
}

// MARK: - IronChipTests

@Suite("IronChip")
@MainActor
struct IronChipTests {

  @Test("can be created with localized string key")
  func createWithLocalizedStringKey() {
    _ = IronChip(LocalizedStringKey("tag"))
    // Chip created successfully
  }

  @Test("can be created with string")
  func createWithString() {
    _ = IronChip("Swift")
    // Chip created successfully
  }

  @Test("can be created with icon")
  func createWithIcon() {
    _ = IronChip("Location", icon: "mappin")
    // Chip created successfully
  }

  @Test("can be created with custom leading icon")
  func createWithCustomIcon() {
    _ = IronChip("Custom") {
      Image(systemName: "star.fill")
    }
    // Chip created successfully
  }

  @Test("can be created as dismissible")
  func createAsDismissible() {
    _ = IronChip("Remove me") {
      // dismiss action
    }
    // Chip created successfully
  }

  @Test("can be created as selectable")
  func createAsSelectable() {
    _ = IronChip("Filter", isSelected: .constant(false))
    // Chip created successfully
  }

  @Test("supports all variants", arguments: IronChipVariant.allCases)
  func supportsVariant(variant: IronChipVariant) {
    _ = IronChip("Test", variant: variant)
    // Chip created successfully with variant
  }

  @Test("supports all sizes", arguments: IronChipSize.allCases)
  func supportsSize(size: IronChipSize) {
    _ = IronChip("Test", size: size)
    // Chip created successfully with size
  }

  @Test("supports combined configuration")
  func supportsCombinedConfiguration() {
    _ = IronChip("Test", icon: "star", variant: .outlined, size: .large) {
      // dismiss action
    }
    // Chip created successfully with all options
  }
}

// MARK: - IronSkeletonShapeTests

@Suite("IronSkeletonShape")
struct IronSkeletonShapeTests {
  @Test("text shape has default width ratio")
  func textShapeDefaultWidthRatio() {
    let shape = IronSkeletonShape.text()
    if case .text(let widthRatio) = shape {
      #expect(widthRatio == 1.0)
    } else {
      Issue.record("Expected text shape")
    }
  }

  @Test("text shape accepts custom width ratio")
  func textShapeCustomWidthRatio() {
    let shape = IronSkeletonShape.text(widthRatio: 0.7)
    if case .text(let widthRatio) = shape {
      #expect(widthRatio == 0.7)
    } else {
      Issue.record("Expected text shape")
    }
  }

  @Test("circle shape stores size")
  func circleShapeStoresSize() {
    let shape = IronSkeletonShape.circle(size: 48)
    if case .circle(let size) = shape {
      #expect(size == 48)
    } else {
      Issue.record("Expected circle shape")
    }
  }

  @Test("rectangle shape stores dimensions")
  func rectangleShapeStoresDimensions() {
    let shape = IronSkeletonShape.rectangle(width: 200, height: 150)
    if case .rectangle(let width, let height) = shape {
      #expect(width == 200)
      #expect(height == 150)
    } else {
      Issue.record("Expected rectangle shape")
    }
  }

  @Test("rounded shape stores dimensions and radius")
  func roundedShapeStoresDimensionsAndRadius() {
    let shape = IronSkeletonShape.rounded(width: 100, height: 20, radius: 4)
    if case .rounded(let width, let height, let radius) = shape {
      #expect(width == 100)
      #expect(height == 20)
      #expect(radius == 4)
    } else {
      Issue.record("Expected rounded shape")
    }
  }

  @Test("capsule shape stores dimensions")
  func capsuleShapeStoresDimensions() {
    let shape = IronSkeletonShape.capsule(width: 80, height: 32)
    if case .capsule(let width, let height) = shape {
      #expect(width == 80)
      #expect(height == 32)
    } else {
      Issue.record("Expected capsule shape")
    }
  }
}

// MARK: - IronSkeletonTests

@Suite("IronSkeleton")
@MainActor
struct IronSkeletonTests {

  @Test("can be created with text shape")
  func createWithTextShape() {
    _ = IronSkeleton(shape: .text())
    // Skeleton created successfully
  }

  @Test("can be created with circle shape")
  func createWithCircleShape() {
    _ = IronSkeleton(shape: .circle(size: 48))
    // Skeleton created successfully
  }

  @Test("can be created with rectangle shape")
  func createWithRectangleShape() {
    _ = IronSkeleton(shape: .rectangle(width: 200, height: 150))
    // Skeleton created successfully
  }

  @Test("can be created with rounded shape")
  func createWithRoundedShape() {
    _ = IronSkeleton(shape: .rounded(width: 100, height: 20, radius: 4))
    // Skeleton created successfully
  }

  @Test("can be created with capsule shape")
  func createWithCapsuleShape() {
    _ = IronSkeleton(shape: .capsule(width: 80, height: 32))
    // Skeleton created successfully
  }

  @Test("can be created without animation")
  func createWithoutAnimation() {
    _ = IronSkeleton(shape: .text(), animated: false)
    // Skeleton created successfully
  }
}

// MARK: - IronSkeletonTextTests

@Suite("IronSkeletonText")
@MainActor
struct IronSkeletonTextTests {

  @Test("can be created with defaults")
  func createWithDefaults() {
    _ = IronSkeletonText()
    // SkeletonText created successfully
  }

  @Test("can be created with custom line count")
  func createWithCustomLineCount() {
    _ = IronSkeletonText(lines: 5)
    // SkeletonText created successfully
  }

  @Test("can be created with custom last line ratio")
  func createWithCustomLastLineRatio() {
    _ = IronSkeletonText(lastLineRatio: 0.5)
    // SkeletonText created successfully
  }

  @Test("can be created with custom spacing")
  func createWithCustomSpacing() {
    _ = IronSkeletonText(spacing: 12)
    // SkeletonText created successfully
  }

  @Test("supports combined configuration")
  func supportsCombinedConfiguration() {
    _ = IronSkeletonText(lines: 4, lastLineRatio: 0.6, spacing: 10)
    // SkeletonText created successfully with all options
  }
}

// MARK: - IronSkeletonCardTests

@Suite("IronSkeletonCard")
@MainActor
struct IronSkeletonCardTests {

  @Test("can be created with defaults")
  func createWithDefaults() {
    _ = IronSkeletonCard()
    // SkeletonCard created successfully
  }

  @Test("can be created with image placeholder")
  func createWithImagePlaceholder() {
    _ = IronSkeletonCard(showImage: true)
    // SkeletonCard created successfully
  }

  @Test("can be created without image placeholder")
  func createWithoutImagePlaceholder() {
    _ = IronSkeletonCard(showImage: false)
    // SkeletonCard created successfully
  }
}

// MARK: - IronSkeletonListTests

@Suite("IronSkeletonList")
@MainActor
struct IronSkeletonListTests {

  @Test("can be created with defaults")
  func createWithDefaults() {
    _ = IronSkeletonList()
    // SkeletonList created successfully
  }

  @Test("can be created with custom count")
  func createWithCustomCount() {
    _ = IronSkeletonList(count: 10)
    // SkeletonList created successfully
  }
}

// MARK: - IronSkeletonListItemTests

@Suite("IronSkeletonListItem")
@MainActor
struct IronSkeletonListItemTests {

  @Test("can be created")
  func create() {
    _ = IronSkeletonListItem()
    // SkeletonListItem created successfully
  }
}

// MARK: - IronSegmentedControlSizeTests

@Suite("IronSegmentedControlSize")
struct IronSegmentedControlSizeTests {
  @Test("all sizes are available")
  func allSizesAvailable() {
    let sizes = IronSegmentedControlSize.allCases
    #expect(sizes.count == 3)
    #expect(sizes.contains(.small))
    #expect(sizes.contains(.medium))
    #expect(sizes.contains(.large))
  }
}

// MARK: - IronSegmentedControlTests

@Suite("IronSegmentedControl")
@MainActor
struct IronSegmentedControlTests {

  // MARK: Internal

  @Test("can be created with options and label builder")
  func createWithOptionsAndLabelBuilder() {
    _ = IronSegmentedControl(
      selection: .constant(TestOption.first),
      options: TestOption.allCases,
    ) { option in
      Text(option.rawValue)
    }
    // SegmentedControl created successfully
  }

  @Test("can be created with string-convertible options")
  func createWithStringConvertibleOptions() {
    _ = IronSegmentedControl(
      selection: .constant(TestOption.first),
      options: TestOption.allCases,
    )
    // SegmentedControl created successfully
  }

  @Test("supports all sizes", arguments: IronSegmentedControlSize.allCases)
  func supportsSize(size: IronSegmentedControlSize) {
    _ = IronSegmentedControl(
      selection: .constant(TestOption.first),
      options: TestOption.allCases,
      size: size,
    )
    // SegmentedControl created successfully with size
  }

  @Test("supports custom label")
  func supportsCustomLabel() {
    _ = IronSegmentedControl(
      selection: .constant(TestOption.first),
      options: TestOption.allCases,
    ) { option in
      HStack {
        Image(systemName: "star")
        Text(option.rawValue)
      }
    }
    // SegmentedControl created successfully with custom label
  }

  // MARK: Private

  private enum TestOption: String, CaseIterable, CustomStringConvertible {
    case first
    case second
    case third

    var description: String {
      rawValue
    }
  }

}

// MARK: - IronMenuTests

@Suite("IronMenu")
@MainActor
struct IronMenuTests {

  @Test("can be created with text label")
  func createWithTextLabel() {
    _ = IronMenu("Options") {
      IronMenuItem("Edit") { }
    }
    // Menu created successfully
  }

  @Test("can be created with icon")
  func createWithIcon() {
    _ = IronMenu("Options", icon: "gear") {
      IronMenuItem("Settings") { }
    }
    // Menu created successfully
  }

  @Test("can be created with custom label")
  func createWithCustomLabel() {
    _ = IronMenu {
      IronMenuItem("Action") { }
    } label: {
      Text("Custom Trigger")
    }
    // Menu created successfully
  }
}

// MARK: - IronMenuItemTests

@Suite("IronMenuItem")
@MainActor
struct IronMenuItemTests {

  @Test("can be created with title")
  func createWithTitle() {
    _ = IronMenuItem("Edit") { }
    // MenuItem created successfully
  }

  @Test("can be created with icon")
  func createWithIcon() {
    _ = IronMenuItem("Edit", icon: "pencil") { }
    // MenuItem created successfully
  }

  @Test("can be created with destructive role")
  func createWithDestructiveRole() {
    _ = IronMenuItem("Delete", icon: "trash", role: .destructive) { }
    // MenuItem created successfully
  }

  @Test("can be created with cancel role")
  func createWithCancelRole() {
    _ = IronMenuItem("Cancel", role: .cancel) { }
    // MenuItem created successfully
  }
}

// MARK: - IronMenuSectionTests

@Suite("IronMenuSection")
@MainActor
struct IronMenuSectionTests {

  @Test("can be created with header")
  func createWithHeader() {
    _ = IronMenuSection("Edit") {
      IronMenuItem("Cut") { }
      IronMenuItem("Copy") { }
    }
    // MenuSection created successfully
  }
}

// MARK: - IronMenuDividerTests

@Suite("IronMenuDivider")
@MainActor
struct IronMenuDividerTests {

  @Test("can be created")
  func create() {
    _ = IronMenuDivider()
    // MenuDivider created successfully
  }
}
