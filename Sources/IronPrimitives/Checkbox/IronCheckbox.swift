import IronCore
import SwiftUI

// MARK: - IronCheckbox

/// A themed checkbox with tactile animations.
///
/// `IronCheckbox` provides a customizable checkbox control with spring-based
/// animations for a delightful, physical feel when toggling.
///
/// ## Basic Usage
///
/// ```swift
/// @State private var isChecked = false
///
/// IronCheckbox(isChecked: $isChecked)
/// ```
///
/// ## With Label
///
/// ```swift
/// IronCheckbox("Accept Terms", isChecked: $accepted)
///
/// IronCheckbox(isChecked: $notifications) {
///   VStack(alignment: .leading) {
///     Text("Email Notifications")
///     Text("Get updates about your account")
///       .font(.caption)
///       .foregroundStyle(.secondary)
///   }
/// }
/// ```
///
/// ## Sizes
///
/// ```swift
/// IronCheckbox(isChecked: $value, size: .small)
/// IronCheckbox(isChecked: $value, size: .medium)
/// IronCheckbox(isChecked: $value, size: .large)
/// ```
///
/// ## Colors
///
/// ```swift
/// IronCheckbox(isChecked: $value, color: .success)
/// IronCheckbox(isChecked: $value, color: .error)
/// ```
public struct IronCheckbox<Label: View>: View {

  // MARK: Lifecycle

  /// Creates a checkbox without a label.
  ///
  /// - Parameters:
  ///   - isChecked: Binding to the checked state.
  ///   - size: The size of the checkbox.
  ///   - color: The color when checked.
  public init(
    isChecked: Binding<Bool>,
    size: IronCheckboxSize = .medium,
    color: IronCheckboxColor = .primary,
  ) where Label == EmptyView {
    _isChecked = isChecked
    self.size = size
    self.color = color
    label = nil
    accessibilityTitle = nil
  }

  /// Creates a checkbox with a text label.
  ///
  /// - Parameters:
  ///   - title: The text label.
  ///   - isChecked: Binding to the checked state.
  ///   - size: The size of the checkbox.
  ///   - color: The color when checked.
  public init(
    _ title: LocalizedStringKey,
    isChecked: Binding<Bool>,
    size: IronCheckboxSize = .medium,
    color: IronCheckboxColor = .primary,
  ) where Label == IronText {
    _isChecked = isChecked
    self.size = size
    self.color = color
    label = IronText(title, style: .bodyMedium, color: .primary)
    // LocalizedStringKey doesn't expose its string value, so we rely on .combine
    accessibilityTitle = nil
  }

  /// Creates a checkbox with a text label from a string.
  ///
  /// - Parameters:
  ///   - title: The string label.
  ///   - isChecked: Binding to the checked state.
  ///   - size: The size of the checkbox.
  ///   - color: The color when checked.
  public init(
    _ title: some StringProtocol,
    isChecked: Binding<Bool>,
    size: IronCheckboxSize = .medium,
    color: IronCheckboxColor = .primary,
  ) where Label == IronText {
    _isChecked = isChecked
    self.size = size
    self.color = color
    label = IronText(title, style: .bodyMedium, color: .primary)
    accessibilityTitle = String(title)
  }

  /// Creates a checkbox with a custom label.
  ///
  /// - Parameters:
  ///   - isChecked: Binding to the checked state.
  ///   - size: The size of the checkbox.
  ///   - color: The color when checked.
  ///   - accessibilityLabel: Optional accessibility label for the checkbox.
  ///     If not provided, the label's accessibility text will be combined automatically.
  ///   - label: The label view.
  public init(
    isChecked: Binding<Bool>,
    size: IronCheckboxSize = .medium,
    color: IronCheckboxColor = .primary,
    accessibilityLabel: String? = nil,
    @ViewBuilder label: () -> Label,
  ) {
    _isChecked = isChecked
    self.size = size
    self.color = color
    self.label = label()
    accessibilityTitle = accessibilityLabel
  }

  // MARK: Public

