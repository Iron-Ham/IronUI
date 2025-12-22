import SwiftUI
import Testing
@testable import IronPrimitives

// MARK: - IronPrimitivesTests

@Suite("IronPrimitives")
struct IronPrimitivesTests {
  @Test("version is defined")
  func versionIsDefined() {
    #expect(!IronPrimitives.version.isEmpty)
  }
}

// MARK: - IronButtonVariantTests

@Suite("IronButtonVariant")
struct IronButtonVariantTests {
  @Test("all variants are available")
  func allVariantsAvailable() {
    let variants = IronButtonVariant.allCases
    #expect(variants.count == 4)
    #expect(variants.contains(.filled))
    #expect(variants.contains(.outlined))
    #expect(variants.contains(.ghost))
    #expect(variants.contains(.elevated))
  }
}

// MARK: - IronButtonSizeTests

@Suite("IronButtonSize")
struct IronButtonSizeTests {
  @Test("all sizes are available")
  func allSizesAvailable() {
    let sizes = IronButtonSize.allCases
    #expect(sizes.count == 3)
    #expect(sizes.contains(.small))
    #expect(sizes.contains(.medium))
    #expect(sizes.contains(.large))
  }
}

// MARK: - IronButtonTests

@Suite("IronButton")
@MainActor
struct IronButtonTests {

  @Test("can be created with string title")
  func createWithStringTitle() {
    _ = IronButton("Test") { }
    // Button created successfully
  }

  @Test("can be created with localized string key")
  func createWithLocalizedStringKey() {
    _ = IronButton(LocalizedStringKey("test.button.title")) { }
    // Button created successfully
  }

  @Test("can be created with custom label")
  func createWithCustomLabel() {
    _ = IronButton {
      // action
    } label: {
      HStack {
        Image(systemName: "star")
        Text("Custom")
      }
    }
    // Button created successfully
  }

  @Test("supports all variants", arguments: IronButtonVariant.allCases)
  func supportsVariant(variant: IronButtonVariant) {
    _ = IronButton("Test", variant: variant) { }
    // Button created successfully with variant
  }

  @Test("supports all sizes", arguments: IronButtonSize.allCases)
  func supportsSize(size: IronButtonSize) {
    _ = IronButton("Test", size: size) { }
    // Button created successfully with size
  }

  @Test("supports full width mode")
  func supportsFullWidth() {
    _ = IronButton("Test", isFullWidth: true) { }
    // Button created successfully with full width
  }

  @Test("supports combined configuration")
  func supportsCombinedConfiguration() {
    _ = IronButton(
      "Test",
      variant: .elevated,
      size: .large,
      isFullWidth: true,
    ) { }
    // Button created successfully with all options
  }
}

// MARK: - IronTextStyleTests

@Suite("IronTextStyle")
struct IronTextStyleTests {
  @Test("all styles are available")
  func allStylesAvailable() {
    let styles = IronTextStyle.allCases
    #expect(styles.count == 16)
    #expect(styles.contains(.displayLarge))
    #expect(styles.contains(.bodyMedium))
    #expect(styles.contains(.caption))
  }
}

// MARK: - IronTextTests

@Suite("IronText")
@MainActor
struct IronTextTests {

  @Test("can be created with string")
  func createWithString() {
    _ = IronText("Hello, World!")
    // Text created successfully
  }

  @Test("can be created with localized string key")
  func createWithLocalizedStringKey() {
    _ = IronText(LocalizedStringKey("test.text"))
    // Text created successfully
  }

  @Test("supports all styles", arguments: IronTextStyle.allCases)
  func supportsStyle(style: IronTextStyle) {
    _ = IronText("Test", style: style)
    // Text created successfully with style
  }

  @Test("supports primary color")
  func supportsPrimaryColor() {
    _ = IronText("Test", color: .primary)
    // Text created with primary color
  }

  @Test("supports secondary color")
  func supportsSecondaryColor() {
    _ = IronText("Test", color: .secondary)
    // Text created with secondary color
  }

  @Test("supports semantic colors")
  func supportsSemanticColors() {
    _ = IronText("Success", color: .success)
    _ = IronText("Warning", color: .warning)
    _ = IronText("Error", color: .error)
    _ = IronText("Info", color: .info)
    // All semantic colors work
  }

