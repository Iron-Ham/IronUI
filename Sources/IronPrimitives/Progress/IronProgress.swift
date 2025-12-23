import IronCore
import SwiftUI

// MARK: - IronProgress

/// A themed progress indicator for displaying task completion.
///
/// `IronProgress` provides both determinate (known progress) and indeterminate
/// (unknown duration) progress indicators with consistent styling and animations.
///
/// ## Basic Usage
///
/// ```swift
/// // Determinate progress
/// IronProgress(value: 0.7)
///
/// // Indeterminate progress
/// IronProgress()
/// ```
///
/// ## Styles
///
/// ```swift
/// IronProgress(value: 0.5, style: .linear)    // Horizontal bar
/// IronProgress(value: 0.5, style: .circular)  // Ring indicator
/// ```
///
/// ## Colors
///
/// ```swift
/// IronProgress(value: 0.8, color: .success)
/// IronProgress(value: 0.3, color: .warning)
/// ```
///
/// ## With Label
///
/// ```swift
/// IronProgress(value: 0.65) {
///   Text("65% Complete")
/// }
/// ```
public struct IronProgress<Label: View>: View {

  // MARK: Lifecycle

  /// Creates an indeterminate progress indicator.
  ///
  /// - Parameters:
  ///   - style: The visual style of the progress indicator.
  ///   - color: The semantic color of the progress indicator.
  ///   - size: The size of the progress indicator.
  public init(
    style: IronProgressStyle = .linear,
    color: IronProgressColor = .primary,
    size: IronProgressSize = .medium,
  ) where Label == EmptyView {
    value = nil
    self.style = style
    self.color = color
    self.size = size
    label = nil
  }

  /// Creates a determinate progress indicator.
  ///
  /// - Parameters:
  ///   - value: The current progress value (0.0 to 1.0).
  ///   - style: The visual style of the progress indicator.
  ///   - color: The semantic color of the progress indicator.
  ///   - size: The size of the progress indicator.
  public init(
    value: Double,
    style: IronProgressStyle = .linear,
    color: IronProgressColor = .primary,
    size: IronProgressSize = .medium,
  ) where Label == EmptyView {
    self.value = max(0, min(1, value))
    self.style = style
    self.color = color
    self.size = size
    label = nil
  }

  /// Creates a determinate progress indicator with a label.
  ///
  /// - Parameters:
  ///   - value: The current progress value (0.0 to 1.0).
  ///   - style: The visual style of the progress indicator.
  ///   - color: The semantic color of the progress indicator.
  ///   - size: The size of the progress indicator.
  ///   - label: A view to display alongside the progress indicator.
  public init(
    value: Double,
    style: IronProgressStyle = .linear,
    color: IronProgressColor = .primary,
    size: IronProgressSize = .medium,
    @ViewBuilder label: () -> Label,
  ) {
    self.value = max(0, min(1, value))
    self.style = style
    self.color = color
    self.size = size
    self.label = label()
  }

  // MARK: Public

