import CoreGraphics

// MARK: - IronRadiusTokens

/// Defines the corner radius scale for an IronUI theme.
///
/// Radius tokens provide consistent corner rounding throughout the UI.
/// Larger elements should generally use larger radii for visual balance.
///
/// ## Scale
///
/// | Token | Default Value | Typical Use |
/// |-------|---------------|-------------|
/// | none  | 0pt           | Sharp corners |
/// | sm    | 4pt           | Small badges, chips |
/// | md    | 8pt           | Buttons, inputs |
/// | lg    | 12pt          | Cards, dialogs |
/// | xl    | 16pt          | Large cards |
/// | xxl   | 24pt          | Modals, sheets |
/// | full  | 9999pt        | Pills, circular buttons |
///
/// ## Example
///
/// ```swift
/// RoundedRectangle(cornerRadius: theme.radii.md)
///   .fill(theme.colors.surface)
/// ```
public protocol IronRadiusTokens: Sendable {

  /// No corner radius (sharp corners).
  var none: CGFloat { get }

  /// Small radius for compact elements.
  var sm: CGFloat { get }

  /// Medium radius for buttons and inputs.
  var md: CGFloat { get }

  /// Large radius for cards.
  var lg: CGFloat { get }

  /// Extra large radius for prominent cards.
  var xl: CGFloat { get }

  /// Extra extra large radius for sheets and modals.
  var xxl: CGFloat { get }

  /// Full radius for pills and circular elements.
  var full: CGFloat { get }
}

// MARK: - IronDefaultRadiusTokens

/// Default radius tokens providing a modern, soft appearance.
public struct IronDefaultRadiusTokens: IronRadiusTokens {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  public var none: CGFloat {
    0
  }

  public var sm: CGFloat {
    4
  }

  public var md: CGFloat {
    8
  }

  public var lg: CGFloat {
    12
  }

  public var xl: CGFloat {
    16
  }

  public var xxl: CGFloat {
    24
  }

  public var full: CGFloat {
    9999
  }
}
