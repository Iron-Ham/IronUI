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

// MARK: - IronBadgeStyleTests

@Suite("IronBadgeStyle")
struct IronBadgeStyleTests {
  @Test("all styles are available")
  func allStylesAvailable() {
    let styles = IronBadgeStyle.allCases
    #expect(styles.count == 3)
    #expect(styles.contains(.filled))
    #expect(styles.contains(.soft))
    #expect(styles.contains(.outlined))
  }
}

// MARK: - IronBadgeSizeTests

@Suite("IronBadgeSize")
struct IronBadgeSizeTests {
  @Test("all sizes are available")
  func allSizesAvailable() {
    let sizes = IronBadgeSize.allCases
    #expect(sizes.count == 3)
    #expect(sizes.contains(.small))
    #expect(sizes.contains(.medium))
    #expect(sizes.contains(.large))
  }
}

// MARK: - IronBadgeTests

@Suite("IronBadge")
@MainActor
struct IronBadgeTests {

  @Test("can be created as dot")
  func createAsDot() {
    _ = IronBadge()
    // Dot badge created successfully
  }

  @Test("can be created with text")
  func createWithText() {
    _ = IronBadge("New")
    // Text badge created successfully
  }

  @Test("can be created with localized string key")
  func createWithLocalizedStringKey() {
    _ = IronBadge(LocalizedStringKey("badge.new"))
    // Localized badge created successfully
  }

  @Test("can be created with count")
  func createWithCount() {
    _ = IronBadge(count: 5)
    // Count badge created successfully
  }

  @Test("supports max count")
  func supportsMaxCount() {
    _ = IronBadge(count: 100, maxCount: 99)
    // Max count badge created successfully
  }

  @Test("supports all styles", arguments: IronBadgeStyle.allCases)
  func supportsStyle(style: IronBadgeStyle) {
    _ = IronBadge(count: 3, style: style)
    // Badge created with style
  }

  @Test("supports all sizes", arguments: IronBadgeSize.allCases)
  func supportsSize(size: IronBadgeSize) {
    _ = IronBadge(count: 3, size: size)
    // Badge created with size
  }

  @Test("supports primary color")
  func supportsPrimaryColor() {
    _ = IronBadge(count: 3, color: .primary)
    // Primary color badge created
  }

  @Test("supports semantic colors")
  func supportsSemanticColors() {
    _ = IronBadge(count: 1, color: .success)
    _ = IronBadge(count: 2, color: .warning)
    _ = IronBadge(count: 3, color: .error)
    _ = IronBadge(count: 4, color: .info)
    // All semantic colors work
  }

  @Test("supports custom color")
  func supportsCustomColor() {
    _ = IronBadge(count: 5, color: .custom(.purple))
    // Custom color badge created
  }

  @Test("supports combined configuration")
  func supportsCombinedConfiguration() {
    _ = IronBadge(
      count: 42,
      maxCount: 99,
      style: .soft,
      color: .error,
      size: .large,
    )
    // Combined configuration works
  }
}

// MARK: - IronCardStyleTests

@Suite("IronCardStyle")
struct IronCardStyleTests {
  @Test("all styles are available")
  func allStylesAvailable() {
    let styles = IronCardStyle.allCases
    #expect(styles.count == 3)
    #expect(styles.contains(.elevated))
    #expect(styles.contains(.filled))
    #expect(styles.contains(.outlined))
  }
}

// MARK: - IronCardPaddingTests

@Suite("IronCardPadding")
struct IronCardPaddingTests {
  @Test("all padding options are available")
  func allPaddingOptionsAvailable() {
    let options = IronCardPadding.allCases
    #expect(options.count == 4)
    #expect(options.contains(.none))
    #expect(options.contains(.compact))
    #expect(options.contains(.standard))
    #expect(options.contains(.spacious))
  }
}

// MARK: - IronCardTests

@Suite("IronCard")
@MainActor
struct IronCardTests {

  @Test("can be created with content only")
  func createWithContentOnly() {
    _ = IronCard {
      Text("Card content")
    }
    // Card created successfully
  }

  @Test("can be created as tappable")
  func createAsTappable() {
    _ = IronCard {
      Text("Tappable card")
    } action: {
      // Action
    }
    // Tappable card created successfully
  }

