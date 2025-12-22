import IronCore
import SwiftUI

// MARK: - IronSpinner

/// A delightful, animated loading indicator with multiple styles.
///
/// `IronSpinner` provides tactile, joyful loading animations that bring
/// life to your app's loading states. Each style features carefully crafted
/// spring-based animations for a natural, physical feel.
///
/// ## Basic Usage
///
/// ```swift
/// IronSpinner()
/// ```
///
/// ## Styles
///
/// ```swift
/// IronSpinner(style: .spinning)   // Classic rotating ring
/// IronSpinner(style: .pulsing)    // Breathing dots
/// IronSpinner(style: .bouncing)   // Playful bouncing dots
/// IronSpinner(style: .orbiting)   // Orbital motion
/// ```
///
/// ## Colors
///
/// ```swift
/// IronSpinner(color: .primary)
/// IronSpinner(color: .success)
/// IronSpinner(color: .custom(.purple))
/// ```
///
/// ## Sizes
///
/// ```swift
/// IronSpinner(size: .small)   // Inline loading
/// IronSpinner(size: .medium)  // Default
/// IronSpinner(size: .large)   // Prominent loading
/// ```
public struct IronSpinner: View {

  // MARK: Lifecycle

  /// Creates a spinner with the specified configuration.
  ///
  /// - Parameters:
  ///   - style: The animation style of the spinner.
  ///   - color: The semantic color of the spinner.
  ///   - size: The size of the spinner.
  public init(
    style: IronSpinnerStyle = .spinning,
    color: IronSpinnerColor = .primary,
    size: IronSpinnerSize = .medium,
  ) {
    self.style = style
    self.color = color
    self.size = size
  }

  // MARK: Public

  public var body: some View {
    Group {
      switch style {
      case .spinning:
        spinningView
      case .pulsing:
        pulsingView
      case .bouncing:
        bouncingView
      case .orbiting:
        orbitingView
      }
    }
    .frame(width: spinnerSize, height: spinnerSize)
    .accessibilityLabel("Loading")
    .accessibilityAddTraits(.updatesFrequently)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  /// Scaled sizes for Dynamic Type
  @ScaledMetric(relativeTo: .caption2)
  private var smallSize: CGFloat = 20

  @ScaledMetric(relativeTo: .body)
  private var mediumSize: CGFloat = 32

  @ScaledMetric(relativeTo: .title)
  private var largeSize: CGFloat = 48

  /// Stroke widths
  @ScaledMetric(relativeTo: .caption2)
  private var smallStroke: CGFloat = 2

  @ScaledMetric(relativeTo: .body)
  private var mediumStroke: CGFloat = 3

  @ScaledMetric(relativeTo: .title)
  private var largeStroke: CGFloat = 4

  /// Dot sizes for pulsing/bouncing
  @ScaledMetric(relativeTo: .caption2)
  private var smallDot: CGFloat = 4

  @ScaledMetric(relativeTo: .body)
  private var mediumDot: CGFloat = 6

  @ScaledMetric(relativeTo: .title)
  private var largeDot: CGFloat = 8

  // Animation states
  @State private var isAnimating = false
  @State private var pulsePhases: [Bool] = [false, false, false]
  @State private var bouncePhases: [Bool] = [false, false, false]

  private let style: IronSpinnerStyle
  private let color: IronSpinnerColor
  private let size: IronSpinnerSize

  private var spinningView: some View {
    ZStack {
      // Track (subtle background ring)
      Circle()
        .stroke(spinnerColor.opacity(0.2), lineWidth: strokeWidth)

      // Animated arc with gradient tail
      Circle()
        .trim(from: 0, to: 0.7)
        .stroke(
          AngularGradient(
            gradient: Gradient(colors: [spinnerColor.opacity(0), spinnerColor]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(270),
          ),
          style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round),
        )
        .rotationEffect(.degrees(isAnimating ? 360 : 0))
        .animation(
          .linear(duration: 0.8)
            .repeatForever(autoreverses: false),
          value: isAnimating,
        )
    }
    .onAppear { isAnimating = true }
  }

  private var pulsingView: some View {
    HStack(spacing: dotSpacing) {
      ForEach(0..<3, id: \.self) { index in
        Circle()
          .fill(spinnerColor)
          .frame(width: dotSize, height: dotSize)
          .scaleEffect(pulsePhases[index] ? 1.0 : 0.5)
          .opacity(pulsePhases[index] ? 1.0 : 0.4)
          .animation(
            .spring(response: 0.4, dampingFraction: 0.5)
              .repeatForever(autoreverses: true)
              .delay(Double(index) * 0.15),
            value: pulsePhases[index],
          )
      }
    }
    .onAppear {
      // Stagger the pulse animations
      for index in 0..<3 {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15) {
          pulsePhases[index] = true
        }
      }
    }
  }

