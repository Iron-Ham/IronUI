import IronCore
import SwiftUI

// MARK: - IronToggle

/// A themed toggle switch with tactile drag and tap gestures.
///
/// `IronToggle` provides a customizable on/off switch with spring-based
/// animations and drag gesture support for a delightful, physical feel.
///
/// ## Basic Usage
///
/// ```swift
/// @State private var isEnabled = false
///
/// IronToggle(isOn: $isEnabled)
/// ```
///
/// ## With Label
///
/// ```swift
/// IronToggle("Dark Mode", isOn: $isDarkMode)
///
/// IronToggle(isOn: $notifications) {
///   Label("Notifications", systemImage: "bell")
/// }
/// ```
///
/// ## Sizes
///
/// ```swift
/// IronToggle(isOn: $value, size: .small)
/// IronToggle(isOn: $value, size: .medium)
/// IronToggle(isOn: $value, size: .large)
/// ```
///
/// ## Colors
///
/// ```swift
/// IronToggle(isOn: $value, color: .success)
/// IronToggle(isOn: $value, color: .warning)
/// IronToggle(isOn: $value, color: .custom(.purple))
/// ```
public struct IronToggle<Label: View>: View {

  // MARK: Lifecycle

  /// Creates a toggle without a label.
  ///
  /// - Parameters:
  ///   - isOn: Binding to the toggle state.
  ///   - size: The size of the toggle.
  ///   - color: The color when the toggle is on.
  public init(
    isOn: Binding<Bool>,
    size: IronToggleSize = .medium,
    color: IronToggleColor = .primary,
  ) where Label == EmptyView {
    _isOn = isOn
    self.size = size
    self.color = color
    label = nil
    accessibilityTitle = nil
  }

  /// Creates a toggle with a text label.
  ///
  /// - Parameters:
  ///   - title: The text label.
  ///   - isOn: Binding to the toggle state.
  ///   - size: The size of the toggle.
  ///   - color: The color when the toggle is on.
  public init(
    _ title: LocalizedStringKey,
    isOn: Binding<Bool>,
    size: IronToggleSize = .medium,
    color: IronToggleColor = .primary,
  ) where Label == IronText {
    _isOn = isOn
    self.size = size
    self.color = color
    label = IronText(title, style: .bodyMedium, color: .primary)
    // LocalizedStringKey doesn't expose its string value, so we rely on .combine
    accessibilityTitle = nil
  }

  /// Creates a toggle with a text label from a string.
  ///
  /// - Parameters:
  ///   - title: The string label.
  ///   - isOn: Binding to the toggle state.
  ///   - size: The size of the toggle.
  ///   - color: The color when the toggle is on.
  public init(
    _ title: some StringProtocol,
    isOn: Binding<Bool>,
    size: IronToggleSize = .medium,
    color: IronToggleColor = .primary,
  ) where Label == IronText {
    _isOn = isOn
    self.size = size
    self.color = color
    label = IronText(title, style: .bodyMedium, color: .primary)
    accessibilityTitle = String(title)
  }

  /// Creates a toggle with a custom label.
  ///
  /// - Parameters:
  ///   - isOn: Binding to the toggle state.
  ///   - size: The size of the toggle.
  ///   - color: The color when the toggle is on.
  ///   - accessibilityLabel: Optional accessibility label for the toggle.
  ///     If not provided, the label's accessibility text will be combined automatically.
  ///   - label: The label view.
  public init(
    isOn: Binding<Bool>,
    size: IronToggleSize = .medium,
    color: IronToggleColor = .primary,
    accessibilityLabel: String? = nil,
    @ViewBuilder label: () -> Label,
  ) {
    _isOn = isOn
    self.size = size
    self.color = color
    self.label = label()
    accessibilityTitle = accessibilityLabel
  }

  // MARK: Public

