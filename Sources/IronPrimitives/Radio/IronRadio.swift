import IronCore
import SwiftUI

// MARK: - IronRadio

/// A themed radio button with tactile animations.
///
/// `IronRadio` provides a customizable radio button control with spring-based
/// animations for selecting a single option from a set.
///
/// ## Basic Usage
///
/// ```swift
/// enum Option: String, CaseIterable {
///   case first, second, third
/// }
///
/// @State private var selection: Option = .first
///
/// IronRadio("First", value: .first, selection: $selection)
/// IronRadio("Second", value: .second, selection: $selection)
/// IronRadio("Third", value: .third, selection: $selection)
/// ```
///
/// ## With Custom Labels
///
/// ```swift
/// IronRadio(value: .premium, selection: $plan) {
///   VStack(alignment: .leading) {
///     Text("Premium Plan")
///       .fontWeight(.medium)
///     Text("$9.99/month")
///       .font(.caption)
///       .foregroundStyle(.secondary)
///   }
/// }
/// ```
///
/// ## Using IronRadioGroup
///
/// ```swift
/// IronRadioGroup(selection: $selectedOption) {
///   IronRadio("Option 1", value: .first, selection: $selectedOption)
///   IronRadio("Option 2", value: .second, selection: $selectedOption)
///   IronRadio("Option 3", value: .third, selection: $selectedOption)
/// }
/// ```
public struct IronRadio<Value: Hashable, Label: View>: View {

  // MARK: Lifecycle

  /// Creates a radio button with a text label.
  ///
  /// - Parameters:
  ///   - title: The text label.
  ///   - value: The value this radio represents.
  ///   - selection: Binding to the selected value.
  ///   - size: The size of the radio button.
  ///   - color: The color when selected.
  public init(
    _ title: LocalizedStringKey,
    value: Value,
    selection: Binding<Value>,
    size: IronRadioSize = .medium,
    color: IronRadioColor = .primary,
  ) where Label == IronText {
    self.value = value
    _selection = selection
    self.size = size
    self.color = color
    label = IronText(title, style: .bodyMedium, color: .primary)
  }

  /// Creates a radio button with a text label from a string.
  ///
  /// - Parameters:
  ///   - title: The string label.
  ///   - value: The value this radio represents.
  ///   - selection: Binding to the selected value.
  ///   - size: The size of the radio button.
  ///   - color: The color when selected.
  public init(
    _ title: some StringProtocol,
    value: Value,
    selection: Binding<Value>,
    size: IronRadioSize = .medium,
    color: IronRadioColor = .primary,
  ) where Label == IronText {
    self.value = value
    _selection = selection
    self.size = size
    self.color = color
    label = IronText(title, style: .bodyMedium, color: .primary)
  }

  /// Creates a radio button with a custom label.
  ///
  /// - Parameters:
  ///   - value: The value this radio represents.
  ///   - selection: Binding to the selected value.
  ///   - size: The size of the radio button.
  ///   - color: The color when selected.
  ///   - label: The label view.
  public init(
    value: Value,
    selection: Binding<Value>,
    size: IronRadioSize = .medium,
    color: IronRadioColor = .primary,
    @ViewBuilder label: () -> Label,
  ) {
    self.value = value
    _selection = selection
    self.size = size
    self.color = color
    self.label = label()
  }

  // MARK: Public

