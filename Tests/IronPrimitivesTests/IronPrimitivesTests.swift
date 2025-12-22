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