  private var bouncingView: some View {
    HStack(spacing: dotSpacing) {
      ForEach(0..<3, id: \.self) { index in
        Circle()
          .fill(spinnerColor)
          .frame(width: dotSize, height: dotSize)
          .offset(y: bouncePhases[index] ? -dotSize : dotSize)
          .animation(
            .spring(response: 0.35, dampingFraction: 0.4, blendDuration: 0)
              .repeatForever(autoreverses: true)
              .delay(Double(index) * 0.12),
            value: bouncePhases[index],
          )
      }
    }
    .onAppear {
      // Stagger the bounce animations
      for index in 0..<3 {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.12) {
          bouncePhases[index] = true
        }
      }
    }
  }

  private var orbitingView: some View {
    ZStack {
      // Subtle center dot
      Circle()
        .fill(spinnerColor.opacity(0.3))
        .frame(width: dotSize * 0.8, height: dotSize * 0.8)

      // Orbiting dots with different speeds and sizes
      ForEach(0..<3, id: \.self) { index in
        Circle()
          .fill(spinnerColor.opacity(1.0 - Double(index) * 0.25))
          .frame(width: dotSize * (1.0 - Double(index) * 0.2), height: dotSize * (1.0 - Double(index) * 0.2))
          .offset(x: orbitRadius(for: index))
          .rotationEffect(.degrees(isAnimating ? 360 : 0))
          .animation(
            .linear(duration: 1.0 + Double(index) * 0.3)
              .repeatForever(autoreverses: false),
            value: isAnimating,
          )
      }
    }
    .onAppear { isAnimating = true }
  }

  private var spinnerSize: CGFloat {
    switch size {
    case .small: smallSize
    case .medium: mediumSize
    case .large: largeSize
    }
  }

  private var strokeWidth: CGFloat {
    switch size {
    case .small: smallStroke
    case .medium: mediumStroke
    case .large: largeStroke
    }
  }

  private var dotSize: CGFloat {
    switch size {
    case .small: smallDot
    case .medium: mediumDot
    case .large: largeDot
    }
  }

  private var dotSpacing: CGFloat {
    switch size {
    case .small: 4
    case .medium: 6
    case .large: 8
    }
  }

  private var spinnerColor: Color {
    switch color {
    case .primary: theme.colors.primary
    case .secondary: theme.colors.secondary
    case .success: theme.colors.success
    case .warning: theme.colors.warning
    case .error: theme.colors.error
    case .info: theme.colors.info
    case .onSurface: theme.colors.onSurface
    case .custom(let customColor): customColor
    }
  }

  private func orbitRadius(for index: Int) -> CGFloat {
    let baseRadius = spinnerSize * 0.35
    return baseRadius - CGFloat(index) * (baseRadius * 0.2)
  }

}

// MARK: - IronSpinnerStyle

/// Animation styles for `IronSpinner`.
public enum IronSpinnerStyle: Sendable, CaseIterable {
  /// Classic rotating ring with gradient tail.
  case spinning
  /// Breathing dots that pulse in sequence.
  case pulsing
  /// Playful dots that bounce with spring physics.
  case bouncing
  /// Dots orbiting around a center point.
  case orbiting
}

// MARK: - IronSpinnerColor

/// Semantic colors for `IronSpinner`.
public enum IronSpinnerColor: Sendable {
  /// Primary brand color.
  case primary
  /// Secondary brand color.
  case secondary
  /// Success/positive indicator.
  case success
  /// Warning indicator.
  case warning
  /// Error/destructive indicator.
  case error
  /// Informational indicator.
  case info
  /// Matches surface text color.
  case onSurface
  /// Custom color.
  case custom(Color)
}

// MARK: - IronSpinnerSize

/// Size options for `IronSpinner`.
public enum IronSpinnerSize: Sendable, CaseIterable {
  /// Small spinner for inline loading indicators.
  case small
  /// Medium spinner, the default size.
  case medium
  /// Large spinner for prominent loading states.
  case large
}