  public var body: some View {
    Button {
      withAnimation(shouldAnimate ? theme.animation.bouncy : nil) {
        isChecked.toggle()
      }
      IronLogger.ui.debug(
        "IronCheckbox toggled",
        metadata: ["isChecked": .string("\(isChecked)")],
      )
    } label: {
      HStack(spacing: theme.spacing.sm) {
        checkboxControl

        if let label {
          label
            .opacity(isEnabled ? 1.0 : 0.5)
        }
      }
      .frame(minWidth: label == nil ? minTouchTarget : nil)
      .frame(minHeight: minTouchTarget)
    }
    .buttonStyle(.plain)
    .disabled(!isEnabled)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(accessibilityLabelText)
    .accessibilityValue(isChecked ? "Checked" : "Unchecked")
    .accessibilityAddTraits(.isButton)
  }

  // MARK: Internal

  /// Computes the accessibility label text.
  /// Priority: explicit accessibilityTitle > fallback "Checkbox" when no label.
  /// When a label view is present without explicit title, returns empty to let .combine work.
  var accessibilityLabelText: String {
    if let accessibilityTitle {
      return accessibilityTitle
    }
    if label == nil {
      return "Checkbox"
    }
    // When label is present, return empty and let .accessibilityElement(children: .combine)
    // derive the label from child views
    return ""
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.ironSkipEntranceAnimations) private var skipEntranceAnimations

  @Binding private var isChecked: Bool

  @ScaledMetric(relativeTo: .caption2)
  private var smallSize: CGFloat = 16

  @ScaledMetric(relativeTo: .body)
  private var mediumSize: CGFloat = 20

  @ScaledMetric(relativeTo: .title3)
  private var largeSize: CGFloat = 24

  /// Minimum touch target size per Apple HIG (44pt).
  private let minTouchTarget: CGFloat = 44

  private let size: IronCheckboxSize
  private let color: IronCheckboxColor
  private let label: Label?
  private let accessibilityTitle: String?

  private var checkboxControl: some View {
    ZStack {
      // Background
      RoundedRectangle(cornerRadius: cornerRadius)
        .fill(isChecked ? checkboxColor : Color.clear)
        .frame(width: boxSize, height: boxSize)

      // Border
      RoundedRectangle(cornerRadius: cornerRadius)
        .strokeBorder(
          isChecked ? checkboxColor : borderColor,
          lineWidth: isChecked ? 0 : borderWidth,
        )
        .frame(width: boxSize, height: boxSize)

      // Checkmark
      if isChecked {
        Image(systemName: "checkmark")
          .font(.system(size: checkmarkSize, weight: .bold))
          .foregroundStyle(theme.colors.onPrimary)
          .transition(.scale.combined(with: .opacity))
      }
    }
    .scaleEffect(isChecked ? 1.0 : 0.95)
    .accessibilityHidden(true)
  }

  private var boxSize: CGFloat {
    switch size {
    case .small: smallSize
    case .medium: mediumSize
    case .large: largeSize
    }
  }

  private var cornerRadius: CGFloat {
    switch size {
    case .small: 3
    case .medium: 4
    case .large: 5
    }
  }

  private var borderWidth: CGFloat {
    switch size {
    case .small: 1.5
    case .medium: 2
    case .large: 2.5
    }
  }

  private var checkmarkSize: CGFloat {
    switch size {
    case .small: 10
    case .medium: 12
    case .large: 14
    }
  }

  private var borderColor: Color {
    isEnabled ? theme.colors.onSurface.opacity(0.3) : theme.colors.onSurface.opacity(0.15)
  }

  private var checkboxColor: Color {
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

  private var shouldAnimate: Bool {
    !reduceMotion && !skipEntranceAnimations
  }
}

// MARK: - IronCheckboxSize

/// Size options for `IronCheckbox`.
public enum IronCheckboxSize: Sendable, CaseIterable {
  /// A compact checkbox.
  case small
  /// The default checkbox size.
  case medium
  /// A larger checkbox for prominent placement.
  case large
}

// MARK: - IronCheckboxColor

/// Color options for `IronCheckbox` when checked.
public enum IronCheckboxColor: Sendable {
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

// MARK: - Previews

#Preview("IronCheckbox - Basic") {
  @Previewable @State var checked1 = false
  @Previewable @State var checked2 = true

