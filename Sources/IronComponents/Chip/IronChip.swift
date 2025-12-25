import IronCore
import IronPrimitives
import SwiftUI

// MARK: - IronChip

/// A themed chip component for tags, filters, and selections.
///
/// `IronChip` provides compact elements for filtering content, making selections,
/// or displaying tags with optional icons and dismiss actions.
///
/// ## Basic Usage
///
/// ```swift
/// IronChip("Swift")
/// IronChip("Featured", variant: .filled)
/// ```
///
/// ## With Leading Icon
///
/// ```swift
/// IronChip("Location", icon: "mappin")
/// IronChip("Settings", icon: "gear", variant: .outlined)
/// ```
///
/// ## Dismissible Chips
///
/// ```swift
/// IronChip("Remove me", onDismiss: { /* handle removal */ })
/// ```
///
/// ## Selectable Chips
///
/// ```swift
/// @State private var isSelected = false
///
/// IronChip("Filter", isSelected: $isSelected)
/// ```
public struct IronChip<LeadingIcon: View>: View {

  // MARK: Lifecycle

  /// Creates a chip with a text label.
  ///
  /// - Parameters:
  ///   - title: The chip label.
  ///   - variant: The visual style of the chip.
  ///   - size: The size of the chip.
  ///   - onDismiss: Optional dismiss action.
  public init(
    _ title: LocalizedStringKey,
    variant: IronChipVariant = .filled,
    size: IronChipSize = .medium,
    onDismiss: (() -> Void)? = nil,
  ) where LeadingIcon == EmptyView {
    self.title = title
    self.variant = variant
    self.size = size
    self.onDismiss = onDismiss
    leadingIcon = nil
    _isSelected = .constant(nil)
  }

  /// Creates a chip with a text label from a string.
  ///
  /// - Parameters:
  ///   - title: The chip label string.
  ///   - variant: The visual style of the chip.
  ///   - size: The size of the chip.
  ///   - onDismiss: Optional dismiss action.
  public init(
    _ title: some StringProtocol,
    variant: IronChipVariant = .filled,
    size: IronChipSize = .medium,
    onDismiss: (() -> Void)? = nil,
  ) where LeadingIcon == EmptyView {
    self.title = LocalizedStringKey(String(title))
    self.variant = variant
    self.size = size
    self.onDismiss = onDismiss
    leadingIcon = nil
    _isSelected = .constant(nil)
  }

  /// Creates a chip with a system icon.
  ///
  /// - Parameters:
  ///   - title: The chip label.
  ///   - icon: The SF Symbol name.
  ///   - variant: The visual style of the chip.
  ///   - size: The size of the chip.
  ///   - onDismiss: Optional dismiss action.
  public init(
    _ title: LocalizedStringKey,
    icon: String,
    variant: IronChipVariant = .filled,
    size: IronChipSize = .medium,
    onDismiss: (() -> Void)? = nil,
  ) where LeadingIcon == IronIcon {
    self.title = title
    self.variant = variant
    self.size = size
    self.onDismiss = onDismiss
    leadingIcon = IronIcon(systemName: icon, size: Self.iconSize(for: size), color: .primary)
    _isSelected = .constant(nil)
  }

  /// Creates a chip with a custom leading icon.
  ///
  /// - Parameters:
  ///   - title: The chip label.
  ///   - variant: The visual style of the chip.
  ///   - size: The size of the chip.
  ///   - onDismiss: Optional dismiss action.
  ///   - leadingIcon: The custom leading icon view.
  public init(
    _ title: LocalizedStringKey,
    variant: IronChipVariant = .filled,
    size: IronChipSize = .medium,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder leadingIcon: () -> LeadingIcon,
  ) {
    self.title = title
    self.variant = variant
    self.size = size
    self.onDismiss = onDismiss
    self.leadingIcon = leadingIcon()
    _isSelected = .constant(nil)
  }

  /// Creates a selectable chip.
  ///
  /// - Parameters:
  ///   - title: The chip label.
  ///   - isSelected: Binding to the selection state.
  ///   - size: The size of the chip.
  public init(
    _ title: LocalizedStringKey,
    isSelected: Binding<Bool>,
    size: IronChipSize = .medium,
  ) where LeadingIcon == EmptyView {
    self.title = title
    variant = .outlined
    self.size = size
    onDismiss = nil
    leadingIcon = nil
    _isSelected = Binding(
      get: { isSelected.wrappedValue },
      set: { isSelected.wrappedValue = $0 ?? false },
    )
  }