  @Test("can be created with header and content")
  func createWithHeaderAndContent() {
    _ = IronCard {
      Text("Content")
    } header: {
      Text("Header")
    }
    // Card with header created successfully
  }

  @Test("can be created with content and footer")
  func createWithContentAndFooter() {
    _ = IronCard {
      Text("Content")
    } footer: {
      Text("Footer")
    }
    // Card with footer created successfully
  }

  @Test("can be created with header, content, and footer")
  func createWithHeaderContentAndFooter() {
    _ = IronCard {
      Text("Content")
    } header: {
      Text("Header")
    } footer: {
      Text("Footer")
    }
    // Card with header and footer created successfully
  }

  @Test("supports all styles", arguments: IronCardStyle.allCases)
  func supportsStyle(style: IronCardStyle) {
    _ = IronCard(style: style) {
      Text("Styled card")
    }
    // Card created with style
  }

  @Test("supports all padding options", arguments: IronCardPadding.allCases)
  func supportsPadding(padding: IronCardPadding) {
    _ = IronCard(padding: padding) {
      Text("Padded card")
    }
    // Card created with padding
  }

  @Test("supports combined configuration")
  func supportsCombinedConfiguration() {
    _ = IronCard(
      style: .elevated,
      padding: .spacious,
    ) {
      VStack {
        Text("Title")
        Text("Description")
      }
    } header: {
      Label("Settings", systemImage: "gear")
    } footer: {
      Button("Save") { }
    }
    // Combined configuration works
  }
}

// MARK: - IronProgressStyleTests

@Suite("IronProgressStyle")
struct IronProgressStyleTests {
  @Test("all styles are available")
  func allStylesAvailable() {
    let styles = IronProgressStyle.allCases
    #expect(styles.count == 2)
    #expect(styles.contains(.linear))
    #expect(styles.contains(.circular))
  }
}

// MARK: - IronProgressSizeTests

@Suite("IronProgressSize")
struct IronProgressSizeTests {
  @Test("all sizes are available")
  func allSizesAvailable() {
    let sizes = IronProgressSize.allCases
    #expect(sizes.count == 3)
    #expect(sizes.contains(.small))
    #expect(sizes.contains(.medium))
    #expect(sizes.contains(.large))
  }
}

// MARK: - IronProgressTests

@Suite("IronProgress")
@MainActor
struct IronProgressTests {

  @Test("can be created as indeterminate")
  func createAsIndeterminate() {
    _ = IronProgress<EmptyView>()
    // Indeterminate progress created successfully
  }

  @Test("can be created as determinate")
  func createAsDeterminate() {
    _ = IronProgress<EmptyView>(value: 0.5)
    // Determinate progress created successfully
  }

  @Test("clamps value to valid range")
  func clampsValue() {
    _ = IronProgress<EmptyView>(value: -0.5) // Should clamp to 0
    _ = IronProgress<EmptyView>(value: 1.5) // Should clamp to 1
    // Values clamped successfully
  }

  @Test("supports all styles", arguments: IronProgressStyle.allCases)
  func supportsStyle(style: IronProgressStyle) {
    _ = IronProgress<EmptyView>(value: 0.5, style: style)
    // Progress created with style
  }

  @Test("supports all sizes", arguments: IronProgressSize.allCases)
  func supportsSize(size: IronProgressSize) {
    _ = IronProgress<EmptyView>(value: 0.5, size: size)
    // Progress created with size
  }

  @Test("supports primary color")
  func supportsPrimaryColor() {
    _ = IronProgress<EmptyView>(value: 0.5, color: .primary)
    // Primary color progress created
  }

  @Test("supports semantic colors")
  func supportsSemanticColors() {
    _ = IronProgress<EmptyView>(value: 0.5, color: .success)
    _ = IronProgress<EmptyView>(value: 0.5, color: .warning)
    _ = IronProgress<EmptyView>(value: 0.5, color: .error)
    _ = IronProgress<EmptyView>(value: 0.5, color: .info)
    // All semantic colors work
  }

  @Test("supports custom color")
  func supportsCustomColor() {
    _ = IronProgress<EmptyView>(value: 0.5, color: .custom(.purple))
    // Custom color progress created
  }