  @Test("supports custom color")
  func supportsCustomColor() {
    _ = IronText("Custom", color: .custom(.purple))
    // Custom color works
  }

  @Test("supports combined configuration")
  func supportsCombinedConfiguration() {
    _ = IronText("Test", style: .headlineLarge, color: .primary)
    // Combined configuration works
  }
}

// MARK: - IronIconSizeTests

@Suite("IronIconSize")
struct IronIconSizeTests {
  @Test("all sizes are available")
  func allSizesAvailable() {
    let sizes = IronIconSize.allCases
    #expect(sizes.count == 5)
    #expect(sizes.contains(.xSmall))
    #expect(sizes.contains(.small))
    #expect(sizes.contains(.medium))
    #expect(sizes.contains(.large))
    #expect(sizes.contains(.xLarge))
  }
}

// MARK: - IronIconTests

@Suite("IronIcon")
@MainActor
struct IronIconTests {

  @Test("can be created with SF Symbol")
  func createWithSFSymbol() {
    _ = IronIcon(systemName: "star.fill")
    // Icon created successfully
  }

  @Test("can be created with custom image name")
  func createWithCustomImage() {
    _ = IronIcon("customIcon", bundle: nil)
    // Icon created successfully (image may not exist, but init works)
  }

  @Test("supports all sizes", arguments: IronIconSize.allCases)
  func supportsSize(size: IronIconSize) {
    _ = IronIcon(systemName: "star", size: size)
    // Icon created successfully with size
  }

  @Test("supports primary color")
  func supportsPrimaryColor() {
    _ = IronIcon(systemName: "star", color: .primary)
    // Icon created with primary color
  }

  @Test("supports semantic colors")
  func supportsSemanticColors() {
    _ = IronIcon(systemName: "checkmark", color: .success)
    _ = IronIcon(systemName: "exclamationmark", color: .warning)
    _ = IronIcon(systemName: "xmark", color: .error)
    _ = IronIcon(systemName: "info", color: .info)
    // All semantic colors work
  }

  @Test("supports accent color")
  func supportsAccentColor() {
    _ = IronIcon(systemName: "star", color: .accent)
    // Accent color works
  }

  @Test("supports custom color")
  func supportsCustomColor() {
    _ = IronIcon(systemName: "star", color: .custom(.purple))
    // Custom color works
  }

  @Test("supports combined configuration")
  func supportsCombinedConfiguration() {
    _ = IronIcon(systemName: "star.fill", size: .large, color: .accent)
    // Combined configuration works
  }
}

// MARK: - IronDividerAxisTests

@Suite("IronDividerAxis")
struct IronDividerAxisTests {
  @Test("all axes are available")
  func allAxesAvailable() {
    let axes = IronDividerAxis.allCases
    #expect(axes.count == 2)
    #expect(axes.contains(.horizontal))
    #expect(axes.contains(.vertical))
  }
}

// MARK: - IronDividerStyleTests

@Suite("IronDividerStyle")
struct IronDividerStyleTests {
  @Test("all styles are available")
  func allStylesAvailable() {
    let styles = IronDividerStyle.allCases
    #expect(styles.count == 4)
    #expect(styles.contains(.subtle))
    #expect(styles.contains(.standard))
    #expect(styles.contains(.prominent))
    #expect(styles.contains(.accent))
  }
}

// MARK: - IronDividerTests

@Suite("IronDivider")
@MainActor
struct IronDividerTests {

  @Test("can be created with defaults")
  func createWithDefaults() {
    _ = IronDivider<EmptyView>()
    // Divider created successfully
  }

  @Test("supports horizontal axis")
  func supportsHorizontalAxis() {
    _ = IronDivider<EmptyView>(axis: .horizontal)
    // Horizontal divider created
  }

  @Test("supports vertical axis")
  func supportsVerticalAxis() {
    _ = IronDivider<EmptyView>(axis: .vertical)
    // Vertical divider created
  }

  @Test("supports all styles", arguments: IronDividerStyle.allCases)
  func supportsStyle(style: IronDividerStyle) {
    _ = IronDivider<EmptyView>(style: style)
    // Divider created successfully with style
  }

