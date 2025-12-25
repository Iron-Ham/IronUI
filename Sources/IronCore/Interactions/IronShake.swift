import SwiftUI

// MARK: - IronShakeModifier

/// A shake animation for attention-grabbing feedback.
///
/// Creates a horizontal shake animation like Honkish's trash icon
/// shaking when full, or iOS's wrong password feedback.
///
/// ## Basic Usage
///
/// ```swift
/// @State private var shake = false
///
/// TextField("Password", text: $password)
///   .ironShake(isActive: $shake)
///
/// // Trigger on error
/// if passwordWrong {
///   shake = true
/// }
/// ```
///
/// ## Shake Styles
///
/// ```swift
/// .ironShake(isActive: $shake, style: .subtle)   // Gentle nudge
/// .ironShake(isActive: $shake, style: .standard) // Normal shake
/// .ironShake(isActive: $shake, style: .intense)  // Urgent attention
/// ```
public struct IronShakeModifier: ViewModifier {

  // MARK: Lifecycle

  /// Creates a shake modifier.
  ///
  /// - Parameters:
  ///   - isActive: When true, triggers the shake animation.
  ///   - style: The intensity of the shake.
  ///   - onComplete: Called when the shake animation finishes.
  public init(
    isActive: Binding<Bool>,
    style: IronShakeStyle = .standard,
    onComplete: (() -> Void)? = nil,
  ) {
    _isActive = isActive
    self.style = style
    self.onComplete = onComplete
  }

  // MARK: Public

  public func body(content: Content) -> some View {
    content
      .modifier(ShakeAnimationModifier(
        trigger: animationTrigger,
        intensity: style.intensity,
      ))
      .onChange(of: isActive) { _, newValue in
        if newValue {
          animationTrigger += 1
          // Reset after animation completes
          DispatchQueue.main.asyncAfter(deadline: .now() + style.duration) {
            isActive = false
            onComplete?()
          }
        }
      }
  }

  // MARK: Private

  @Binding private var isActive: Bool
  @State private var animationTrigger = 0

  private let style: IronShakeStyle
  private let onComplete: (() -> Void)?
}

// MARK: - ShakeAnimationModifier

/// Internal modifier that performs the keyframe shake animation.
private struct ShakeAnimationModifier: ViewModifier {

  // MARK: Internal

  let trigger: Int
  let intensity: CGFloat

  func body(content: Content) -> some View {
    content
      .keyframeAnimator(
        initialValue: ShakeValue(),
        trigger: trigger,
      ) { view, value in
        view.offset(x: value.offset)
      } keyframes: { _ in
        KeyframeTrack(\.offset) {
          // Oscillating shake with natural dampening
          // First oscillation (full intensity)
          SpringKeyframe(intensity, duration: 0.06, spring: .snappy)
          SpringKeyframe(-intensity, duration: 0.06, spring: .snappy)

          // Second oscillation (75% intensity)
          SpringKeyframe(intensity * 0.75, duration: 0.06, spring: .snappy)
          SpringKeyframe(-intensity * 0.75, duration: 0.06, spring: .snappy)

          // Third oscillation (50% intensity)
          SpringKeyframe(intensity * 0.5, duration: 0.05, spring: .snappy)
          SpringKeyframe(-intensity * 0.5, duration: 0.05, spring: .snappy)

          // Fourth oscillation (25% intensity)
          SpringKeyframe(intensity * 0.25, duration: 0.05, spring: .snappy)
          SpringKeyframe(-intensity * 0.25, duration: 0.05, spring: .snappy)

          // Settle back to center
          SpringKeyframe(0, duration: 0.1, spring: .smooth)
        }
      }
  }

  // MARK: Private

  private struct ShakeValue {
    var offset: CGFloat = 0
  }

}

// MARK: - IronShakeStyle

/// Intensity presets for shake animations.
public enum IronShakeStyle: Sendable {
  /// Subtle nudge for gentle feedback.
  case subtle
  /// Standard shake for errors or attention.
  case standard
  /// Intense shake for urgent attention.
  case intense
  /// Custom shake parameters.
  case custom(intensity: CGFloat, shakeCount: Int, duration: Double)

  // MARK: Internal

  var intensity: CGFloat {
    switch self {
    case .subtle: 4
    case .standard: 10
    case .intense: 20
    case .custom(let intensity, _, _): intensity
    }
  }

  var shakeCount: Int {
    switch self {
    case .subtle: 2
    case .standard: 4
    case .intense: 6
    case .custom(_, let count, _): count
    }
  }