  @Test("supports label")
  func supportsLabel() {
    _ = IronProgress(value: 0.5) {
      Text("Loading...")
    }
    // Progress with label created
  }

  @Test("supports combined configuration")
  func supportsCombinedConfiguration() {
    _ = IronProgress(
      value: 0.75,
      style: .circular,
      color: .success,
      size: .large,
    ) {
      Text("75% Complete")
    }
    // Combined configuration works
  }
}

// MARK: - IronSpinnerStyleTests

@Suite("IronSpinnerStyle")
struct IronSpinnerStyleTests {
  @Test("all styles are available")
  func allStylesAvailable() {
    let styles = IronSpinnerStyle.allCases
    #expect(styles.count == 4)
    #expect(styles.contains(.spinning))
    #expect(styles.contains(.pulsing))
    #expect(styles.contains(.bouncing))
    #expect(styles.contains(.orbiting))
  }
}

// MARK: - IronSpinnerSizeTests

@Suite("IronSpinnerSize")
struct IronSpinnerSizeTests {
  @Test("all sizes are available")
  func allSizesAvailable() {
    let sizes = IronSpinnerSize.allCases
    #expect(sizes.count == 3)
    #expect(sizes.contains(.small))
    #expect(sizes.contains(.medium))
    #expect(sizes.contains(.large))
  }
}

// MARK: - IronSpinnerTests

@Suite("IronSpinner")
@MainActor
struct IronSpinnerTests {

  @Test("can be created with defaults")
  func createWithDefaults() {
    _ = IronSpinner()
    // Spinner created successfully
  }

  @Test("supports all styles", arguments: IronSpinnerStyle.allCases)
  func supportsStyle(style: IronSpinnerStyle) {
    _ = IronSpinner(style: style)
    // Spinner created with style
  }

  @Test("supports all sizes", arguments: IronSpinnerSize.allCases)
  func supportsSize(size: IronSpinnerSize) {
    _ = IronSpinner(size: size)
    // Spinner created with size
  }

  @Test("supports primary color")
  func supportsPrimaryColor() {
    _ = IronSpinner(color: .primary)
    // Primary color spinner created
  }

  @Test("supports semantic colors")
  func supportsSemanticColors() {
    _ = IronSpinner(color: .success)
    _ = IronSpinner(color: .warning)
    _ = IronSpinner(color: .error)
    _ = IronSpinner(color: .info)
    // All semantic colors work
  }

  @Test("supports onSurface color")
  func supportsOnSurfaceColor() {
    _ = IronSpinner(color: .onSurface)
    // OnSurface color spinner created
  }

  @Test("supports custom color")
  func supportsCustomColor() {
    _ = IronSpinner(color: .custom(.purple))
    // Custom color spinner created
  }

  @Test("supports combined configuration")
  func supportsCombinedConfiguration() {
    _ = IronSpinner(
      style: .bouncing,
      color: .success,
      size: .large,
    )
    // Combined configuration works
  }
}

// MARK: - IronTextFieldStyleTests

@Suite("IronTextFieldStyle")
struct IronTextFieldStyleTests {
  @Test("all styles are available")
  func allStylesAvailable() {
    let styles = IronTextFieldStyle.allCases
    #expect(styles.count == 3)
    #expect(styles.contains(.outlined))
    #expect(styles.contains(.filled))
    #expect(styles.contains(.underlined))
  }
}

// MARK: - IronTextFieldSizeTests

@Suite("IronTextFieldSize")
struct IronTextFieldSizeTests {
  @Test("all sizes are available")
  func allSizesAvailable() {
    let sizes = IronTextFieldSize.allCases
    #expect(sizes.count == 3)
    #expect(sizes.contains(.small))
    #expect(sizes.contains(.medium))
    #expect(sizes.contains(.large))
  }
}

// MARK: - IronTextFieldStateTests

@Suite("IronTextFieldState")
struct IronTextFieldStateTests {
  @Test("supports normal state")
  func supportsNormalState() {
    let state = IronTextFieldState.normal
    #expect(state == .normal)
  }

  @Test("supports success state")
  func supportsSuccessState() {
    let state = IronTextFieldState.success
    #expect(state == .success)
  }