  public var body: some View {
    let content = HStack(spacing: theme.spacing.md) {
      if let label {
        label
          .opacity(isEnabled ? 1.0 : 0.5)
      }

      Spacer()

      toggleSwitch
        .frame(minWidth: minTouchTarget, minHeight: minTouchTarget)
    }
    .frame(minHeight: minTouchTarget)
    .contentShape(Rectangle())
    .onTapGesture {
      guard isEnabled else { return }
      toggleWithAnimation()
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(accessibilityLabelText)
    .accessibilityValue(isOn ? "On" : "Off")
    .accessibilityAddTraits(.isButton)
  }

  // MARK: Internal

  /// Computes the accessibility label text.
  /// Priority: explicit accessibilityTitle > fallback "Toggle" when no label.
  /// When a label view is present without explicit title, returns empty to let .combine work.
  var accessibilityLabelText: String {
    if let accessibilityTitle {
      return accessibilityTitle
    }
    if label == nil {
      return "Toggle"
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

  @Binding private var isOn: Bool

  /// Tracks the drag offset during gesture
  @GestureState private var dragOffset: CGFloat = 0

  /// Whether a drag is actively happening
  @State private var isDragging = false

  @ScaledMetric(relativeTo: .caption2)
  private var smallWidth: CGFloat = 40

  @ScaledMetric(relativeTo: .caption2)
  private var smallHeight: CGFloat = 24

  @ScaledMetric(relativeTo: .body)
  private var mediumWidth: CGFloat = 50

  @ScaledMetric(relativeTo: .body)
  private var mediumHeight: CGFloat = 30

  @ScaledMetric(relativeTo: .title3)
  private var largeWidth: CGFloat = 60

  @ScaledMetric(relativeTo: .title3)
  private var largeHeight: CGFloat = 36

  private let size: IronToggleSize
  private let color: IronToggleColor
  private let label: Label?
  private let accessibilityTitle: String?

  /// Minimum touch target size per Apple HIG (44pt).
  private let minTouchTarget: CGFloat = 44

  private var toggleSwitch: some View {
    ZStack(alignment: .leading) {
      // Track - using overlapping layers to preserve theme colors
      ZStack {
        // Base layer (off color)
        Capsule()
          .fill(trackOffColor)
          .frame(width: trackWidth, height: trackHeight)

        // On color overlay with opacity based on progress
        Capsule()
          .fill(toggleColor)
          .frame(width: trackWidth, height: trackHeight)
          .opacity(isEnabled ? visualProgress : 0)
      }

      // Thumb with drag support
      Circle()
        .fill(thumbColor)
        .frame(width: thumbSize, height: thumbSize)
        .ironShadow(isDragging ? theme.shadows.md : theme.shadows.sm)
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .offset(x: thumbOffset)
        .accessibleAnimation(theme.animation.bouncy, value: isOn)
        .accessibleAnimation(theme.animation.snappy, value: isDragging)
    }
    .padding(thumbPadding)
    .gesture(dragGesture)
    .accessibilityHidden(true)
  }

  /// The drag gesture for sliding the toggle
  private var dragGesture: some Gesture {
    DragGesture(minimumDistance: 0)
      .updating($dragOffset) { value, state, _ in
        state = value.translation.width
      }
      .onChanged { value in
        // Only start dragging if we've moved a meaningful amount
        if !isDragging, abs(value.translation.width) > 2 {
          isDragging = true
        }
      }
      .onEnded { value in
        isDragging = false
        guard isEnabled else { return }

        let threshold = maxThumbTravel * 0.3
        let translation = value.translation.width

        // If minimal movement, treat as a tap
        if abs(translation) < 5 {
          toggleWithAnimation()
          return
        }

        // Determine if we should toggle based on drag direction and distance
        if isOn {
          // Currently on, check if dragged left past threshold
          if translation < -threshold {
            toggleWithAnimation()
          }
        } else {
          // Currently off, check if dragged right past threshold
          if translation > threshold {
            toggleWithAnimation()
          }
        }
      }
  }

  /// Maximum travel distance for the thumb
  private var maxThumbTravel: CGFloat {
    trackWidth - thumbSize - (thumbPadding * 2)
  }

  /// Current thumb offset including drag
  private var thumbOffset: CGFloat {
    let baseOffset = isOn ? maxThumbTravel : 0

    if isDragging {
      // Clamp the drag offset within bounds
      let newOffset = baseOffset + dragOffset
      return max(0, min(maxThumbTravel, newOffset))
    }

    return baseOffset
  }

  private var trackWidth: CGFloat {
    switch size {
    case .small: smallWidth
    case .medium: mediumWidth
    case .large: largeWidth
    }
  }

  private var trackHeight: CGFloat {
    switch size {
    case .small: smallHeight
    case .medium: mediumHeight
    case .large: largeHeight
    }
  }

  private var thumbSize: CGFloat {
    trackHeight - (thumbPadding * 2)
  }

  private var thumbPadding: CGFloat {
    switch size {
    case .small: 2
    case .medium: 3
    case .large: 4
    }
  }

  /// Progress from off (0) to on (1) based on thumb position
  private var visualProgress: CGFloat {
    guard maxThumbTravel > 0 else { return isOn ? 1 : 0 }
    return thumbOffset / maxThumbTravel
  }

  private var trackOffColor: Color {
    isEnabled ? theme.colors.onSurface.opacity(0.3) : theme.colors.onSurface.opacity(0.15)
  }

  private var thumbColor: Color {
    isEnabled ? theme.colors.onPrimary : theme.colors.surface
  }

  private var toggleColor: Color {
    switch color {
    case .primary: theme.colors.primary
    case .secondary: theme.colors.secondary
    case .success: theme.colors.success
    case .warning: theme.colors.warning
    case .error: theme.colors.error
    case .custom(let customColor): customColor
    }
  }

  private var shouldAnimate: Bool {
    !reduceMotion && !skipEntranceAnimations
  }

  /// Toggles the state with animation and logging
  private func toggleWithAnimation() {
    withAnimation(shouldAnimate ? theme.animation.bouncy : nil) {
      isOn.toggle()
    }
    IronLogger.ui.debug(
      "IronToggle toggled",
      metadata: ["isOn": .string("\(isOn)")],
    )
  }

}

// MARK: - IronToggleSize

/// Size options for `IronToggle`.
public enum IronToggleSize: Sendable, CaseIterable {
  /// A compact toggle.
  case small
  /// The default toggle size.
  case medium
  /// A larger toggle for prominent placement.
  case large
}

// MARK: - IronToggleColor

/// Color options for `IronToggle` when on.
public enum IronToggleColor: Sendable {
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

#Preview("IronToggle - Basic") {
  @Previewable @State var isOn = false

  return VStack(spacing: 24) {
    IronToggle(isOn: $isOn)

    IronToggle(isOn: .constant(true))
    IronToggle(isOn: .constant(false))
  }
  .padding()
}

#Preview("IronToggle - With Labels") {
  @Previewable @State var darkMode = false
  @Previewable @State var notifications = true
  @Previewable @State var analytics = false

  return VStack(spacing: 16) {
    IronToggle("Dark Mode", isOn: $darkMode)
    IronToggle("Notifications", isOn: $notifications)
    IronToggle("Analytics", isOn: $analytics)
  }
  .padding()
}

#Preview("IronToggle - Custom Labels") {
  @Previewable @State var wifi = true
  @Previewable @State var bluetooth = false
  @Previewable @State var airplane = false

  return VStack(spacing: 16) {
    IronToggle(isOn: $wifi) {
      Label("Wi-Fi", systemImage: "wifi")
    }

    IronToggle(isOn: $bluetooth) {
      Label("Bluetooth", systemImage: "wave.3.right")
    }

    IronToggle(isOn: $airplane) {
      Label("Airplane Mode", systemImage: "airplane")
    }
  }
  .padding()
}

#Preview("IronToggle - Sizes") {
  @Previewable @State var small = true
  @Previewable @State var medium = true
  @Previewable @State var large = true