  return VStack(spacing: 24) {
    IronCheckbox(isChecked: $checked1)
    IronCheckbox(isChecked: $checked2)
  }
  .padding()
}

#Preview("IronCheckbox - With Labels") {
  @Previewable @State var terms = false
  @Previewable @State var privacy = false
  @Previewable @State var newsletter = true

  return VStack(alignment: .leading, spacing: 16) {
    IronCheckbox("Accept Terms of Service", isChecked: $terms)
    IronCheckbox("Accept Privacy Policy", isChecked: $privacy)
    IronCheckbox("Subscribe to Newsletter", isChecked: $newsletter)
  }
  .padding()
}

#Preview("IronCheckbox - Custom Labels") {
  @Previewable @State var email = true
  @Previewable @State var push = false
  @Previewable @State var sms = false

  return VStack(alignment: .leading, spacing: 16) {
    IronCheckbox(isChecked: $email) {
      VStack(alignment: .leading) {
        Text("Email Notifications")
          .fontWeight(.medium)
        Text("Receive updates via email")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }

    IronCheckbox(isChecked: $push) {
      VStack(alignment: .leading) {
        Text("Push Notifications")
          .fontWeight(.medium)
        Text("Get instant alerts on your device")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }

    IronCheckbox(isChecked: $sms) {
      VStack(alignment: .leading) {
        Text("SMS Notifications")
          .fontWeight(.medium)
        Text("Receive text message alerts")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
  .padding()
}

#Preview("IronCheckbox - Sizes") {
  @Previewable @State var small = true
  @Previewable @State var medium = true
  @Previewable @State var large = true

  return VStack(alignment: .leading, spacing: 24) {
    IronCheckbox("Small", isChecked: $small, size: .small)
    IronCheckbox("Medium", isChecked: $medium, size: .medium)
    IronCheckbox("Large", isChecked: $large, size: .large)
  }
  .padding()
}

#Preview("IronCheckbox - Colors") {
  @Previewable @State var primary = true
  @Previewable @State var success = true
  @Previewable @State var warning = true
  @Previewable @State var error = true
  @Previewable @State var custom = true

  return VStack(alignment: .leading, spacing: 16) {
    IronCheckbox("Primary", isChecked: $primary, color: .primary)
    IronCheckbox("Success", isChecked: $success, color: .success)
    IronCheckbox("Warning", isChecked: $warning, color: .warning)
    IronCheckbox("Error", isChecked: $error, color: .error)
    IronCheckbox("Custom", isChecked: $custom, color: .custom(.purple))
  }
  .padding()
}

#Preview("IronCheckbox - Disabled") {
  VStack(alignment: .leading, spacing: 16) {
    IronCheckbox("Enabled Checked", isChecked: .constant(true))
    IronCheckbox("Disabled Checked", isChecked: .constant(true))
      .disabled(true)
    IronCheckbox("Disabled Unchecked", isChecked: .constant(false))
      .disabled(true)
  }
  .padding()
}

#Preview("IronCheckbox - Form Example") {
  @Previewable @State var item1 = false
  @Previewable @State var item2 = true
  @Previewable @State var item3 = false
  @Previewable @State var item4 = true
  @Previewable @State var item5 = false

  return VStack(alignment: .leading, spacing: 0) {
    Text("Select Interests")
      .font(.headline)
      .padding(.bottom)

    VStack(alignment: .leading, spacing: 12) {
      IronCheckbox("Technology", isChecked: $item1)
      IronCheckbox("Design", isChecked: $item2)
      IronCheckbox("Business", isChecked: $item3)
      IronCheckbox("Science", isChecked: $item4)
      IronCheckbox("Arts", isChecked: $item5)
    }

    Spacer().frame(height: 24)

    IronButton("Continue", isFullWidth: true) {
      // Continue action
    }
  }
  .padding()
}
