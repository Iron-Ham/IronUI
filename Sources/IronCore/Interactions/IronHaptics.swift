import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - IronHaptics

/// Haptic feedback utilities for tactile interactions.
///
/// Provides a simple API for triggering haptic feedback that
/// aligns with visual animations, like Honkish's synchronized
/// double-tap hearts.
///
/// ## Basic Usage
///
/// ```swift
/// Button("Tap") {
///   IronHaptics.impact(.medium)
///   // perform action
/// }
/// ```
///
/// ## Notification Feedback
///
/// ```swift
/// IronHaptics.notification(.success) // Task completed
/// IronHaptics.notification(.warning) // Attention needed
/// IronHaptics.notification(.error)   // Something went wrong
/// ```
///
/// ## Selection Feedback
///
/// ```swift
/// // In a picker or segmented control
/// IronHaptics.selection()
/// ```
@MainActor
public enum IronHaptics {

  /// Triggers impact haptic feedback.
  ///
  /// Use for physical interactions like button taps,
  /// collisions, or snap-to-grid behaviors.
  ///
  /// - Parameter style: The intensity of the impact.
  public static func impact(_ style: ImpactStyle) {
    #if canImport(UIKit) && !os(watchOS)
    let generator = UIImpactFeedbackGenerator(style: style.uiKitStyle)
    generator.impactOccurred()
    #endif
  }

  /// Triggers impact with custom intensity.
  ///
  /// - Parameters:
  ///   - style: Base impact style.
  ///   - intensity: Intensity multiplier (0.0 to 1.0).
  public static func impact(_ style: ImpactStyle, intensity: CGFloat) {
    #if canImport(UIKit) && !os(watchOS)
    let generator = UIImpactFeedbackGenerator(style: style.uiKitStyle)
    generator.impactOccurred(intensity: intensity)
    #endif
  }

  /// Triggers notification haptic feedback.
  ///
  /// Use for communicating outcomes:
  /// - `.success`: Task completed successfully
  /// - `.warning`: Attention needed
  /// - `.error`: Something went wrong
  ///
  /// - Parameter type: The type of notification.
  public static func notification(_ type: NotificationType) {
    #if canImport(UIKit) && !os(watchOS)
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(type.uiKitType)
    #endif
  }

  /// Triggers selection change haptic feedback.
  ///
  /// Use when the user changes a selection, like
  /// in pickers, segmented controls, or toggles.
  public static func selection() {
    #if canImport(UIKit) && !os(watchOS)
    let generator = UISelectionFeedbackGenerator()
    generator.selectionChanged()
    #endif
  }

  /// Haptic pattern for a successful action.
  ///
  /// Combines a medium impact with success notification.
  public static func success() {
    impact(.medium)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      notification(.success)
    }
  }

  /// Haptic pattern for an error or rejection.
  ///
  /// Combines a rigid impact with error notification.
  public static func error() {
    impact(.rigid)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
      notification(.error)
    }
  }

  /// Haptic pattern for a gentle tap confirmation.
  public static func tap() {
    impact(.light)
  }

  /// Haptic pattern for a button press.
  public static func buttonPress() {
    impact(.medium)
  }

  /// Haptic pattern for toggling a switch.
  public static func toggle() {
    impact(.light, intensity: 0.7)
  }

  /// Haptic pattern for a heart/like reaction.
  ///
  /// Two quick soft impacts like a heartbeat.
  public static func heartbeat() {
    impact(.soft)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      impact(.soft, intensity: 0.7)
    }
  }

  /// Haptic pattern for celebration/confetti.
  ///
  /// Series of impacts building to success.
  public static func celebrate() {
    impact(.light)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      impact(.medium)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      notification(.success)
    }
  }
}

// MARK: IronHaptics.ImpactStyle

extension IronHaptics {
  /// Impact feedback intensity styles.
  public enum ImpactStyle: Sendable {
    /// Light impact for subtle feedback.
    case light
    /// Medium impact for standard interactions.
    case medium
    /// Heavy impact for significant actions.
    case heavy
    /// Soft impact with a softer, more muted feel.
    case soft
    /// Rigid impact with a sharp, precise feel.
    case rigid

    // MARK: Internal

    #if canImport(UIKit) && !os(watchOS)
    var uiKitStyle: UIImpactFeedbackGenerator.FeedbackStyle {
      switch self {
      case .light: .light
      case .medium: .medium
      case .heavy: .heavy
      case .soft: .soft
      case .rigid: .rigid
      }
    }
    #endif
  }
}

// MARK: IronHaptics.NotificationType

extension IronHaptics {
  /// Notification feedback types.
  public enum NotificationType: Sendable {
    /// Success - task completed.
    case success
    /// Warning - attention needed.
    case warning
    /// Error - something went wrong.
    case error

    #if canImport(UIKit) && !os(watchOS)
    var uiKitType: UINotificationFeedbackGenerator.FeedbackType {
      switch self {
      case .success: .success
      case .warning: .warning
      case .error: .error
      }
    }
    #endif
  }
}