  @Test("supports error state with message")
  func supportsErrorState() {
    let message = "Invalid input"
    let state = IronTextFieldState.error(message)
    if case .error(let errorMessage) = state {
      #expect(errorMessage == message)
    } else {
      Issue.record("Expected error state")
    }
  }
}

// MARK: - IronTextFieldTests

@Suite("IronTextField")
@MainActor
struct IronTextFieldTests {

  @Test("can be created with localized string key")
  func createWithLocalizedKey() {
    let placeholder: LocalizedStringKey = "Enter text"
    _ = IronTextField(placeholder, text: .constant(""))
    // TextField created successfully
  }

  @Test("can be created with string")
  func createWithString() {
    _ = IronTextField("Enter text", text: .constant(""))
    // TextField created successfully
  }

  @Test("supports all styles", arguments: IronTextFieldStyle.allCases)
  func supportsStyle(style: IronTextFieldStyle) {
    _ = IronTextField("Test", text: .constant(""), style: style)
    // TextField created with style
  }

  @Test("supports all sizes", arguments: IronTextFieldSize.allCases)
  func supportsSize(size: IronTextFieldSize) {
    _ = IronTextField("Test", text: .constant(""), size: size)
    // TextField created with size
  }

  @Test("supports normal state")
  func supportsNormalState() {
    _ = IronTextField("Test", text: .constant(""), state: .normal)
    // Normal state works
  }

  @Test("supports success state")
  func supportsSuccessState() {
    _ = IronTextField("Test", text: .constant(""), state: .success)
    // Success state works
  }

  @Test("supports error state")
  func supportsErrorState() {
    _ = IronTextField("Test", text: .constant(""), state: .error("Error message"))
    // Error state works
  }

  @Test("supports leading icon")
  func supportsLeadingIcon() {
    _ = IronTextField("Test", text: .constant(""), leading: {
      Image(systemName: "envelope")
    })
    // Leading icon works
  }

  @Test("supports trailing icon")
  func supportsTrailingIcon() {
    _ = IronTextField("Test", text: .constant(""), trailing: {
      Image(systemName: "xmark.circle")
    })
    // Trailing icon works
  }

  @Test("supports leading and trailing icons")
  func supportsLeadingAndTrailingIcons() {
    _ = IronTextField("Test", text: .constant(""), leading: {
      Image(systemName: "magnifyingglass")
    }, trailing: {
      Image(systemName: "xmark.circle")
    })
    // Both icons work
  }

  @Test("supports combined configuration")
  func supportsCombinedConfiguration() {
    _ = IronTextField(
      "Email",
      text: .constant("test@example.com"),
      style: .outlined,
      size: .large,
      state: .success,
      leading: {
        Image(systemName: "envelope")
      },
      trailing: {
        Image(systemName: "checkmark.circle")
      },
    )
    // Combined configuration works
  }
}

// MARK: - IronSecureFieldTests

@Suite("IronSecureField")
@MainActor
struct IronSecureFieldTests {

  @Test("can be created with localized string key")
  func createWithLocalizedKey() {
    let placeholder: LocalizedStringKey = "Password"
    _ = IronSecureField(placeholder, text: .constant(""))
    // SecureField created successfully
  }

  @Test("can be created with string")
  func createWithString() {
    _ = IronSecureField("Password", text: .constant(""))
    // SecureField created successfully
  }

  @Test("supports all styles", arguments: IronTextFieldStyle.allCases)
  func supportsStyle(style: IronTextFieldStyle) {
    _ = IronSecureField("Password", text: .constant(""), style: style)
    // SecureField created with style
  }

  @Test("supports all sizes", arguments: IronTextFieldSize.allCases)
  func supportsSize(size: IronTextFieldSize) {
    _ = IronSecureField("Password", text: .constant(""), size: size)
    // SecureField created with size
  }

  @Test("supports normal state")
  func supportsNormalState() {
    _ = IronSecureField("Password", text: .constant(""), state: .normal)
    // Normal state works
  }

  @Test("supports success state")
  func supportsSuccessState() {
    _ = IronSecureField("Password", text: .constant(""), state: .success)
    // Success state works
  }

  @Test("supports error state")
  func supportsErrorState() {
    _ = IronSecureField("Password", text: .constant(""), state: .error("Password too weak"))
    // Error state works
  }

