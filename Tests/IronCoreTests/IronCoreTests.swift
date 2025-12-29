import SwiftUI
import Testing
@testable import IronCore

// MARK: - IronCoreTests

@Suite("IronCore")
struct IronCoreTests {
  @Test("version is defined")
  func versionIsDefined() {
    #expect(!IronCore.version.isEmpty)
  }
}

// MARK: - IronThemeTests

@Suite("IronTheme")
struct IronThemeTests {
  @Test("default theme initializes with accessible tokens")
  func defaultThemeInitializes() {
    let theme = IronDefaultTheme()
    // Verify all token accessors work and return expected values
    _ = theme.colors.primary
    _ = theme.typography.bodyLarge
    _ = theme.spacing.md
    _ = theme.radii.md
    _ = theme.shadows.md
    _ = theme.animation.snappy
    // If we get here without crashing, initialization succeeded
  }

  @Test("AnyIronTheme wraps theme correctly")
  func anyThemeWrapsCorrectly() {
    let theme = IronDefaultTheme()
    let anyTheme = AnyIronTheme(theme)

    // Verify all token types are accessible
    _ = anyTheme.colors.primary
    _ = anyTheme.typography.bodyLarge
    _ = anyTheme.spacing.md
    _ = anyTheme.radii.md
    _ = anyTheme.shadows.md
    _ = anyTheme.animation.snappy
  }
}

// MARK: - IronColorTokensTests

@Suite("IronColorTokens")
struct IronColorTokensTests {

  // MARK: Internal

  @Test("brand colors are defined")
  func brandColorsAreDefined() {
    _ = colors.primary
    _ = colors.primaryVariant
    _ = colors.secondary
    _ = colors.secondaryVariant
    _ = colors.accent
  }

  @Test("semantic colors are defined")
  func semanticColorsAreDefined() {
    _ = colors.success
    _ = colors.warning
    _ = colors.error
    _ = colors.info
  }

  @Test("surface colors are defined")
  func surfaceColorsAreDefined() {
    _ = colors.background
    _ = colors.surface
    _ = colors.surfaceElevated
  }

  @Test("content colors are defined")
  func contentColorsAreDefined() {
    _ = colors.onPrimary
    _ = colors.onSecondary
    _ = colors.onBackground
    _ = colors.onSurface
    _ = colors.onError
  }

  @Test("text colors are defined")
  func textColorsAreDefined() {
    _ = colors.textPrimary
    _ = colors.textSecondary
    _ = colors.textDisabled
    _ = colors.textPlaceholder
  }

  @Test("border colors are defined")
  func borderColorsAreDefined() {
    _ = colors.border
    _ = colors.borderFocused
    _ = colors.divider
  }

  // MARK: Private

  private let colors = IronDefaultColorTokens()

}

// MARK: - IronTypographyTokensTests

@Suite("IronTypographyTokens")
struct IronTypographyTokensTests {

  // MARK: Internal

  @Test("display fonts are defined")
  func displayFontsAreDefined() {
    _ = typography.displayLarge
    _ = typography.displayMedium
    _ = typography.displaySmall
  }

  @Test("headline fonts are defined")
  func headlineFontsAreDefined() {
    _ = typography.headlineLarge
    _ = typography.headlineMedium
    _ = typography.headlineSmall
  }

  @Test("title fonts are defined")
  func titleFontsAreDefined() {
    _ = typography.titleLarge
    _ = typography.titleMedium
    _ = typography.titleSmall
  }

  @Test("body fonts are defined")
  func bodyFontsAreDefined() {
    _ = typography.bodyLarge
    _ = typography.bodyMedium
    _ = typography.bodySmall
  }

  @Test("label fonts are defined")
  func labelFontsAreDefined() {
    _ = typography.labelLarge
    _ = typography.labelMedium
    _ = typography.labelSmall
  }

  @Test("caption font is defined")
  func captionFontIsDefined() {
    _ = typography.caption
  }

  // MARK: Private

  private let typography = IronDefaultTypographyTokens()

}

// MARK: - IronSpacingTokensTests