  /// Creates a selectable chip from a string.
  ///
  /// - Parameters:
  ///   - title: The chip label string.
  ///   - isSelected: Binding to the selection state.
  ///   - size: The size of the chip.
  public init(
    _ title: some StringProtocol,
    isSelected: Binding<Bool>,
    size: IronChipSize = .medium,
  ) where LeadingIcon == EmptyView {
    self.title = LocalizedStringKey(String(title))
    variant = .outlined
    self.size = size
    onDismiss = nil
    leadingIcon = nil
    _isSelected = Binding(
      get: { isSelected.wrappedValue },
      set: { isSelected.wrappedValue = $0 ?? false },
    )
  }

  // MARK: Public

  public var body: some View {
    let chipShape = Capsule(style: .continuous)
    let chipBody = HStack(spacing: theme.spacing.xs) {
      if let leadingIcon {
        leadingIcon
          .foregroundStyle(contentColor)
          .accessibilityHidden(true)
      }

      IronText(title, style: textStyle, color: textColorToken)

      if let onDismiss {
        Button {
          withAnimation(shouldAnimate ? theme.animation.snappy : nil) {
            onDismiss()
          }
          IronLogger.ui.debug("IronChip dismissed")
        } label: {
          IronIcon(systemName: "xmark", size: dismissIconSize, color: .secondary)
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true) // Action exposed via parent's accessibilityAction
      }
    }
    .padding(.horizontal, horizontalPadding)
    .padding(.vertical, verticalPadding)
    .background(backgroundColor)
    .clipShape(chipShape)
    .overlay {
      if variant == .outlined || isSelectable {
        chipShape
          .strokeBorder(
            borderColor,
            style: StrokeStyle(
              lineWidth: isSelected == true ? 2 : 1,
              lineCap: .round,
              lineJoin: .round,
            ),
          )
      }
    }
    .scaleEffect(isPressed ? 0.95 : 1.0)
    .accessibleAnimation(theme.animation.snappy, value: isPressed)
    .accessibleAnimation(theme.animation.snappy, value: isSelected)
    .contentShape(Capsule())
    .onTapGesture {
      guard isSelectable else { return }
      withAnimation(shouldAnimate ? theme.animation.bouncy : nil) {
        isSelected?.toggle()
      }
      IronLogger.ui.debug(
        "IronChip selection toggled",
        metadata: ["isSelected": .string("\(isSelected ?? false)")],
      )
    }
    .simultaneousGesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in
          guard isSelectable else { return }
          isPressed = true
        }
        .onEnded { _ in
          guard isSelectable else { return }
          isPressed = false
        }
    )
    .accessibilityElement(children: .combine)
    .accessibilityLabel(Text(title))
    .accessibilityAddTraits(isSelectable || onDismiss != nil ? [.isButton] : [])
    .accessibilityValue(accessibilityValue)
    .accessibilityAction(named: dismissActionLabel) {
      onDismiss?()
    }
    .accessibilityAction {
      if isSelectable {
        isSelected?.toggle()
      }
    }

    if isSelectable || onDismiss != nil {
      chipBody
        .frame(minWidth: minTouchTarget)
        .frame(minHeight: minTouchTarget)
    } else {
      chipBody
    }
  }

  // MARK: Internal

  /// Label for dismiss accessibility action; empty string effectively disables the action
  var dismissActionLabel: String {
    onDismiss != nil ? "Remove" : ""
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.ironSkipEntranceAnimations) private var skipEntranceAnimations

  @Binding private var isSelected: Bool?
  @State private var isPressed = false

  /// Minimum touch target size per Apple HIG (44pt).
  private let minTouchTarget: CGFloat = 44

  private let title: LocalizedStringKey
  private let variant: IronChipVariant
  private let size: IronChipSize
  private let onDismiss: (() -> Void)?
  private let leadingIcon: LeadingIcon?

  private var isSelectable: Bool {
    isSelected != nil
  }

  private var shouldAnimate: Bool {
    !reduceMotion && !skipEntranceAnimations
  }

  private var textStyle: IronTextStyle {
    switch size {
    case .small: .labelSmall
    case .medium: .labelMedium
    case .large: .labelLarge
    }
  }

  private var textColorToken: IronTextColor {
    if isSelected == true {
      return .onPrimary
    }

    switch variant {
    case .filled: return .onSurface
    case .outlined: return .primary
    case .elevated: return .onSurface
    }
  }

  private var dismissIconSize: IronIconSize {
    switch size {
    case .small: .xSmall
    case .medium: .small
    case .large: .medium
    }
  }

  private var horizontalPadding: CGFloat {
    switch size {
    case .small: theme.spacing.sm
    case .medium: theme.spacing.md
    case .large: theme.spacing.lg
    }
  }

  private var verticalPadding: CGFloat {
    switch size {
    case .small: theme.spacing.xs
    case .medium: theme.spacing.sm
    case .large: theme.spacing.sm
    }
  }

  private var backgroundColor: Color {
    if isSelected == true {
      return theme.colors.primary
    }

    switch variant {
    case .filled: return theme.colors.background
    case .outlined: return .clear
    case .elevated: return theme.colors.surfaceElevated
    }
  }

  private var borderColor: Color {
    if isSelected == true {
      return theme.colors.primary
    }
    return theme.colors.border
  }

  private var contentColor: Color {
    if isSelected == true {
      return theme.colors.onPrimary
    }

    switch variant {
    case .filled: return theme.colors.textPrimary
    case .outlined: return theme.colors.primary
    case .elevated: return theme.colors.textPrimary
    }
  }

  private var accessibilityValue: String {
    if let isSelected {
      return isSelected ? "Selected" : "Not selected"
    }
    if onDismiss != nil {
      return "Removable"
    }
    return ""
  }

  private static func iconSize(for size: IronChipSize) -> IronIconSize {
    switch size {
    case .small: .xSmall
    case .medium: .small
    case .large: .medium
    }
  }
}