  public var body: some View {
    Group {
      switch style {
      case .linear:
        linearProgress
      case .circular:
        circularProgress
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityLabelText)
    .accessibilityValue(accessibilityValueText)
    .accessibilityAddTraits(value == nil ? .updatesFrequently : [])
  }

  // MARK: Internal

  /// Accessibility label describing the progress type
  var accessibilityLabelText: String {
    value == nil ? "Loading" : "Progress"
  }

  /// Accessibility value showing percentage or loading state
  var accessibilityValueText: String {
    if let value {
      "\(Int(value * 100)) percent"
    } else {
      "In progress"
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  /// Track height scales with Dynamic Type.
  @ScaledMetric(relativeTo: .caption2)
  private var smallHeight: CGFloat = 4

  @ScaledMetric(relativeTo: .footnote)
  private var mediumHeight: CGFloat = 6

  @ScaledMetric(relativeTo: .body)
  private var largeHeight: CGFloat = 8

  /// Circular sizes scale with Dynamic Type.
  @ScaledMetric(relativeTo: .caption2)
  private var smallCircularSize: CGFloat = 20

  @ScaledMetric(relativeTo: .footnote)
  private var mediumCircularSize: CGFloat = 32

  @ScaledMetric(relativeTo: .body)
  private var largeCircularSize: CGFloat = 48

  /// Stroke width for circular progress.
  @ScaledMetric(relativeTo: .caption2)
  private var smallStrokeWidth: CGFloat = 2

  @ScaledMetric(relativeTo: .footnote)
  private var mediumStrokeWidth: CGFloat = 3

  @ScaledMetric(relativeTo: .body)
  private var largeStrokeWidth: CGFloat = 4

  @State private var indeterminatePhase: CGFloat = 0

  private let value: Double?
  private let style: IronProgressStyle
  private let color: IronProgressColor
  private let size: IronProgressSize
  private let label: Label?

  private var linearProgress: some View {
    VStack(alignment: .leading, spacing: theme.spacing.xs) {
      if let label {
        label
      }

      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          // Track
          Capsule()
            .fill(trackColor)
            .frame(height: trackHeight)

          // Progress
          if let value {
            // Determinate
            Capsule()
              .fill(progressColor)
              .frame(width: geometry.size.width * value, height: trackHeight)
              .animation(theme.animation.smooth, value: value)
          } else {
            // Indeterminate
            Capsule()
              .fill(progressColor)
              .frame(width: geometry.size.width * 0.3, height: trackHeight)
              .offset(x: geometry.size.width * indeterminatePhase)
              .onAppear {
                withAnimation(
                  .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                  indeterminatePhase = 0.7
                }
              }
          }
        }
      }
      .frame(height: trackHeight)
      .clipShape(Capsule())
    }
  }

  private var circularProgress: some View {
    HStack(spacing: theme.spacing.sm) {
      ZStack {
        // Track
        Circle()
          .stroke(trackColor, lineWidth: strokeWidth)

        // Progress
        if let value {
          // Determinate
          Circle()
            .trim(from: 0, to: value)
            .stroke(progressColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .animation(theme.animation.smooth, value: value)
        } else {
          // Indeterminate
          Circle()
            .trim(from: 0.1, to: 0.4)
            .stroke(progressColor, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
            .rotationEffect(.degrees(indeterminatePhase * 360))
            .onAppear {
              withAnimation(
                .linear(duration: 1.0)
                  .repeatForever(autoreverses: false)
              ) {
                indeterminatePhase = 1.0
              }
            }
        }
      }
      .frame(width: circularSize, height: circularSize)

      if let label {
        label
      }
    }
  }

  private var trackHeight: CGFloat {
    switch size {
    case .small: smallHeight
    case .medium: mediumHeight
    case .large: largeHeight
    }
  }

  private var circularSize: CGFloat {
    switch size {
    case .small: smallCircularSize
    case .medium: mediumCircularSize
    case .large: largeCircularSize
    }
  }

  private var strokeWidth: CGFloat {
    switch size {
    case .small: smallStrokeWidth
    case .medium: mediumStrokeWidth
    case .large: largeStrokeWidth
    }
  }

  private var trackColor: Color {
    theme.colors.border.opacity(0.3)
  }

  private var progressColor: Color {
    switch color {
    case .primary: theme.colors.primary
    case .secondary: theme.colors.secondary
    case .success: theme.colors.success
    case .warning: theme.colors.warning
    case .error: theme.colors.error
    case .info: theme.colors.info
    case .custom(let customColor): customColor
    }
  }
}

// MARK: - IronProgressStyle

/// Visual styles for `IronProgress`.
public enum IronProgressStyle: Sendable, CaseIterable {
  /// Horizontal bar progress indicator.
  case linear
  /// Circular ring progress indicator.
  case circular
}

// MARK: - IronProgressColor

/// Semantic colors for `IronProgress`.
public enum IronProgressColor: Sendable {
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
  /// Custom color.
  case custom(Color)
}

// MARK: - IronProgressSize

/// Size options for `IronProgress`.
public enum IronProgressSize: Sendable, CaseIterable {
  /// Small progress indicator.
  case small
  /// Medium progress indicator, the default.
  case medium
  /// Large progress indicator.
  case large
}

// MARK: - Previews

#Preview("IronProgress - Linear Determinate") {
  VStack(spacing: 24) {
    IronProgress(value: 0.0)
    IronProgress(value: 0.25)
    IronProgress(value: 0.5)
    IronProgress(value: 0.75)
    IronProgress(value: 1.0)
  }
  .padding()
}

#Preview("IronProgress - Linear Sizes") {
  VStack(spacing: 24) {
    IronProgress(value: 0.6, size: .small)
    IronProgress(value: 0.6, size: .medium)
    IronProgress(value: 0.6, size: .large)
  }
  .padding()
}

#Preview("IronProgress - Linear Indeterminate") {
  VStack(spacing: 24) {
    IronProgress()
    IronProgress(color: .success)
    IronProgress(color: .info)
  }
  .padding()
}

#Preview("IronProgress - Circular Determinate") {
  HStack(spacing: 32) {
    IronProgress(value: 0.25, style: .circular)
    IronProgress(value: 0.5, style: .circular)
    IronProgress(value: 0.75, style: .circular)
    IronProgress(value: 1.0, style: .circular)
  }
  .padding()
}

#Preview("IronProgress - Circular Sizes") {
  HStack(spacing: 32) {
    IronProgress(value: 0.6, style: .circular, size: .small)
    IronProgress(value: 0.6, style: .circular, size: .medium)
    IronProgress(value: 0.6, style: .circular, size: .large)
  }
  .padding()
}

#Preview("IronProgress - Circular Indeterminate") {
  HStack(spacing: 32) {
    IronProgress(style: .circular)
    IronProgress(style: .circular, color: .success)
    IronProgress(style: .circular, color: .error)
  }
  .padding()
}

#Preview("IronProgress - Colors") {
  VStack(spacing: 16) {
    IronProgress(value: 0.7, color: .primary)
    IronProgress(value: 0.7, color: .secondary)
    IronProgress(value: 0.7, color: .success)
    IronProgress(value: 0.7, color: .warning)
    IronProgress(value: 0.7, color: .error)
    IronProgress(value: 0.7, color: .info)
  }
  .padding()
}

#Preview("IronProgress - With Labels") {
  VStack(spacing: 24) {
    IronProgress(value: 0.65) {
      HStack {
        Text("Uploading...")
        Spacer()
        Text("65%")
          .foregroundStyle(.secondary)
      }
      .font(.subheadline)
    }

    IronProgress(value: 0.3, style: .circular, size: .large) {
      VStack(alignment: .leading) {
        Text("Processing")
          .font(.headline)
        Text("30% complete")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
  .padding()
}