  public var body: some View {
    Button {
      withAnimation(reduceMotion ? nil : theme.animation.bouncy) {
        selection = value
      }
      IronLogger.ui.debug(
        "IronRadio selected",
        metadata: ["value": .string("\(value)")],
      )
    } label: {
      HStack(spacing: theme.spacing.sm) {
        radioControl

        label
          .opacity(isEnabled ? 1.0 : 0.5)
      }
      .frame(minHeight: minTouchTarget)
    }
    .buttonStyle(.plain)
    .disabled(!isEnabled)
    .accessibilityElement(children: .combine)
    .accessibilityValue(isSelected ? "Selected" : "Not selected")
    .accessibilityAddTraits(.isButton)
    .accessibilityHint(isSelected ? "" : "Double tap to select")
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @Binding private var selection: Value

  @ScaledMetric(relativeTo: .caption2)
  private var smallSize: CGFloat = 16

  @ScaledMetric(relativeTo: .body)
  private var mediumSize: CGFloat = 20

  @ScaledMetric(relativeTo: .title3)
  private var largeSize: CGFloat = 24

  private let value: Value
  private let size: IronRadioSize
  private let color: IronRadioColor
  private let label: Label

  /// Minimum touch target size per Apple HIG (44pt).
  private let minTouchTarget: CGFloat = 44

  private var isSelected: Bool {
    selection == value
  }

  private var radioControl: some View {
    ZStack {
      // Outer circle (border)
      Circle()
        .strokeBorder(
          isSelected ? radioColor : borderColor,
          lineWidth: borderWidth,
        )
        .frame(width: circleSize, height: circleSize)

      // Inner dot (when selected)
      if isSelected {
        Circle()
          .fill(radioColor)
          .frame(width: dotSize, height: dotSize)
          .transition(.scale.combined(with: .opacity))
      }
    }
    .scaleEffect(isSelected ? 1.0 : 0.95)
    .accessibilityHidden(true)
  }

  private var circleSize: CGFloat {
    switch size {
    case .small: smallSize
    case .medium: mediumSize
    case .large: largeSize
    }
  }

  private var dotSize: CGFloat {
    switch size {
    case .small: smallSize * 0.5
    case .medium: mediumSize * 0.5
    case .large: largeSize * 0.5
    }
  }

  private var borderWidth: CGFloat {
    switch size {
    case .small: 1.5
    case .medium: 2
    case .large: 2.5
    }
  }

  private var borderColor: Color {
    isEnabled ? theme.colors.onSurface.opacity(0.3) : theme.colors.onSurface.opacity(0.15)
  }

  private var radioColor: Color {
    if !isEnabled {
      return theme.colors.border.opacity(0.5)
    }

    switch color {
    case .primary: return theme.colors.primary
    case .secondary: return theme.colors.secondary
    case .success: return theme.colors.success
    case .warning: return theme.colors.warning
    case .error: return theme.colors.error
    case .custom(let customColor): return customColor
    }
  }
}

// MARK: - IronRadioSize

/// Size options for `IronRadio`.
public enum IronRadioSize: Sendable, CaseIterable {
  /// A compact radio button.
  case small
  /// The default radio button size.
  case medium
  /// A larger radio button for prominent placement.
  case large
}

// MARK: - IronRadioColor

/// Color options for `IronRadio` when selected.
public enum IronRadioColor: Sendable {
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
  /// Custom color.
  case custom(Color)
}

// MARK: - IronRadioGroup

/// A container for grouping radio buttons.
///
/// `IronRadioGroup` provides consistent spacing and layout for radio button options.
///
/// ## Usage
///
/// ```swift
/// IronRadioGroup(selection: $plan) {
///   IronRadio("Basic", value: .basic, selection: $plan)
///   IronRadio("Pro", value: .pro, selection: $plan)
///   IronRadio("Enterprise", value: .enterprise, selection: $plan)
/// }
/// ```
public struct IronRadioGroup<Value: Hashable, Content: View>: View {

  // MARK: Lifecycle

  /// Creates a radio group.
  ///
  /// - Parameters:
  ///   - selection: Binding to the selected value.
  ///   - spacing: The spacing between radio buttons.
  ///   - content: The radio buttons in the group.
  public init(
    selection: Binding<Value>,
    spacing: CGFloat? = nil,
    @ViewBuilder content: () -> Content,
  ) {
    _selection = selection
    self.spacing = spacing
    self.content = content()
  }

  // MARK: Public

  public var body: some View {
    VStack(alignment: .leading, spacing: spacing ?? theme.spacing.md) {
      content
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  @Binding private var selection: Value

  private let spacing: CGFloat?
  private let content: Content
}

// MARK: - SampleOption

private enum SampleOption: String, CaseIterable {
  case first
  case second
  case third
}

#Preview("IronRadio - Basic") {
  struct Demo: View {
    @State private var selection = SampleOption.first

    var body: some View {
      VStack(alignment: .leading, spacing: 16) {
        IronRadio("First Option", value: SampleOption.first, selection: $selection)
        IronRadio("Second Option", value: SampleOption.second, selection: $selection)
        IronRadio("Third Option", value: SampleOption.third, selection: $selection)
      }
      .padding()
    }
  }

  return Demo()
}

#Preview("IronRadio - Custom Labels") {
  struct Demo: View {
    enum Plan: String, CaseIterable {
      case basic, pro, enterprise
    }