// MARK: - IronChipVariant

/// Visual style variants for `IronChip`.
public enum IronChipVariant: Sendable, CaseIterable {
  /// A chip with a subtle background fill.
  case filled
  /// A chip with a border and transparent background.
  case outlined
  /// A chip with a subtle shadow.
  case elevated
}

// MARK: - IronChipSize

/// Size options for `IronChip`.
public enum IronChipSize: Sendable, CaseIterable {
  /// A compact chip.
  case small
  /// The default chip size.
  case medium
  /// A larger chip.
  case large
}

// MARK: - Previews

#Preview("IronChip - Basic") {
  HStack(spacing: 8) {
    IronChip("Swift")
    IronChip("SwiftUI")
    IronChip("iOS")
  }
  .padding()
}

#Preview("IronChip - Variants") {
  VStack(spacing: 16) {
    HStack(spacing: 8) {
      IronChip("Filled", variant: .filled)
      IronChip("Outlined", variant: .outlined)
      IronChip("Elevated", variant: .elevated)
    }
  }
  .padding()
}

#Preview("IronChip - Sizes") {
  HStack(spacing: 8) {
    IronChip("Small", size: .small)
    IronChip("Medium", size: .medium)
    IronChip("Large", size: .large)
  }
  .padding()
}

#Preview("IronChip - With Icons") {
  HStack(spacing: 8) {
    IronChip("Location", icon: "mappin")
    IronChip("Calendar", icon: "calendar")
    IronChip("Settings", icon: "gear", variant: .outlined)
  }
  .padding()
}

#Preview("IronChip - Dismissible") {
  @Previewable @State var tags = ["Swift", "SwiftUI", "iOS", "macOS"]

  return HStack(spacing: 8) {
    ForEach(tags, id: \.self) { tag in
      IronChip(tag) {
        withAnimation {
          tags.removeAll { $0 == tag }
        }
      }
    }
  }
  .padding()
}

#Preview("IronChip - Selectable") {
  @Previewable @State var swift = false
  @Previewable @State var swiftUI = true
  @Previewable @State var combine = false

  HStack(spacing: 8) {
    IronChip("Swift", isSelected: $swift)
    IronChip("SwiftUI", isSelected: $swiftUI)
    IronChip("Combine", isSelected: $combine)
  }
  .padding()
}

#Preview("IronChip - Filter Example") {
  @Previewable @State var filters: Set<String> = ["Active"]

  let allFilters = ["All", "Active", "Completed", "Archived"]

  return VStack(alignment: .leading, spacing: 16) {
    IronText("Filters", style: .labelLarge, color: .primary)

    HStack(spacing: 8) {
      ForEach(allFilters, id: \.self) { filter in
        IronChip(
          filter,
          isSelected: Binding(
            get: { filters.contains(filter) },
            set: { isSelected in
              if isSelected {
                filters.insert(filter)
              } else {
                filters.remove(filter)
              }
            },
          ),
        )
      }
    }
  }
  .padding()
}