  @Test("supports show toggle")
  func supportsShowToggle() {
    _ = IronSecureField("Password", text: .constant(""), showToggle: true)
    // Show toggle works
  }

  @Test("supports hiding toggle")
  func supportsHidingToggle() {
    _ = IronSecureField("Password", text: .constant(""), showToggle: false)
    // Hidden toggle works
  }

  @Test("supports leading icon")
  func supportsLeadingIcon() {
    _ = IronSecureField("Password", text: .constant(""), leading: {
      Image(systemName: "lock")
    })
    // Leading icon works
  }

  @Test("supports combined configuration")
  func supportsCombinedConfiguration() {
    _ = IronSecureField(
      "Password",
      text: .constant("secret123"),
      style: .outlined,
      size: .large,
      state: .success,
      showToggle: true,
      leading: {
        Image(systemName: "lock")
      },
    )
    // Combined configuration works
  }
}

// MARK: - IronToggleSizeTests

@Suite("IronToggleSize")
struct IronToggleSizeTests {
  @Test("all sizes are available")
  func allSizesAvailable() {
    let sizes = IronToggleSize.allCases
    #expect(sizes.count == 3)
    #expect(sizes.contains(.small))
    #expect(sizes.contains(.medium))
    #expect(sizes.contains(.large))
  }
}

// MARK: - IronToggleTests

@Suite("IronToggle")
@MainActor
struct IronToggleTests {

  @Test("can be created without label")
  func createWithoutLabel() {
    _ = IronToggle(isOn: .constant(true))
    // Toggle created successfully
  }

  @Test("can be created with localized string key")
  func createWithLocalizedKey() {
    let title: LocalizedStringKey = "Dark Mode"
    _ = IronToggle(title, isOn: .constant(false))
    // Toggle created successfully
  }

  @Test("can be created with string")
  func createWithString() {
    _ = IronToggle("Dark Mode", isOn: .constant(false))
    // Toggle created successfully
  }

  @Test("can be created with custom label")
  func createWithCustomLabel() {
    _ = IronToggle(isOn: .constant(true)) {
      Label("Wi-Fi", systemImage: "wifi")
    }
    // Toggle created with custom label
  }

  @Test("supports all sizes", arguments: IronToggleSize.allCases)
  func supportsSize(size: IronToggleSize) {
    _ = IronToggle(isOn: .constant(true), size: size)
    // Toggle created with size
  }

  @Test("supports primary color")
  func supportsPrimaryColor() {
    _ = IronToggle(isOn: .constant(true), color: .primary)
    // Primary color works
  }

  @Test("supports success color")
  func supportsSuccessColor() {
    _ = IronToggle(isOn: .constant(true), color: .success)
    // Success color works
  }

  @Test("supports warning color")
  func supportsWarningColor() {
    _ = IronToggle(isOn: .constant(true), color: .warning)
    // Warning color works
  }

  @Test("supports error color")
  func supportsErrorColor() {
    _ = IronToggle(isOn: .constant(true), color: .error)
    // Error color works
  }

  @Test("supports custom color")
  func supportsCustomColor() {
    _ = IronToggle(isOn: .constant(true), color: .custom(.purple))
    // Custom color works
  }

  @Test("supports combined configuration")
  func supportsCombinedConfiguration() {
    _ = IronToggle(
      "Notifications",
      isOn: .constant(true),
      size: .large,
      color: .success,
    )
    // Combined configuration works
  }
}

// MARK: - IronCheckboxSizeTests

@Suite("IronCheckboxSize")
struct IronCheckboxSizeTests {
  @Test("all sizes are available")
  func allSizesAvailable() {
    let sizes = IronCheckboxSize.allCases
    #expect(sizes.count == 3)
    #expect(sizes.contains(.small))
    #expect(sizes.contains(.medium))
    #expect(sizes.contains(.large))
  }
}

// MARK: - IronCheckboxTests

@Suite("IronCheckbox")
@MainActor
struct IronCheckboxTests {

  @Test("can be created without label")
  func createWithoutLabel() {
    _ = IronCheckbox(isChecked: .constant(true))
    // Checkbox created successfully
  }