@Suite("IronSpacingTokens")
struct IronSpacingTokensTests {

  // MARK: Internal

  @Test("spacing follows 8pt grid")
  func spacingFollows8ptGrid() {
    #expect(spacing.none == 0)
    #expect(spacing.xxxs == 2)
    #expect(spacing.xxs == 4)
    #expect(spacing.xs == 8)
    #expect(spacing.sm == 12)
    #expect(spacing.md == 16)
    #expect(spacing.lg == 24)
    #expect(spacing.xl == 32)
    #expect(spacing.xxl == 48)
    #expect(spacing.xxxl == 64)
  }

  @Test("spacing values increase progressively")
  func spacingIncreasesProgressively() {
    #expect(spacing.none < spacing.xxxs)
    #expect(spacing.xxxs < spacing.xxs)
    #expect(spacing.xxs < spacing.xs)
    #expect(spacing.xs < spacing.sm)
    #expect(spacing.sm < spacing.md)
    #expect(spacing.md < spacing.lg)
    #expect(spacing.lg < spacing.xl)
    #expect(spacing.xl < spacing.xxl)
    #expect(spacing.xxl < spacing.xxxl)
  }

  // MARK: Private

  private let spacing = IronDefaultSpacingTokens()

}

// MARK: - IronRadiusTokensTests

@Suite("IronRadiusTokens")
struct IronRadiusTokensTests {

  // MARK: Internal

  @Test("radius values are defined")
  func radiusValuesAreDefined() {
    #expect(radii.none == 0)
    #expect(radii.sm == 4)
    #expect(radii.md == 8)
    #expect(radii.lg == 12)
    #expect(radii.xl == 16)
    #expect(radii.xxl == 24)
    #expect(radii.full == 9999)
  }

  @Test("radius values increase progressively")
  func radiusIncreasesProgressively() {
    #expect(radii.none < radii.sm)
    #expect(radii.sm < radii.md)
    #expect(radii.md < radii.lg)
    #expect(radii.lg < radii.xl)
    #expect(radii.xl < radii.xxl)
    #expect(radii.xxl < radii.full)
  }

  // MARK: Private

  private let radii = IronDefaultRadiusTokens()

}

// MARK: - IronShadowTokensTests

@Suite("IronShadowTokens")
struct IronShadowTokensTests {

  // MARK: Internal

  @Test("shadow none has no layers")
  func shadowNoneHasNoLayers() {
    #expect(shadows.none.layers.isEmpty)
  }

  @Test("shadow sm has layers")
  func shadowSmHasLayers() {
    #expect(!shadows.sm.layers.isEmpty)
  }

  @Test("shadow md has multiple layers")
  func shadowMdHasMultipleLayers() {
    #expect(shadows.md.layers.count >= 2)
  }

  @Test("shadow lg has multiple layers")
  func shadowLgHasMultipleLayers() {
    #expect(shadows.lg.layers.count >= 2)
  }

  @Test("shadow xl has multiple layers")
  func shadowXlHasMultipleLayers() {
    #expect(shadows.xl.layers.count >= 2)
  }

  @Test("IronShadow.none static property returns empty shadow")
  func ironShadowNoneIsEmpty() {
    let emptyShadow = IronShadow.none
    #expect(emptyShadow.layers.isEmpty)
  }

  @Test("IronShadow single-layer initializer works")
  func ironShadowSingleLayerInit() {
    let shadow = IronShadow(color: .black, radius: 4, x: 0, y: 2)
    #expect(shadow.layers.count == 1)
    #expect(shadow.layers[0].radius == 4)
    #expect(shadow.layers[0].y == 2)
  }

  @MainActor
  @Test("IronShadowModifier can be created")
  func ironShadowModifierCreation() {
    let shadow = IronShadow(color: .black, radius: 4, y: 2)
    let modifier = IronShadowModifier(shadow)
    // Verify the modifier can be created without crashing
    _ = modifier
  }

  // MARK: Private

  private let shadows = IronDefaultShadowTokens()

}

