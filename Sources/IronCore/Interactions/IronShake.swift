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
///   .ironShake(active: shake)
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
/// .ironShake(active: shake, style: .subtle)   // Gentle nudge
/// .ironShake(active: shake, style: .standard) // Normal shake
/// .ironShake(active: shake, style: .intense)  // Urgent attention
/// ```
public struct IronShakeModifier: ViewModifier {

  // MARK: Lifecycle

  /// Creates a shake modifier.
  ///
  /// - Parameters:
  ///   - active: When true, triggers the shake animation.
  ///   - style: The intensity of the shake.
  ///   - onComplete: Called when the shake animation finishes.
  public init(
    active: Binding<Bool>,
    style: IronShakeStyle = .standard,
    onComplete: (() -> Void)? = nil,
  ) {
    _active = active
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
      .onChange(of: active) { _, newValue in
        if newValue {
          animationTrigger += 1
          // Reset after animation completes
          DispatchQueue.main.asyncAfter(deadline: .now() + style.duration) {
            active = false
            onComplete?()
          }
        }
      }
  }

  // MARK: Private

  @Binding private var active: Bool
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
  /// When `active` becomes true, the view shakes horizontally
  /// and then returns to its original position.
  ///
  /// ```swift
  /// @State private var shake = false
  ///
  /// TextField("Code", text: $code)
  ///   .ironShake(active: $shake)
  ///   .onChange(of: isInvalid) { _, invalid in
  ///     if invalid { shake = true }
  ///   }
  /// ```
  ///
  /// - Parameters:
  ///   - active: Binding that triggers shake when true.
  ///   - style: The shake intensity.
  ///   - onComplete: Called when shake finishes.
  /// - Returns: A view with shake capability.
  public func ironShake(
    active: Binding<Bool>,
    style: IronShakeStyle = .standard,
    onComplete: (() -> Void)? = nil,
  ) -> some View {
    modifier(
      IronShakeModifier(
        active: active,
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
///   .ironWiggle(active: trashIsFull)
/// ```
public struct IronWiggleModifier: ViewModifier {

  // MARK: Lifecycle

  public init(
    active: Bool,
    intensity: Double = 3,
    speed: Double = 0.1,
  ) {
    self.active = active
    self.intensity = intensity
    self.speed = speed
  }

  // MARK: Public

  public func body(content: Content) -> some View {
    content
      .rotationEffect(.degrees(active ? rotation : 0))
      .animation(
        active
          ? .linear(duration: speed).repeatForever(autoreverses: true)
          : .default,
        value: active,
      )
      .onChange(of: active) { _, newValue in
        if newValue {
          rotation = intensity
        } else {
          rotation = 0
        }
      }
      .onAppear {
        if active {
          rotation = intensity
        }
      }
  }

  // MARK: Private

  @State private var rotation: Double = 0

  private let active: Bool
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
  ///   .ironWiggle(active: trashNeedsEmptying)
  /// ```
  ///
  /// - Parameters:
  ///   - active: Whether the wiggle is animating.
  ///   - intensity: Rotation angle in degrees.
  ///   - speed: Time for one wiggle direction.
  /// - Returns: A view with wiggle animation.
  public func ironWiggle(
    active: Bool,
    intensity: Double = 3,
    speed: Double = 0.1,
  ) -> some View {
    modifier(
      IronWiggleModifier(
        active: active,
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
///   .ironBounce(active: hasNewNotification)
/// ```
public struct IronBounceModifier: ViewModifier {

  // MARK: Lifecycle

  public init(
    active: Binding<Bool>,
    intensity: CGFloat = 0.3,
  ) {
    _active = active
    self.intensity = intensity
  }

  // MARK: Public

  public func body(content: Content) -> some View {
    content
      .scaleEffect(scale)
      .onChange(of: active) { _, newValue in
        if newValue {
          performBounce()
        }
      }
  }

  // MARK: Private

  @Binding private var active: Bool
  @State private var scale: CGFloat = 1.0

  private let intensity: CGFloat

  private func performBounce() {
    // Scale up
    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
      scale = 1 + intensity
    }

    // Bounce back
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
        scale = 1.0
      }
    }

    // Reset active
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      active = false
    }
  }
}

extension View {
  /// Adds a bounce animation for feedback.
  ///
  /// When triggered, the view scales up and bounces back
  /// with spring physics.
  ///
  /// - Parameters:
  ///   - active: Binding that triggers bounce when true.
  ///   - intensity: Scale increase (0.3 = 30% larger).
  /// - Returns: A view with bounce animation.
  public func ironBounce(
    active: Binding<Bool>,
    intensity: CGFloat = 0.3,
  ) -> some View {
    modifier(
      IronBounceModifier(
        active: active,
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
      .ironShake(active: $shakeSubtle, style: .subtle)

    Button("Standard") { shakeStandard = true }
      .buttonStyle(.borderedProminent)
      .ironShake(active: $shakeStandard, style: .standard)

    Button("Intense") { shakeIntense = true }
      .buttonStyle(.borderedProminent)
      .tint(.red)
      .ironShake(active: $shakeIntense, style: .intense)
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
      .ironShake(active: $shake, style: .standard)

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
      .ironWiggle(active: trashFull)
  }
  .padding()
}

#Preview("IronBounce - Notification") {
  @Previewable @State var bounce = false
  @Previewable @State var count = 0

  VStack(spacing: 24) {
    Button {
      count += 1
      bounce = true
    } label: {
      ZStack(alignment: .topTrailing) {
        Image(systemName: "bell.fill")
          .font(.system(size: 40))
          .foregroundStyle(.blue)

        if count > 0 {
          Text("\(count)")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(6)
            .background(Circle().fill(.red))
            .offset(x: 8, y: -8)
            .ironBounce(active: $bounce)
        }
      }
    }
    .buttonStyle(.plain)

    Text("Tap bell to add notification")
      .font(.caption)
      .foregroundStyle(.secondary)
  }
  .padding()
}