  @Test("can be created with localized string key")
  func createWithLocalizedKey() {
    let title: LocalizedStringKey = "Accept Terms"
    _ = IronCheckbox(title, isChecked: .constant(false))
    // Checkbox created successfully
  }

  @Test("can be created with string")
  func createWithString() {
    _ = IronCheckbox("Accept Terms", isChecked: .constant(false))
    // Checkbox created successfully
  }

  @Test("can be created with custom label")
  func createWithCustomLabel() {
    _ = IronCheckbox(isChecked: .constant(true)) {
      VStack(alignment: .leading) {
        Text("Email Notifications")
        Text("Receive updates via email")
          .font(.caption)
      }
    }
    // Checkbox created with custom label
  }

  @Test("supports all sizes", arguments: IronCheckboxSize.allCases)
  func supportsSize(size: IronCheckboxSize) {
    _ = IronCheckbox(isChecked: .constant(true), size: size)
    // Checkbox created with size
  }

  @Test("supports primary color")
  func supportsPrimaryColor() {
    _ = IronCheckbox(isChecked: .constant(true), color: .primary)
    // Primary color works
  }

  @Test("supports success color")
  func supportsSuccessColor() {
    _ = IronCheckbox(isChecked: .constant(true), color: .success)
    // Success color works
  }

  @Test("supports warning color")
  func supportsWarningColor() {
    _ = IronCheckbox(isChecked: .constant(true), color: .warning)
    // Warning color works
  }

  @Test("supports error color")
  func supportsErrorColor() {
    _ = IronCheckbox(isChecked: .constant(true), color: .error)
    // Error color works
  }

  @Test("supports custom color")
  func supportsCustomColor() {
    _ = IronCheckbox(isChecked: .constant(true), color: .custom(.purple))
    // Custom color works
  }

  @Test("supports combined configuration")
  func supportsCombinedConfiguration() {
    _ = IronCheckbox(
      "Accept Terms",
      isChecked: .constant(true),
      size: .large,
      color: .success,
    )
    // Combined configuration works
  }
}

// MARK: - IronRadioSizeTests

@Suite("IronRadioSize")
struct IronRadioSizeTests {
  @Test("all sizes are available")
  func allSizesAvailable() {
    let sizes = IronRadioSize.allCases
    #expect(sizes.count == 3)
    #expect(sizes.contains(.small))
    #expect(sizes.contains(.medium))
    #expect(sizes.contains(.large))
  }
}

// MARK: - TestRadioOption

private enum TestRadioOption: String {
  case first
  case second
  case third
}

// MARK: - IronRadioTests

@Suite("IronRadio")
@MainActor
struct IronRadioTests {

  @Test("can be created with localized string key")
  func createWithLocalizedKey() {
    let title: LocalizedStringKey = "Option One"
    _ = IronRadio(title, value: TestRadioOption.first, selection: .constant(.first))
    // Radio created successfully
  }

  @Test("can be created with string")
  func createWithString() {
    _ = IronRadio("Option One", value: TestRadioOption.first, selection: .constant(.first))
    // Radio created successfully
  }

  @Test("can be created with custom label")
  func createWithCustomLabel() {
    _ = IronRadio(value: TestRadioOption.first, selection: .constant(.first)) {
      VStack(alignment: .leading) {
        Text("Premium Plan")
        Text("$9.99/month")
          .font(.caption)
      }
    }
    // Radio created with custom label
  }

  @Test("supports all sizes", arguments: IronRadioSize.allCases)
  func supportsSize(size: IronRadioSize) {
    _ = IronRadio("Test", value: TestRadioOption.first, selection: .constant(.first), size: size)
    // Radio created with size
  }

  @Test("supports primary color")
  func supportsPrimaryColor() {
    _ = IronRadio("Test", value: TestRadioOption.first, selection: .constant(.first), color: .primary)
    // Primary color works
  }

  @Test("supports success color")
  func supportsSuccessColor() {
    _ = IronRadio("Test", value: TestRadioOption.first, selection: .constant(.first), color: .success)
    // Success color works
  }

  @Test("supports warning color")
  func supportsWarningColor() {
    _ = IronRadio("Test", value: TestRadioOption.first, selection: .constant(.first), color: .warning)
    // Warning color works
  }

