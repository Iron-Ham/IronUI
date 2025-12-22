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
  @Test("default theme initializes")
  func defaultThemeInitializes() {
    let theme = IronDefaultTheme()
    #expect(theme.colors is IronDefaultColorTokens)
    #expect(theme.typography is IronDefaultTypographyTokens)
    #expect(theme.spacing is IronDefaultSpacingTokens)
    #expect(theme.radii is IronDefaultRadiusTokens)
    #expect(theme.shadows is IronDefaultShadowTokens)
    #expect(theme.animation is IronDefaultAnimationTokens)
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