// MARK: - Previews

#Preview("IronSpinner - Spinning") {
  VStack(spacing: 32) {
    HStack(spacing: 32) {
      IronSpinner(style: .spinning, size: .small)
      IronSpinner(style: .spinning, size: .medium)
      IronSpinner(style: .spinning, size: .large)
    }
    HStack(spacing: 32) {
      IronSpinner(style: .spinning, color: .primary)
      IronSpinner(style: .spinning, color: .success)
      IronSpinner(style: .spinning, color: .error)
    }
  }
  .padding()
}

#Preview("IronSpinner - Pulsing") {
  VStack(spacing: 32) {
    HStack(spacing: 32) {
      IronSpinner(style: .pulsing, size: .small)
      IronSpinner(style: .pulsing, size: .medium)
      IronSpinner(style: .pulsing, size: .large)
    }
    HStack(spacing: 32) {
      IronSpinner(style: .pulsing, color: .primary)
      IronSpinner(style: .pulsing, color: .info)
      IronSpinner(style: .pulsing, color: .warning)
    }
  }
  .padding()
}

#Preview("IronSpinner - Bouncing") {
  VStack(spacing: 32) {
    HStack(spacing: 32) {
      IronSpinner(style: .bouncing, size: .small)
      IronSpinner(style: .bouncing, size: .medium)
      IronSpinner(style: .bouncing, size: .large)
    }
    HStack(spacing: 32) {
      IronSpinner(style: .bouncing, color: .primary)
      IronSpinner(style: .bouncing, color: .success)
      IronSpinner(style: .bouncing, color: .secondary)
    }
  }
  .padding()
}

#Preview("IronSpinner - Orbiting") {
  VStack(spacing: 32) {
    HStack(spacing: 32) {
      IronSpinner(style: .orbiting, size: .small)
      IronSpinner(style: .orbiting, size: .medium)
      IronSpinner(style: .orbiting, size: .large)
    }
    HStack(spacing: 32) {
      IronSpinner(style: .orbiting, color: .primary)
      IronSpinner(style: .orbiting, color: .info)
      IronSpinner(style: .orbiting, color: .error)
    }
  }
  .padding()
}

#Preview("IronSpinner - All Styles") {
  VStack(spacing: 24) {
    HStack {
      IronSpinner(style: .spinning, size: .medium)
      Text("Spinning")
        .font(.caption)
        .foregroundStyle(.secondary)
      Spacer()
    }
    HStack {
      IronSpinner(style: .pulsing, size: .medium)
      Text("Pulsing")
        .font(.caption)
        .foregroundStyle(.secondary)
      Spacer()
    }
    HStack {
      IronSpinner(style: .bouncing, size: .medium)
      Text("Bouncing")
        .font(.caption)
        .foregroundStyle(.secondary)
      Spacer()
    }
    HStack {
      IronSpinner(style: .orbiting, size: .medium)
      Text("Orbiting")
        .font(.caption)
        .foregroundStyle(.secondary)
      Spacer()
    }
  }
  .padding()
  .frame(width: 200)
}

#Preview("IronSpinner - Loading Button") {
  VStack(spacing: 16) {
    Button {
      // Action
    } label: {
      HStack(spacing: 8) {
        IronSpinner(style: .spinning, color: .custom(.white), size: .small)
        Text("Loading...")
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 12)
      .background(Color.blue)
      .foregroundStyle(.white)
      .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    .buttonStyle(.plain)

    HStack(spacing: 12) {
      IronSpinner(style: .pulsing, size: .small)
      Text("Syncing data...")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
  }
  .padding()
}

#Preview("IronSpinner - Colors") {
  LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 24) {
    VStack(spacing: 8) {
      IronSpinner(color: .primary)
      Text("Primary").font(.caption2)
    }
    VStack(spacing: 8) {
      IronSpinner(color: .secondary)
      Text("Secondary").font(.caption2)
    }
    VStack(spacing: 8) {
      IronSpinner(color: .success)
      Text("Success").font(.caption2)
    }
    VStack(spacing: 8) {
      IronSpinner(color: .warning)
      Text("Warning").font(.caption2)
    }
    VStack(spacing: 8) {
      IronSpinner(color: .error)
      Text("Error").font(.caption2)
    }
    VStack(spacing: 8) {
      IronSpinner(color: .info)
      Text("Info").font(.caption2)
    }
  }
  .padding()
}