  var duration: Double {
    switch self {
    case .subtle: 0.2
    case .standard: 0.4
    case .intense: 0.6
    case .custom(_, _, let duration): duration
    }
  }
}

// MARK: - View Extension

extension View {
  /// Adds a shake animation for attention feedback.
  ///
  /// When `isActive` becomes true, the view shakes horizontally
  /// and then returns to its original position.
  ///
  /// ```swift
  /// @State private var shake = false
  ///
  /// TextField("Code", text: $code)
  ///   .ironShake(isActive: $shake)
  ///   .onChange(of: isInvalid) { _, invalid in
  ///     if invalid { shake = true }
  ///   }
  /// ```
  ///
  /// - Parameters:
  ///   - isActive: Binding that triggers shake when true.
  ///   - style: The shake intensity.
  ///   - onComplete: Called when shake finishes.
  /// - Returns: A view with shake capability.
  public func ironShake(
    isActive: Binding<Bool>,
    style: IronShakeStyle = .standard,
    onComplete: (() -> Void)? = nil,
  ) -> some View {
    modifier(
      IronShakeModifier(
        isActive: isActive,
        style: style,
        onComplete: onComplete,
      )
    )
  }
}

// MARK: - IronWiggleModifier

/// A continuous wiggle animation for playful attention.
///
/// Unlike shake which is a one-time animation, wiggle
/// continuously animates while active.
///
/// ```swift
/// TrashIcon()
///   .ironWiggle(isActive: trashIsFull)
/// ```
public struct IronWiggleModifier: ViewModifier {

  // MARK: Lifecycle

  public init(
    isActive: Bool,
    intensity: Double = 3,
    speed: Double = 0.1,
  ) {
    self.isActive = isActive
    self.intensity = intensity
    self.speed = speed
  }

  // MARK: Public

  public func body(content: Content) -> some View {
    if isActive {
      content
        .phaseAnimator(WigglePhase.allCases) { view, phase in
          view.rotationEffect(.degrees(phase == .left ? -intensity : intensity))
        } animation: { _ in
          .easeInOut(duration: speed)
        }
    } else {
      content
        .rotationEffect(.degrees(0))
    }
  }

  // MARK: Internal

  /// Wiggle phases for oscillation.
  enum WigglePhase: CaseIterable {
    case left
    case right
  }

  // MARK: Private

  private let isActive: Bool
  private let intensity: Double
  private let speed: Double
}

extension View {
  /// Adds a continuous wiggle animation.
  ///
  /// The view rotates back and forth while active,
  /// like an icon wanting attention.
  ///
  /// ```swift
  /// Image(systemName: "trash.fill")
  ///   .ironWiggle(isActive: trashNeedsEmptying)
  /// ```
  ///
  /// - Parameters:
  ///   - isActive: Whether the wiggle is animating.
  ///   - intensity: Rotation angle in degrees.
  ///   - speed: Time for one wiggle direction.
  /// - Returns: A view with wiggle animation.
  public func ironWiggle(
    isActive: Bool,
    intensity: Double = 3,
    speed: Double = 0.1,
  ) -> some View {
    modifier(
      IronWiggleModifier(
        isActive: isActive,
        intensity: intensity,
        speed: speed,
      )
    )
  }
}

// MARK: - IronBounceModifier

/// A bounce animation for celebratory or attention feedback.
///
/// ```swift
/// NotificationBadge()
///   .ironBounce(isActive: $hasNewNotification)
/// ```
public struct IronBounceModifier: ViewModifier {

  // MARK: Lifecycle

  public init(
    isActive: Binding<Bool>,
    intensity: CGFloat = 0.3,
  ) {
    _isActive = isActive
    self.intensity = intensity
  }

  // MARK: Public

  public func body(content: Content) -> some View {
    content
      .modifier(BounceAnimationModifier(trigger: animationTrigger, intensity: intensity))
      .onChange(of: isActive) { _, newValue in
        if newValue {
          animationTrigger += 1
          // Reset isActive after animation
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isActive = false
          }
        }
      }
  }

  // MARK: Private

  @Binding private var isActive: Bool
  @State private var animationTrigger = 0

  private let intensity: CGFloat
}

// MARK: - BounceAnimationModifier

/// Internal modifier that performs the keyframe bounce animation.
private struct BounceAnimationModifier: ViewModifier {

  // MARK: Internal

  let trigger: Int
  let intensity: CGFloat

