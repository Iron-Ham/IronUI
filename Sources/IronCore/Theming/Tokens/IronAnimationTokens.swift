import SwiftUI

// MARK: - IronAnimationTokens

/// Defines the animation timing for an IronUI theme.
///
/// Animation tokens wrap native SwiftUI `Animation` types, providing
/// semantic names that communicate intent rather than implementation.
///
/// ## Design Principle
///
/// We wrap native animations rather than creating custom animation systems.
/// This ensures:
/// - Optimal performance from SwiftUI's animation engine
/// - Compatibility with all SwiftUI animation modifiers
/// - Respect for accessibility settings like Reduce Motion
///
/// ## Duration Tokens
///
/// | Token     | Duration | Use Case |
/// |-----------|----------|----------|
/// | instant   | 0.1s     | Micro-feedback |
/// | fast      | 0.2s     | Button states |
/// | normal    | 0.3s     | Standard transitions |
/// | slow      | 0.5s     | Complex reveals |
/// | dramatic  | 0.8s     | Hero moments |
///
/// ## Animation Tokens
///
/// | Token  | Feel | Use Case |
/// |--------|------|----------|
/// | snappy | Quick, responsive | Button press |
/// | smooth | Standard | Most transitions |
/// | bouncy | Playful | Success states |
/// | gentle | Slow, elegant | Background changes |
///
/// ## Example
///
/// ```swift
/// Button("Submit") { }
///   .scaleEffect(isPressed ? 0.95 : 1.0)
///   .animation(theme.animation.snappy, value: isPressed)
/// ```
public protocol IronAnimationTokens: Sendable {

  /// Instant feedback duration (0.1s).
  var instant: Double { get }

  /// Fast transition duration (0.2s).
  var fast: Double { get }

  /// Normal transition duration (0.3s).
  var normal: Double { get }

  /// Slow transition duration (0.5s).
  var slow: Double { get }

  /// Dramatic transition duration (0.8s).
  var dramatic: Double { get }

  /// Quick, responsive animation for immediate feedback.
  var snappy: Animation { get }

  /// Smooth animation for standard transitions.
  var smooth: Animation { get }

  /// Bouncy animation for playful moments.
  var bouncy: Animation { get }

  /// Gentle animation for slow, elegant transitions.
  var gentle: Animation { get }

  /// Ease-out animation for deceleration.
  var easeOut: Animation { get }

  /// Ease-in-out animation for smooth acceleration and deceleration.
  var easeInOut: Animation { get }
}

// MARK: - IronDefaultAnimationTokens

/// Default animation tokens wrapping SwiftUI's native animation system.
public struct IronDefaultAnimationTokens: IronAnimationTokens {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  public var instant: Double {
    0.1
  }

  public var fast: Double {
    0.2
  }

  public var normal: Double {
    0.3
  }

  public var slow: Double {
    0.5
  }

  public var dramatic: Double {
    0.8
  }

  public var snappy: Animation {
    .spring(response: 0.3, dampingFraction: 0.7)
  }

  public var smooth: Animation {
    .spring(response: 0.4, dampingFraction: 0.8)
  }

  public var bouncy: Animation {
    .spring(response: 0.5, dampingFraction: 0.6)
  }

  public var gentle: Animation {
    .spring(response: 0.6, dampingFraction: 0.9)
  }

  public var easeOut: Animation {
    .easeOut(duration: normal)
  }

  public var easeInOut: Animation {
    .easeInOut(duration: normal)
  }
}

// MARK: - Reduce Motion Support

extension View {
  /// Applies animation that respects the Reduce Motion accessibility setting.
  ///
  /// When Reduce Motion is enabled, returns `.none` instead of the provided animation.
  ///
  /// - Parameters:
  ///   - animation: The animation to apply when Reduce Motion is disabled.
  ///   - value: The value to monitor for changes.
  /// - Returns: A view with accessibility-aware animation.
  public func accessibleAnimation(
    _ animation: Animation?,
    value: some Equatable,
  ) -> some View {
    modifier(AccessibleAnimationModifier(animation: animation, value: value))
  }
}

// MARK: - AccessibleAnimationModifier

private struct AccessibleAnimationModifier<V: Equatable>: ViewModifier {
  let animation: Animation?
  let value: V

  func body(content: Content) -> some View {
    content.animation(reduceMotion ? nil : animation, value: value)
  }

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

}