  @Test("supports text label")
  func supportsTextLabel() {
    _ = IronDivider(label: "OR")
    // Labeled divider created
  }

  @Test("supports custom label")
  func supportsCustomLabel() {
    _ = IronDivider {
      HStack {
        Image(systemName: "star")
        Text("Custom")
      }
    }
    // Custom labeled divider created
  }

  @Test("supports insets")
  func supportsInsets() {
    _ = IronDivider<EmptyView>(
      insets: EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
    )
    // Divider with insets created
  }

  @Test("supports combined configuration")
  func supportsCombinedConfiguration() {
    _ = IronDivider<EmptyView>(
      axis: .horizontal,
      style: .prominent,
      insets: EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0),
    )
    // Combined configuration works
  }
}

// MARK: - IronContextLinePositionTests

@Suite("IronContextLinePosition")
struct IronContextLinePositionTests {
  @Test("all positions are available")
  func allPositionsAvailable() {
    let positions = IronContextLinePosition.allCases
    #expect(positions.count == 5)
    #expect(positions.contains(.single))
    #expect(positions.contains(.first))
    #expect(positions.contains(.middle))
    #expect(positions.contains(.last))
    #expect(positions.contains(.continuation))
  }
}

// MARK: - IronContextLineStyleTests

@Suite("IronContextLineStyle")
struct IronContextLineStyleTests {
  @Test("all styles are available")
  func allStylesAvailable() {
    let styles = IronContextLineStyle.allCases
    #expect(styles.count == 6)
    #expect(styles.contains(.subtle))
    #expect(styles.contains(.standard))
    #expect(styles.contains(.prominent))
    #expect(styles.contains(.accent))
    #expect(styles.contains(.success))
    #expect(styles.contains(.error))
  }
}

// MARK: - IronContextLineTests

@Suite("IronContextLine")
@MainActor
struct IronContextLineTests {

  @Test("can be created with defaults")
  func createWithDefaults() {
    _ = IronContextLine {
      Text("Content")
    }
    // Context line created successfully
  }

  @Test("supports all positions", arguments: IronContextLinePosition.allCases)
  func supportsPosition(position: IronContextLinePosition) {
    _ = IronContextLine(position: position) {
      Text("Content")
    }
    // Context line created with position
  }

  @Test("supports standard styles")
  func supportsStandardStyles() {
    _ = IronContextLine(style: .subtle) { Text("Subtle") }
    _ = IronContextLine(style: .standard) { Text("Standard") }
    _ = IronContextLine(style: .prominent) { Text("Prominent") }
    _ = IronContextLine(style: .accent) { Text("Accent") }
    _ = IronContextLine(style: .success) { Text("Success") }
    _ = IronContextLine(style: .error) { Text("Error") }
    // All styles work
  }

  @Test("supports custom color")
  func supportsCustomColor() {
    _ = IronContextLine(style: .custom(.purple)) {
      Text("Custom color")
    }
    // Custom color works
  }

  @Test("supports animated reveal")
  func supportsAnimatedReveal() {
    @State var isRevealed = false
    _ = IronContextLine(isRevealed: $isRevealed) {
      Text("Animated content")
    }
    // Animated context line created
  }

  @Test("supports combined configuration")
  func supportsCombinedConfiguration() {
    _ = IronContextLine(position: .last, style: .success) {
      HStack {
        Image(systemName: "checkmark")
        Text("Success")
      }
    }
    // Combined configuration works
  }

  @Test("supports nested context lines")
  func supportsNestedContextLines() {
    _ = IronContextLine(position: .first) {
      VStack {
        Text("Parent")
        IronContextLine(position: .last) {
          Text("Nested child")
        }
      }
    }
    // Nested context lines work
  }
}

// MARK: - IronContextGroupTests

@Suite("IronContextGroup")
@MainActor
struct IronContextGroupTests {

  @Test("can be created with content")
  func createWithContent() {
    _ = IronContextGroup {
      Text("First")
      Text("Second")
      Text("Third")
    }
    // Context group created successfully
  }

  @Test("supports style")
  func supportsStyle() {
    _ = IronContextGroup(style: .accent) {
      Text("Styled item 1")
      Text("Styled item 2")
    }
    // Styled context group created
  }
}
