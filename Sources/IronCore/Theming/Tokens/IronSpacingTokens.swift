import CoreGraphics

// MARK: - IronSpacingTokens

/// Defines the spacing scale for an IronUI theme.
///
/// Spacing tokens follow an 8-point grid system, providing consistent
/// rhythm throughout the interface. Named tokens make it easy to
/// maintain consistency without remembering specific values.
///
/// ## Scale
///
/// | Token | Default Value |
/// |-------|---------------|
/// | none  | 0pt           |
/// | xxxs  | 2pt           |
/// | xxs   | 4pt           |
/// | xs    | 8pt           |
/// | sm    | 12pt          |
/// | md    | 16pt          |
/// | lg    | 24pt          |
/// | xl    | 32pt          |
/// | xxl   | 48pt          |
/// | xxxl  | 64pt          |
///
/// ## Example
///
/// ```swift
/// VStack(spacing: theme.spacing.md) {
///   // Content with 16pt spacing
/// }
/// .padding(theme.spacing.lg)  // 24pt padding
/// ```
public protocol IronSpacingTokens: Sendable {

  /// No spacing (0pt).
  var none: CGFloat { get }

  /// Extra extra extra small spacing (2pt).
  var xxxs: CGFloat { get }

  /// Extra extra small spacing (4pt).
  var xxs: CGFloat { get }

  /// Extra small spacing (8pt).
  var xs: CGFloat { get }

  /// Small spacing (12pt).
  var sm: CGFloat { get }

  /// Medium spacing (16pt) - base unit.
  var md: CGFloat { get }

  /// Large spacing (24pt).
  var lg: CGFloat { get }

  /// Extra large spacing (32pt).
  var xl: CGFloat { get }

  /// Extra extra large spacing (48pt).
  var xxl: CGFloat { get }

  /// Extra extra extra large spacing (64pt).
  var xxxl: CGFloat { get }
}

// MARK: - IronDefaultSpacingTokens

/// Default spacing tokens following an 8-point grid system.
public struct IronDefaultSpacingTokens: IronSpacingTokens {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  public var none: CGFloat {
    0
  }

  public var xxxs: CGFloat {
    2
  }

  public var xxs: CGFloat {
    4
  }

  public var xs: CGFloat {
    8
  }

  public var sm: CGFloat {
    12
  }

  public var md: CGFloat {
    16
  }

  public var lg: CGFloat {
    24
  }

  public var xl: CGFloat {
    32
  }

  public var xxl: CGFloat {
    48
  }

  public var xxxl: CGFloat {
    64
  }
}