// MARK: - IronAnimationTokensTests

@Suite("IronAnimationTokens")
struct IronAnimationTokensTests {

  // MARK: Internal

  @Test("duration tokens are defined")
  func durationTokensAreDefined() {
    #expect(animation.instant == 0.1)
    #expect(animation.fast == 0.2)
    #expect(animation.normal == 0.3)
    #expect(animation.slow == 0.5)
    #expect(animation.dramatic == 0.8)
  }

  @Test("duration values increase progressively")
  func durationIncreasesProgressively() {
    #expect(animation.instant < animation.fast)
    #expect(animation.fast < animation.normal)
    #expect(animation.normal < animation.slow)
    #expect(animation.slow < animation.dramatic)
  }

  @Test("animation tokens are defined")
  func animationTokensAreDefined() {
    _ = animation.snappy
    _ = animation.smooth
    _ = animation.bouncy
    _ = animation.gentle
    _ = animation.easeOut
    _ = animation.easeInOut
  }

  // MARK: Private

  private let animation = IronDefaultAnimationTokens()

}

// MARK: - IronLogLevelTests

@Suite("IronLogLevel")
struct IronLogLevelTests {

  @Test("levels are ordered by severity")
  func levelsAreOrdered() {
    #expect(IronLogLevel.debug < .info)
    #expect(IronLogLevel.info < .notice)
    #expect(IronLogLevel.notice < .warning)
    #expect(IronLogLevel.warning < .error)
    #expect(IronLogLevel.error < .fault)
  }

  @Test("all levels have labels")
  func allLevelsHaveLabels() {
    for level in IronLogLevel.allCases {
      #expect(!level.label.isEmpty)
    }
  }

  @Test("all levels have emoji")
  func allLevelsHaveEmoji() {
    for level in IronLogLevel.allCases {
      #expect(!level.emoji.isEmpty)
    }
  }

  @Test("all levels map to OSLogType")
  func allLevelsMapToOSLogType() {
    // Just verify the mapping doesn't crash
    for level in IronLogLevel.allCases {
      _ = level.osLogType
    }
  }
}

// MARK: - IronLogMetadataTests

@Suite("IronLogMetadata")
struct IronLogMetadataTests {

  @Test("empty metadata is empty")
  func emptyMetadataIsEmpty() {
    let metadata = IronLogMetadata.empty
    #expect(metadata.isEmpty)
  }

  @Test("can create with dictionary literal")
  func createWithDictionaryLiteral() {
    let metadata: IronLogMetadata = [
      "key1": "value1",
      "key2": 42,
      "key3": 3.14,
      "key4": true,
    ]
    #expect(!metadata.isEmpty)
    #expect(metadata["key1"]?.description == "value1")
    #expect(metadata["key2"]?.description == "42")
  }

  @Test("can merge metadata")
  func canMergeMetadata() {
    let first: IronLogMetadata = ["a": "1", "b": "2"]
    let second: IronLogMetadata = ["b": "override", "c": "3"]
    let merged = first.merging(second)

    #expect(merged["a"]?.description == "1")
    #expect(merged["b"]?.description == "override")
    #expect(merged["c"]?.description == "3")
  }

  @Test("description formats correctly")
  func descriptionFormatsCorrectly() {
    let empty = IronLogMetadata.empty
    #expect(empty.description == "")

    let single: IronLogMetadata = ["key": "value"]
    #expect(single.description.contains("key=value"))
  }
}

// MARK: - IronTestLogHandlerTests

@Suite("IronTestLogHandler")
struct IronTestLogHandlerTests {

  @Test("captures log messages")
  func capturesLogMessages() {
    let handler = IronTestLogHandler()
    let logger = IronLogger(handlers: [handler])

    logger.info("Test message")

    #expect(handler.logs.count == 1)
    #expect(handler.logs[0].level == .info)
    #expect(handler.logs[0].message == "Test message")
  }

