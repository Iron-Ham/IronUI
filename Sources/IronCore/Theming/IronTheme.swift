import SwiftUI

// MARK: - IronTheme

/// The root protocol defining a complete IronUI design system.
///
/// An `IronTheme` combines all design tokens (colors, typography, spacing, etc.)
/// into a cohesive package that can be applied throughout your app.
///
/// ## Using a Theme
///
/// Apply a theme using the `ironTheme` environment modifier:
///
/// ```swift
/// ContentView()
///   .ironTheme(IronDefaultTheme())
/// ```
///
/// Access theme tokens in your views:
///
/// ```swift
/// struct MyView: View {
///   @Environment(\.ironTheme) private var theme
///
///   var body: some View {
///     Text("Hello")
///       .font(theme.typography.bodyLarge)
///       .foregroundStyle(theme.colors.textPrimary)
///       .padding(theme.spacing.md)
///   }
/// }
/// ```
///
/// ## Creating a Custom Theme
///
/// Implement `IronTheme` with your own token types:
///
/// ```swift
/// struct MyTheme: IronTheme {
///   var colors: MyColorTokens { MyColorTokens() }
///   var typography: IronDefaultTypographyTokens { IronDefaultTypographyTokens() }
///   // ... other tokens
/// }
/// ```
public protocol IronTheme: Sendable {
  associatedtype Colors: IronColorTokens
  associatedtype Typography: IronTypographyTokens
  associatedtype Spacing: IronSpacingTokens
  associatedtype Radii: IronRadiusTokens
  associatedtype Shadows: IronShadowTokens
  associatedtype Animation: IronAnimationTokens

  /// The color palette for this theme.
  var colors: Colors { get }

  /// The typography scale for this theme.
  var typography: Typography { get }

  /// The spacing scale for this theme.
  var spacing: Spacing { get }

  /// The corner radius scale for this theme.
  var radii: Radii { get }

  /// The shadow styles for this theme.
  var shadows: Shadows { get }

  /// The animation timing for this theme.
  var animation: Animation { get }
}

// MARK: - IronDefaultTheme

/// The default IronUI theme with an opinionated, stylish design.
///
/// This theme embodies the IronUI design philosophy:
/// - Bold, confident colors
/// - Spring-based animations
/// - Generous whitespace
/// - Multi-layer shadows for depth
///
/// Use this theme as-is or as a starting point for customization.
public struct IronDefaultTheme: IronTheme {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  public var colors: IronDefaultColorTokens {
    IronDefaultColorTokens()
  }

  public var typography: IronDefaultTypographyTokens {
    IronDefaultTypographyTokens()
  }

  public var spacing: IronDefaultSpacingTokens {
    IronDefaultSpacingTokens()
  }

  public var radii: IronDefaultRadiusTokens {
    IronDefaultRadiusTokens()
  }

  public var shadows: IronDefaultShadowTokens {
    IronDefaultShadowTokens()
  }

  public var animation: IronDefaultAnimationTokens {
    IronDefaultAnimationTokens()
  }
}

// MARK: - AnyIronTheme

/// A type-erased wrapper for any IronTheme.
///
/// This allows storing themes of different concrete types in the environment.
public struct AnyIronTheme: Sendable {

  // MARK: Lifecycle

  /// Creates a type-erased theme from any `IronTheme`.
  public init(_ theme: some IronTheme) {
    _colors = { theme.colors }
    _typography = { theme.typography }
    _spacing = { theme.spacing }
    _radii = { theme.radii }
    _shadows = { theme.shadows }
    _animation = { theme.animation }
  }

  // MARK: Public

  /// The color palette for this theme.
  public var colors: any IronColorTokens {
    _colors()
  }

  /// The typography scale for this theme.
  public var typography: any IronTypographyTokens {
    _typography()
  }

  /// The spacing scale for this theme.
  public var spacing: any IronSpacingTokens {
    _spacing()
  }

  /// The corner radius scale for this theme.
  public var radii: any IronRadiusTokens {
    _radii()
  }

  /// The shadow styles for this theme.
  public var shadows: any IronShadowTokens {
    _shadows()
  }

  /// The animation timing for this theme.
  public var animation: any IronAnimationTokens {
    _animation()
  }

  // MARK: Private

  private let _colors: @Sendable () -> any IronColorTokens
  private let _typography: @Sendable () -> any IronTypographyTokens
  private let _spacing: @Sendable () -> any IronSpacingTokens
  private let _radii: @Sendable () -> any IronRadiusTokens
  private let _shadows: @Sendable () -> any IronShadowTokens
  private let _animation: @Sendable () -> any IronAnimationTokens

}

extension EnvironmentValues {
  /// The current IronUI theme.
  ///
  /// Access this in your views to use theme tokens:
  ///
  /// ```swift
  /// @Environment(\.ironTheme) private var theme
  /// ```
  @Entry public var ironTheme = AnyIronTheme(IronDefaultTheme())
}

// MARK: - View Extension

extension View {
  /// Applies an IronUI theme to this view and its descendants.
  ///
  /// ```swift
  /// ContentView()
  ///   .ironTheme(MyCustomTheme())
  /// ```
  ///
  /// - Parameter theme: The theme to apply.
  /// - Returns: A view with the theme applied to its environment.
  public func ironTheme(_ theme: some IronTheme) -> some View {
    environment(\.ironTheme, AnyIronTheme(theme))
  }
}