    @State private var plan = Plan.pro

    var body: some View {
      VStack(alignment: .leading, spacing: 16) {
        IronRadio(value: Plan.basic, selection: $plan) {
          VStack(alignment: .leading) {
            Text("Basic")
              .fontWeight(.medium)
            Text("Free forever")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        IronRadio(value: Plan.pro, selection: $plan) {
          VStack(alignment: .leading) {
            Text("Pro")
              .fontWeight(.medium)
            Text("$9.99/month")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }

        IronRadio(value: Plan.enterprise, selection: $plan) {
          VStack(alignment: .leading) {
            Text("Enterprise")
              .fontWeight(.medium)
            Text("Contact sales")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      .padding()
    }
  }

  return Demo()
}

#Preview("IronRadio - Sizes") {
  struct Demo: View {
    @State private var selection = SampleOption.first

    var body: some View {
      VStack(alignment: .leading, spacing: 24) {
        IronRadio("Small", value: SampleOption.first, selection: $selection, size: .small)
        IronRadio("Medium", value: SampleOption.second, selection: $selection, size: .medium)
        IronRadio("Large", value: SampleOption.third, selection: $selection, size: .large)
      }
      .padding()
    }
  }

  return Demo()
}

#Preview("IronRadio - Colors") {
  struct Demo: View {
    enum ColorOption: String, CaseIterable {
      case primary, success, warning, error, custom
    }

    @State private var selection = ColorOption.primary

    var body: some View {
      VStack(alignment: .leading, spacing: 16) {
        IronRadio("Primary", value: ColorOption.primary, selection: $selection, color: .primary)
        IronRadio("Success", value: ColorOption.success, selection: $selection, color: .success)
        IronRadio("Warning", value: ColorOption.warning, selection: $selection, color: .warning)
        IronRadio("Error", value: ColorOption.error, selection: $selection, color: .error)
        IronRadio("Custom", value: ColorOption.custom, selection: $selection, color: .custom(.purple))
      }
      .padding()
    }
  }

  return Demo()
}

#Preview("IronRadio - Disabled") {
  struct Demo: View {
    @State private var selection = SampleOption.first

    var body: some View {
      VStack(alignment: .leading, spacing: 16) {
        IronRadio("Enabled Selected", value: SampleOption.first, selection: $selection)
        IronRadio("Enabled Unselected", value: SampleOption.second, selection: $selection)
        IronRadio("Disabled Selected", value: SampleOption.first, selection: .constant(.first))
          .disabled(true)
        IronRadio("Disabled Unselected", value: SampleOption.second, selection: .constant(.first))
          .disabled(true)
      }
      .padding()
    }
  }

  return Demo()
}

#Preview("IronRadioGroup") {
  struct Demo: View {
    @State private var selection = SampleOption.second

    var body: some View {
      VStack(alignment: .leading) {
        Text("Select an option")
          .font(.headline)
          .padding(.bottom, 8)

        IronRadioGroup(selection: $selection) {
          IronRadio("First Option", value: SampleOption.first, selection: $selection)
          IronRadio("Second Option", value: SampleOption.second, selection: $selection)
          IronRadio("Third Option", value: SampleOption.third, selection: $selection)
        }
      }
      .padding()
    }
  }

  return Demo()
}

#Preview("IronRadio - Survey Example") {
  struct Demo: View {
    enum Rating: Int, CaseIterable {
      case poor = 1
      case fair = 2
      case good = 3
      case excellent = 4
    }

    @State private var rating = Rating.good

    var body: some View {
      VStack(alignment: .leading, spacing: 16) {
        Text("How would you rate our service?")
          .font(.headline)

        IronRadioGroup(selection: $rating) {
          IronRadio("Poor", value: Rating.poor, selection: $rating)
          IronRadio("Fair", value: Rating.fair, selection: $rating)
          IronRadio("Good", value: Rating.good, selection: $rating)
          IronRadio("Excellent", value: Rating.excellent, selection: $rating)
        }

        Spacer().frame(height: 16)

        IronButton("Submit", isFullWidth: true) {
          // Submit action
        }
      }
      .padding()
    }
  }

  return Demo()
}