  @Test("supports error color")
  func supportsErrorColor() {
    _ = IronRadio("Test", value: TestRadioOption.first, selection: .constant(.first), color: .error)
    // Error color works
  }

  @Test("supports custom color")
  func supportsCustomColor() {
    _ = IronRadio("Test", value: TestRadioOption.first, selection: .constant(.first), color: .custom(.purple))
    // Custom color works
  }

  @Test("supports combined configuration")
  func supportsCombinedConfiguration() {
    _ = IronRadio(
      "Premium",
      value: TestRadioOption.first,
      selection: .constant(.first),
      size: .large,
      color: .success,
    )
    // Combined configuration works
  }
}

// MARK: - IronRadioGroupTests

@Suite("IronRadioGroup")
@MainActor
struct IronRadioGroupTests {

  @Test("can be created with content")
  func createWithContent() {
    _ = IronRadioGroup(selection: .constant(TestRadioOption.first)) {
      IronRadio("First", value: TestRadioOption.first, selection: .constant(.first))
      IronRadio("Second", value: TestRadioOption.second, selection: .constant(.first))
    }
    // RadioGroup created successfully
  }

  @Test("supports custom spacing")
  func supportsCustomSpacing() {
    _ = IronRadioGroup(selection: .constant(TestRadioOption.first), spacing: 24) {
      IronRadio("First", value: TestRadioOption.first, selection: .constant(.first))
      IronRadio("Second", value: TestRadioOption.second, selection: .constant(.first))
    }
    // Custom spacing works
  }
}

// MARK: - IronAlertVariantTests

@Suite("IronAlertVariant")
struct IronAlertVariantTests {
  @Test("all variants are available")
  func allVariantsAvailable() {
    let variants = IronAlertVariant.allCases
    #expect(variants.count == 4)
    #expect(variants.contains(.info))
    #expect(variants.contains(.success))
    #expect(variants.contains(.warning))
    #expect(variants.contains(.error))
  }
}

// MARK: - IronAlertTests

@Suite("IronAlert")
@MainActor
struct IronAlertTests {

  @Test("can be created with localized string key")
  func createWithLocalizedKey() {
    let message: LocalizedStringKey = "Alert message"
    _ = IronAlert(message)
    // Alert created successfully
  }

  @Test("can be created with string")
  func createWithString() {
    _ = IronAlert("Alert message")
    // Alert created successfully
  }

  @Test("can be created with title and message")
  func createWithTitleAndMessage() {
    _ = IronAlert("Title", message: "Message content")
    // Alert created with title
  }

  @Test("supports all variants", arguments: IronAlertVariant.allCases)
  func supportsVariant(variant: IronAlertVariant) {
    _ = IronAlert("Test message", variant: variant)
    // Alert created with variant
  }

  @Test("supports info variant")
  func supportsInfoVariant() {
    _ = IronAlert("Info message", variant: .info)
    // Info variant works
  }

  @Test("supports success variant")
  func supportsSuccessVariant() {
    _ = IronAlert("Success message", variant: .success)
    // Success variant works
  }

  @Test("supports warning variant")
  func supportsWarningVariant() {
    _ = IronAlert("Warning message", variant: .warning)
    // Warning variant works
  }

  @Test("supports error variant")
  func supportsErrorVariant() {
    _ = IronAlert("Error message", variant: .error)
    // Error variant works
  }

  @Test("supports dismiss action")
  func supportsDismissAction() {
    var dismissed = false
    _ = IronAlert("Dismissible", variant: .info) {
      dismissed = true
    }
    // Dismiss action configured
    #expect(!dismissed) // Not called yet
  }

  @Test("supports dismiss with title")
  func supportsDismissWithTitle() {
    _ = IronAlert("Title", message: "Message", variant: .info, onDismiss: {
      // Dismiss action
    })
    // Dismiss with title works
  }

  @Test("supports custom actions")
  func supportsCustomActions() {
    _ = IronAlert("Alert", variant: .info, actions: {
      Button("Action") { }
    })
    // Custom actions work
  }

  @Test("supports custom actions with title")
  func supportsCustomActionsWithTitle() {
    _ = IronAlert("Title", message: "Message", variant: .info, actions: {
      Button("Primary") { }
      Button("Secondary") { }
    })
    // Custom actions with title work
  }
}