  return VStack(spacing: 24) {
    HStack {
      Text("Small")
      Spacer()
      IronToggle(isOn: $small, size: .small)
    }

    HStack {
      Text("Medium")
      Spacer()
      IronToggle(isOn: $medium, size: .medium)
    }

    HStack {
      Text("Large")
      Spacer()
      IronToggle(isOn: $large, size: .large)
    }
  }
  .padding()
}

#Preview("IronToggle - Colors") {
  @Previewable @State var primary = true
  @Previewable @State var success = true
  @Previewable @State var warning = true
  @Previewable @State var error = true
  @Previewable @State var custom = true

  return VStack(spacing: 16) {
    HStack {
      Text("Primary")
      Spacer()
      IronToggle(isOn: $primary, color: .primary)
    }

    HStack {
      Text("Success")
      Spacer()
      IronToggle(isOn: $success, color: .success)
    }

    HStack {
      Text("Warning")
      Spacer()
      IronToggle(isOn: $warning, color: .warning)
    }

    HStack {
      Text("Error")
      Spacer()
      IronToggle(isOn: $error, color: .error)
    }

    HStack {
      Text("Custom")
      Spacer()
      IronToggle(isOn: $custom, color: .custom(.purple))
    }
  }
  .padding()
}

#Preview("IronToggle - Disabled") {
  VStack(spacing: 16) {
    IronToggle("Enabled On", isOn: .constant(true))

    IronToggle("Disabled On", isOn: .constant(true))
      .disabled(true)

    IronToggle("Disabled Off", isOn: .constant(false))
      .disabled(true)
  }
  .padding()
}

#Preview("IronToggle - Settings Example") {
  struct SettingsRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
      IronToggle(title, isOn: $isOn)
        .padding()
    }
  }

  @Previewable @State var notifications = true
  @Previewable @State var sounds = true
  @Previewable @State var haptics = false
  @Previewable @State var autoUpdate = true

  return VStack(spacing: 0) {
    SettingsRow(title: "Push Notifications", isOn: $notifications)
    Divider().padding(.leading)
    SettingsRow(title: "Sound Effects", isOn: $sounds)
    Divider().padding(.leading)
    SettingsRow(title: "Haptic Feedback", isOn: $haptics)
    Divider().padding(.leading)
    SettingsRow(title: "Auto-Update", isOn: $autoUpdate)
  }
  .background(Color.white)
  .clipShape(RoundedRectangle(cornerRadius: 12))
  .padding()
}