// MARK: - IronHapticTapModifier

/// A modifier that triggers haptic feedback on tap.
public struct IronHapticTapModifier: ViewModifier {

  // MARK: Lifecycle

  public init(style: IronHaptics.ImpactStyle = .medium) {
    self.style = style
  }

  // MARK: Public

  public func body(content: Content) -> some View {
    content
      .simultaneousGesture(
        TapGesture()
          .onEnded { _ in
            IronHaptics.impact(style)
          }
      )
  }

  // MARK: Private

  private let style: IronHaptics.ImpactStyle
}

extension View {
  /// Adds haptic feedback on tap.
  ///
  /// ```swift
  /// Button("Action") { }
  ///   .ironHapticTap(.medium)
  /// ```
  ///
  /// - Parameter style: The impact style.
  /// - Returns: A view with haptic tap feedback.
  public func ironHapticTap(_ style: IronHaptics.ImpactStyle = .medium) -> some View {
    modifier(IronHapticTapModifier(style: style))
  }
}

// MARK: - IronSensoryFeedbackModifier

/// A modifier that combines visual animations with haptic feedback.
public struct IronSensoryFeedbackModifier: ViewModifier {

  // MARK: Lifecycle

  public init(
    trigger: Bool,
    haptic: @escaping () -> Void,
  ) {
    self.trigger = trigger
    self.haptic = haptic
  }

  // MARK: Public

  public func body(content: Content) -> some View {
    content
      .onChange(of: trigger) { _, newValue in
        if newValue {
          haptic()
        }
      }
  }

  // MARK: Private

  private let trigger: Bool
  private let haptic: () -> Void
}

extension View {
  /// Triggers haptic feedback when a condition becomes true.
  ///
  /// Useful for synchronizing haptics with animations.
  ///
  /// ```swift
  /// ContentView()
  ///   .ironSensoryFeedback(trigger: isComplete) {
  ///     IronHaptics.success()
  ///   }
  /// ```
  ///
  /// - Parameters:
  ///   - trigger: Condition that triggers the haptic.
  ///   - haptic: The haptic feedback to trigger.
  /// - Returns: A view with sensory feedback.
  public func ironSensoryFeedback(
    trigger: Bool,
    haptic: @escaping () -> Void,
  ) -> some View {
    modifier(
      IronSensoryFeedbackModifier(
        trigger: trigger,
        haptic: haptic,
      )
    )
  }
}

// MARK: - Previews

#Preview("IronHaptics - Impact Styles") {
  VStack(spacing: 16) {
    Text("Impact Styles")
      .font(.headline)

    Group {
      Button("Light") { IronHaptics.impact(.light) }
      Button("Medium") { IronHaptics.impact(.medium) }
      Button("Heavy") { IronHaptics.impact(.heavy) }
      Button("Soft") { IronHaptics.impact(.soft) }
      Button("Rigid") { IronHaptics.impact(.rigid) }
    }
    .buttonStyle(.bordered)
  }
  .padding()
}

#Preview("IronHaptics - Notifications") {
  VStack(spacing: 16) {
    Text("Notification Types")
      .font(.headline)

    Button("Success") { IronHaptics.notification(.success) }
      .buttonStyle(.borderedProminent)
      .tint(.green)

    Button("Warning") { IronHaptics.notification(.warning) }
      .buttonStyle(.borderedProminent)
      .tint(.orange)

    Button("Error") { IronHaptics.notification(.error) }
      .buttonStyle(.borderedProminent)
      .tint(.red)
  }
  .padding()
}

#Preview("IronHaptics - Patterns") {
  VStack(spacing: 16) {
    Text("Haptic Patterns")
      .font(.headline)

    Button("Tap") { IronHaptics.tap() }
    Button("Button Press") { IronHaptics.buttonPress() }
    Button("Toggle") { IronHaptics.toggle() }
    Button("Selection") { IronHaptics.selection() }
    Button("Heartbeat ❤️") { IronHaptics.heartbeat() }
    Button("Celebrate 🎉") { IronHaptics.celebrate() }
    Button("Success ✓") { IronHaptics.success() }
    Button("Error ✗") { IronHaptics.error() }
  }
  .buttonStyle(.bordered)
  .padding()
}

#Preview("IronHapticTap Modifier") {
  VStack(spacing: 24) {
    Text("Tap for haptic feedback")
      .font(.headline)

    RoundedRectangle(cornerRadius: 16)
      .fill(Color.blue.opacity(0.2))
      .frame(height: 100)
      .overlay {
        Text("Light Tap")
      }
      .ironHapticTap(.light)

    RoundedRectangle(cornerRadius: 16)
      .fill(Color.green.opacity(0.2))
      .frame(height: 100)
      .overlay {
        Text("Medium Tap")
      }
      .ironHapticTap(.medium)

    RoundedRectangle(cornerRadius: 16)
      .fill(Color.orange.opacity(0.2))
      .frame(height: 100)
      .overlay {
        Text("Heavy Tap")
      }
      .ironHapticTap(.heavy)
  }
  .padding()
}