  func body(content: Content) -> some View {
    content
      .keyframeAnimator(
        initialValue: BounceValue(),
        trigger: trigger,
      ) { view, value in
        view.scaleEffect(value.scale)
      } keyframes: { _ in
        KeyframeTrack(\.scale) {
          // Quick scale up
          SpringKeyframe(1 + intensity, duration: 0.15, spring: .snappy)
          // Bounce back with overshoot
          SpringKeyframe(1.0, duration: 0.35, spring: .bouncy(duration: 0.35, extraBounce: 0.2))
        }
      }
  }

  // MARK: Private

  private struct BounceValue {
    var scale: CGFloat = 1.0
  }

}

extension View {
  /// Adds a bounce animation for feedback.
  ///
  /// When triggered, the view scales up and bounces back
  /// with spring physics.
  ///
  /// - Parameters:
  ///   - isActive: Binding that triggers bounce when true.
  ///   - intensity: Scale increase (0.3 = 30% larger).
  /// - Returns: A view with bounce animation.
  public func ironBounce(
    isActive: Binding<Bool>,
    intensity: CGFloat = 0.3,
  ) -> some View {
    modifier(
      IronBounceModifier(
        isActive: isActive,
        intensity: intensity,
      )
    )
  }
}

// MARK: - Previews

#Preview("IronShake - Styles") {
  @Previewable @State var shakeSubtle = false
  @Previewable @State var shakeStandard = false
  @Previewable @State var shakeIntense = false

  VStack(spacing: 24) {
    Text("Tap to shake")
      .font(.headline)

    Button("Subtle") { shakeSubtle = true }
      .buttonStyle(.borderedProminent)
      .ironShake(isActive: $shakeSubtle, style: .subtle)

    Button("Standard") { shakeStandard = true }
      .buttonStyle(.borderedProminent)
      .ironShake(isActive: $shakeStandard, style: .standard)

    Button("Intense") { shakeIntense = true }
      .buttonStyle(.borderedProminent)
      .tint(.red)
      .ironShake(isActive: $shakeIntense, style: .intense)
  }
  .padding()
}

#Preview("IronShake - Password Error") {
  @Previewable @State var password = ""
  @Previewable @State var shake = false
  @Previewable @State var showError = false

  VStack(spacing: 16) {
    Text("Enter 'secret'")
      .font(.headline)

    SecureField("Password", text: $password)
      .textFieldStyle(.roundedBorder)
      .padding(.horizontal, 40)
      .ironShake(isActive: $shake, style: .standard)

    if showError {
      Text("Wrong password!")
        .foregroundStyle(.red)
        .font(.caption)
    }

    Button("Submit") {
      if password != "secret" {
        shake = true
        showError = true
      }
    }
    .buttonStyle(.borderedProminent)
  }
  .padding()
}

#Preview("IronWiggle - Trash Icon") {
  @Previewable @State var trashFull = false

  VStack(spacing: 24) {
    Toggle("Trash is full", isOn: $trashFull)

    Image(systemName: "trash.fill")
      .font(.system(size: 50))
      .foregroundStyle(trashFull ? .red : .secondary)
      .ironWiggle(isActive: trashFull)
  }
  .padding()
}

#Preview("IronBounce - Notification") {
  @Previewable @State var bounce = false

  VStack(spacing: 32) {
    Text("Tap any item to bounce")
      .font(.headline)

    HStack(spacing: 40) {
      // Heart button
      Button {
        bounce = true
      } label: {
        Image(systemName: "heart.fill")
          .font(.system(size: 50))
          .foregroundStyle(.pink)
      }
      .buttonStyle(.plain)
      .ironBounce(isActive: $bounce)

      // Star button with separate state
      BounceableButton(
        systemName: "star.fill",
        color: .yellow,
      )

      // Bell button with separate state
      BounceableButton(
        systemName: "bell.fill",
        color: .blue,
      )
    }

    Text("Each icon bounces independently")
      .font(.caption)
      .foregroundStyle(.secondary)
  }
  .padding()
}

// MARK: - BounceableButton

/// Helper view for bounce preview with independent state.
private struct BounceableButton: View {
  let systemName: String
  let color: Color

  var body: some View {
    Button {
      bounce = true
    } label: {
      Image(systemName: systemName)
        .font(.system(size: 50))
        .foregroundStyle(color)
    }
    .buttonStyle(.plain)
    .ironBounce(isActive: $bounce)
  }

  @State private var bounce = false

}
