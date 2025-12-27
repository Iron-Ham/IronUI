import SwiftUI

// MARK: - IronShadowTokens

/// Defines the shadow styles for an IronUI theme.
///
/// Shadows in IronUI use a multi-layer approach for more natural depth,
/// and can be color-tinted for interactive elements.
///
/// ## Elevation Levels
///
/// | Token   | Use Case |
/// |---------|----------|
/// | none    | Flat elements |
/// | sm      | Subtle lift (buttons) |
/// | md      | Cards, dropdowns |
/// | lg      | Modals, dialogs |
/// | xl      | Popovers, sheets |
///
/// ## Example
///
/// ```swift
/// RoundedRectangle(cornerRadius: 12)
///   .fill(Color.white)
///   .modifier(theme.shadows.md)
/// ```
public protocol IronShadowTokens: Sendable {

  /// No shadow.
  var none: IronShadow { get }

  /// Small shadow for subtle elevation.
  var sm: IronShadow { get }

  /// Medium shadow for cards.
  var md: IronShadow { get }

  /// Large shadow for prominent elements.
  var lg: IronShadow { get }

  /// Extra large shadow for overlays.
  var xl: IronShadow { get }
}

// MARK: - IronShadow

/// Configuration for a multi-layer shadow.
public struct IronShadow: Sendable {

  // MARK: Lifecycle

  public init(layers: [Layer]) {
    self.layers = layers
  }

  /// Creates a shadow with a single layer.
  public init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat) {
    layers = [Layer(color: color, radius: radius, x: x, y: y)]
  }

  // MARK: Public

  /// A single shadow layer.
  public struct Layer: Sendable {
    public init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat) {
      self.color = color
      self.radius = radius
      self.x = x
      self.y = y
    }

    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat

  }

  /// An empty shadow with no layers.
  public static var none: IronShadow {
    IronShadow(layers: [])
  }

  /// The shadow layers from bottom to top.
  public let layers: [Layer]

}

// MARK: - IronShadowModifier

/// A view modifier that applies an IronShadow.
///
/// This modifier respects `accessibilityReduceTransparency` by removing
/// shadow layers when the user has enabled that setting, as shadows rely
/// on transparency effects.
public struct IronShadowModifier: ViewModifier {

  // MARK: Lifecycle

  public init(_ shadow: IronShadow) {
    self.shadow = shadow
  }

  // MARK: Public

  public func body(content: Content) -> some View {
    // When reduce transparency is enabled, skip shadows entirely
    // as they rely on transparency effects
    if reduceTransparency {
      content
    } else {
      shadow.layers.reduce(AnyView(content)) { view, layer in
        AnyView(
          view.shadow(
            color: layer.color,
            radius: layer.radius,
            x: layer.x,
            y: layer.y,
          )
        )
      }
    }
  }

  // MARK: Internal

  @Environment(\.accessibilityReduceTransparency) var reduceTransparency

  let shadow: IronShadow

}

extension View {
  /// Applies an IronShadow to the view.
  public func ironShadow(_ shadow: IronShadow) -> some View {
    modifier(IronShadowModifier(shadow))
  }
}

// MARK: - IronDefaultShadowTokens

/// Default shadow tokens with multi-layer shadows for natural depth.
public struct IronDefaultShadowTokens: IronShadowTokens {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  public var none: IronShadow {
    .none
  }

  public var sm: IronShadow {
    IronShadow(layers: [
      .init(color: .black.opacity(0.04), radius: 1, y: 1),
      .init(color: .black.opacity(0.06), radius: 2, y: 2),
    ])
  }

  public var md: IronShadow {
    IronShadow(layers: [
      .init(color: .black.opacity(0.04), radius: 1, y: 1),
      .init(color: .black.opacity(0.08), radius: 4, y: 2),
      .init(color: .black.opacity(0.04), radius: 8, y: 4),
    ])
  }

  public var lg: IronShadow {
    IronShadow(layers: [
      .init(color: .black.opacity(0.04), radius: 2, y: 2),
      .init(color: .black.opacity(0.08), radius: 8, y: 4),
      .init(color: .black.opacity(0.06), radius: 16, y: 8),
    ])
  }

  public var xl: IronShadow {
    IronShadow(layers: [
      .init(color: .black.opacity(0.04), radius: 4, y: 4),
      .init(color: .black.opacity(0.08), radius: 12, y: 8),
      .init(color: .black.opacity(0.08), radius: 24, y: 16),
    ])
  }
}
