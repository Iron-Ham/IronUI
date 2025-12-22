import SwiftUI

// MARK: - IronTrayDetent

/// Defines the height behavior for an `IronTray`.
///
/// Detents specify the resting positions where a tray can settle.
/// Trays can snap between detents during drag gestures.
///
/// ## Built-in Detents
///
/// ```swift
/// IronTray(detents: [.small, .medium, .large]) {
///   // Content
/// }
/// ```
///
/// ## Custom Detents
///
/// ```swift
/// // Fixed height
/// IronTray(detents: [.height(200), .large]) {
///   // Content
/// }
///
/// // Fraction of screen
/// IronTray(detents: [.fraction(0.3), .fraction(0.8)]) {
///   // Content
/// }
/// ```
public enum IronTrayDetent: Hashable, Sendable {
  /// A small detent, approximately 25% of the available height.
  case small

  /// A medium detent, approximately 50% of the available height.
  case medium

  /// A large detent, approximately 90% of the available height.
  case large

  /// A detent that sizes to fit the content.
  ///
  /// The tray will measure its content and size accordingly,
  /// up to the maximum available height.
  case intrinsic

  /// A detent at a specific fraction of the available height.
  ///
  /// - Parameter fraction: A value between 0 and 1.
  case fraction(CGFloat)

  /// A detent at a fixed height in points.
  ///
  /// - Parameter height: The height in points.
  case height(CGFloat)

  // MARK: Public

  /// Calculates the actual height for this detent.
  ///
  /// - Parameters:
  ///   - availableHeight: The total available height.
  ///   - intrinsicHeight: The measured content height (for `.intrinsic`).
  /// - Returns: The calculated height in points.
  public func resolvedHeight(
    availableHeight: CGFloat,
    intrinsicHeight: CGFloat,
  ) -> CGFloat {
    switch self {
    case .small:
      availableHeight * 0.25
    case .medium:
      availableHeight * 0.5
    case .large:
      availableHeight * 0.9
    case .intrinsic:
      min(intrinsicHeight, availableHeight * 0.9)
    case .fraction(let fraction):
      availableHeight * min(max(fraction, 0), 1)
    case .height(let height):
      min(height, availableHeight * 0.95)
    }
  }
}

// MARK: Comparable

extension IronTrayDetent: Comparable {
  public static func <(lhs: IronTrayDetent, rhs: IronTrayDetent) -> Bool {
    // Use a reference height for comparison
    let referenceHeight: CGFloat = 1000
    let referenceIntrinsic: CGFloat = 300
    return lhs.resolvedHeight(availableHeight: referenceHeight, intrinsicHeight: referenceIntrinsic)
      < rhs.resolvedHeight(availableHeight: referenceHeight, intrinsicHeight: referenceIntrinsic)
  }
}