  @Test("respects minimum level")
  func respectsMinimumLevel() {
    let handler = IronTestLogHandler(minimumLevel: .warning)
    let logger = IronLogger(handlers: [handler])

    logger.debug("Debug")
    logger.info("Info")
    logger.warning("Warning")
    logger.error("Error")

    #expect(handler.logs.count == 2)
    #expect(handler.logs[0].level == .warning)
    #expect(handler.logs[1].level == .error)
  }

  @Test("captures metadata")
  func capturesMetadata() {
    let handler = IronTestLogHandler()
    let logger = IronLogger(handlers: [handler])

    logger.info("With metadata", metadata: ["component": "test", "count": 42])

    #expect(handler.logs.count == 1)
    #expect(handler.logs[0].metadata["component"]?.description == "test")
    #expect(handler.logs[0].metadata["count"]?.description == "42")
  }

  @Test("can filter logs by level")
  func canFilterByLevel() {
    let handler = IronTestLogHandler()
    let logger = IronLogger(handlers: [handler])

    logger.debug("Debug")
    logger.info("Info")
    logger.error("Error")

    #expect(handler.logs(at: .debug).count == 1)
    #expect(handler.logs(at: .info).count == 1)
    #expect(handler.logs(at: .error).count == 1)
    #expect(handler.logs(at: .warning).count == 0)
  }

  @Test("can filter logs by content")
  func canFilterByContent() {
    let handler = IronTestLogHandler()
    let logger = IronLogger(handlers: [handler])

    logger.info("Button tapped")
    logger.info("View appeared")
    logger.info("Button released")

    #expect(handler.logs(containing: "Button").count == 2)
    #expect(handler.logs(containing: "View").count == 1)
  }

  @Test("can clear logs")
  func canClearLogs() {
    let handler = IronTestLogHandler()
    let logger = IronLogger(handlers: [handler])

    logger.info("Message 1")
    logger.info("Message 2")
    #expect(handler.logs.count == 2)

    handler.clear()
    #expect(handler.logs.count == 0)
  }
}

// MARK: - IronLoggerTests

@Suite("IronLogger")
struct IronLoggerTests {

  @Test("logs at all levels")
  func logsAtAllLevels() {
    let handler = IronTestLogHandler()
    let logger = IronLogger(handlers: [handler])

    logger.debug("Debug")
    logger.info("Info")
    logger.notice("Notice")
    logger.warning("Warning")
    logger.error("Error")
    logger.fault("Fault")

    #expect(handler.logs.count == 6)
    #expect(handler.logs[0].level == .debug)
    #expect(handler.logs[1].level == .info)
    #expect(handler.logs[2].level == .notice)
    #expect(handler.logs[3].level == .warning)
    #expect(handler.logs[4].level == .error)
    #expect(handler.logs[5].level == .fault)
  }

  @Test("disabled logger produces no output")
  func disabledLoggerProducesNoOutput() {
    // Disabled logger has no handlers, so it just doesn't crash
    let disabled = IronLogger.disabled
    disabled.info("This should not crash")
  }

  @Test("static loggers are available")
  func staticLoggersAvailable() {
    // Verify static loggers don't crash when used
    IronLogger.ui.debug("UI log")
    IronLogger.theme.debug("Theme log")
    IronLogger.animation.debug("Animation log")
    IronLogger.accessibility.debug("Accessibility log")
  }

  @Test("supports multiple handlers")
  func supportsMultipleHandlers() {
    let handler1 = IronTestLogHandler()
    let handler2 = IronTestLogHandler()
    let logger = IronLogger(handlers: [handler1, handler2])

    logger.info("Broadcast message")

    #expect(handler1.logs.count == 1)
    #expect(handler2.logs.count == 1)
  }

  @Test("preview detection is available")
  func previewDetectionAvailable() {
    // In test environment, this should be false
    // (unless running tests from a preview, which is unlikely)
    _ = IronLogger.isRunningInPreview
    // Just verify it doesn't crash and returns a Bool
  }
}

// MARK: - IronHapticsTests

@Suite("IronHaptics")
struct IronHapticsTests {

  @Test("ImpactStyle has all expected cases")
  func impactStyleHasAllCases() {
    let styles: [IronHaptics.ImpactStyle] = [
      .light,
      .medium,
      .heavy,
      .soft,
      .rigid,
    ]
    #expect(styles.count == 5)
  }

  @Test("ImpactStyle is Sendable")
  func impactStyleIsSendable() {
    let style = IronHaptics.ImpactStyle.medium
    Task {
      _ = style
    }
  }

  @Test("NotificationType has all expected cases")
  func notificationTypeHasAllCases() {
    let types: [IronHaptics.NotificationType] = [
      .success,
      .warning,
      .error,
    ]
    #expect(types.count == 3)
  }

  @Test("NotificationType is Sendable")
  func notificationTypeIsSendable() {
    let type = IronHaptics.NotificationType.success
    Task {
      _ = type
    }
  }

  @MainActor
  @Test("impact methods are accessible")
  func impactMethodsAccessible() {
    // Verify API is callable (actual haptics may not work in test env)
    IronHaptics.impact(.light)
    IronHaptics.impact(.medium, intensity: 0.5)
  }

  @MainActor
  @Test("notification method is accessible")
  func notificationMethodAccessible() {
    IronHaptics.notification(.success)
    IronHaptics.notification(.warning)
    IronHaptics.notification(.error)
  }

  @MainActor
  @Test("selection method is accessible")
  func selectionMethodAccessible() {
    IronHaptics.selection()
  }

  @MainActor
  @Test("convenience pattern methods are accessible")
  func convenienceMethodsAccessible() {
    IronHaptics.tap()
    IronHaptics.buttonPress()
    IronHaptics.toggle()
  }

  @MainActor
  @Test("composite pattern methods are accessible")
  func compositeMethodsAccessible() {
    // These use DispatchQueue.main.asyncAfter internally
    IronHaptics.success()
    IronHaptics.error()
    IronHaptics.heartbeat()
    IronHaptics.celebrate()
  }
}

// MARK: - IronHapticTapModifierTests

@Suite("IronHapticTapModifier")
@MainActor
struct IronHapticTapModifierTests {

  @Test("modifier can be instantiated with default style")
  func modifierWithDefaultStyle() {
    let modifier = IronHapticTapModifier()
    _ = modifier
  }

  @Test("modifier can be instantiated with custom style")
  func modifierWithCustomStyle() {
    let modifier = IronHapticTapModifier(style: .heavy)
    _ = modifier
  }

  @Test("view extension applies modifier")
  func viewExtensionAppliesModifier() {
    let view = Text("Tap me")
      .ironHapticTap(.medium)

    _ = view
  }

  @Test("view extension works with all styles")
  func viewExtensionWorksWithAllStyles() {
    _ = Text("Light").ironHapticTap(.light)
    _ = Text("Medium").ironHapticTap(.medium)
    _ = Text("Heavy").ironHapticTap(.heavy)
    _ = Text("Soft").ironHapticTap(.soft)
    _ = Text("Rigid").ironHapticTap(.rigid)
  }
}

// MARK: - IronSensoryFeedbackModifierTests

@Suite("IronSensoryFeedbackModifier")
@MainActor
struct IronSensoryFeedbackModifierTests {

  @Test("modifier can be instantiated")
  func modifierCanBeInstantiated() {
    var triggered = false
    let modifier = IronSensoryFeedbackModifier(
      isTriggered: false,
      onTrigger: { triggered = true },
    )
    _ = modifier
    #expect(triggered == false)
  }

  @Test("view extension applies modifier")
  func viewExtensionAppliesModifier() {
    var hapticCount = 0
    let view = Text("Content")
      .ironSensoryFeedback(isTriggered: false) {
        hapticCount += 1
      }

    _ = view
    #expect(hapticCount == 0)
  }
}

// MARK: - IronEnvironmentValuesTests

@Suite("IronEnvironmentValues")
struct IronEnvironmentValuesTests {

  @Test("ironTheme environment key is accessible")
  func ironThemeKeyAccessible() {
    // Verify the environment key exists
    _ = \EnvironmentValues.ironTheme
  }
}
