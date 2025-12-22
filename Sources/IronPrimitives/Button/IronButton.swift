import IronCore
import SwiftUI

// MARK: - IronButton

/// A customizable button component that adapts to the current theme.
///
/// `IronButton` provides a consistent button experience across your app
/// with support for multiple variants, sizes, and automatic theming.
///
/// ## Basic Usage
///
/// ```swift
/// IronButton("Submit") {
///   submitForm()
/// }
/// ```
///
/// ## Variants
///
/// ```swift
/// IronButton("Primary", variant: .filled) { }
/// IronButton("Secondary", variant: .outlined) { }
/// IronButton("Tertiary", variant: .ghost) { }
/// IronButton("Elevated", variant: .elevated) { }
/// ```
///
/// ## Sizes
///
/// ```swift
/// IronButton("Small", size: .small) { }
/// IronButton("Medium", size: .medium) { }
/// IronButton("Large", size: .large) { }
/// ```
///
/// ## Custom Labels
///
/// ```swift
/// IronButton {
///   processData()
/// } label: {
///   HStack {
///     Image(systemName: "arrow.up.circle")
///     Text("Upload")
///   }
/// }
/// ```
public struct IronButton<Label: View>: View {

  // MARK: Lifecycle

  /// Creates a button with a custom label.
  ///
  /// - Parameters:
  ///   - variant: The visual style of the button.
  ///   - size: The size of the button.
  ///   - isFullWidth: Whether the button should expand to fill available width.
  ///   - action: The action to perform when the button is tapped.
  ///   - label: A view builder that creates the button's label.
  public init(
    variant: IronButtonVariant = .filled,
    size: IronButtonSize = .medium,
    isFullWidth: Bool = false,
    action: @escaping () -> Void,
    @ViewBuilder label: () -> Label,
  ) {
    self.variant = variant
    self.size = size
    self.isFullWidth = isFullWidth
    self.action = action
    self.label = label()
  }

  // MARK: Public

  public var body: some View {
    Button(action: action) {
      label
        .contentTransition(.interpolate)
    }
    .buttonStyle(
      IronButtonStyleInternal(
        variant: variant,
        size: size,
        isFullWidth: isFullWidth,
        theme: theme,
      )
    )
    .disabled(!isEnabled)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @Environment(\.isEnabled) private var isEnabled

  private let variant: IronButtonVariant
  private let size: IronButtonSize
  private let isFullWidth: Bool
  private let action: () -> Void
  private let label: Label

}

// MARK: - Convenience Initializers

extension IronButton where Label == Text {
  /// Creates a button with a text label.
  ///
  /// - Parameters:
  ///   - title: The text to display in the button.
  ///   - variant: The visual style of the button.
  ///   - size: The size of the button.
  ///   - isFullWidth: Whether the button should expand to fill available width.
  ///   - action: The action to perform when the button is tapped.
  public init(
    _ title: LocalizedStringKey,
    variant: IronButtonVariant = .filled,
    size: IronButtonSize = .medium,
    isFullWidth: Bool = false,
    action: @escaping () -> Void,
  ) {
    self.variant = variant
    self.size = size
    self.isFullWidth = isFullWidth
    self.action = action
    label = Text(title)
  }

  /// Creates a button with a text label from a string.
  ///
  /// - Parameters:
  ///   - title: The string to display in the button.
  ///   - variant: The visual style of the button.
  ///   - size: The size of the button.
  ///   - isFullWidth: Whether the button should expand to fill available width.
  ///   - action: The action to perform when the button is tapped.
  public init(
    _ title: some StringProtocol,
    variant: IronButtonVariant = .filled,
    size: IronButtonSize = .medium,
    isFullWidth: Bool = false,
    action: @escaping () -> Void,
  ) {
    self.variant = variant
    self.size = size
    self.isFullWidth = isFullWidth
    self.action = action
    label = Text(title)
  }
}

// MARK: - IronButtonVariant

/// The visual style variants for `IronButton`.
public enum IronButtonVariant: Sendable, CaseIterable {
  /// A solid button with the primary color background.
  case filled
  /// A button with a border and transparent background.
  case outlined
  /// A text-only button with no visible container.
  case ghost
  /// A solid button with an elevated shadow.
  case elevated
}

// MARK: - IronButtonSize

/// The size options for `IronButton`.
public enum IronButtonSize: Sendable, CaseIterable {
  /// A compact button for tight spaces.
  case small
  /// The default button size.
  case medium
  /// A larger button for prominent actions.
  case large
}

// MARK: - IronButtonStyleInternal

/// Internal button style that applies theming and handles press states.
struct IronButtonStyleInternal: ButtonStyle {

  // MARK: Internal

  let variant: IronButtonVariant
  let size: IronButtonSize
  let isFullWidth: Bool
  let theme: AnyIronTheme

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(font)
      .fontWeight(.medium)
      .padding(.horizontal, horizontalPadding)
      .padding(.vertical, verticalPadding)
      .frame(maxWidth: isFullWidth ? .infinity : nil)
      .frame(minWidth: minTouchTarget, minHeight: minTouchTarget)
      .foregroundStyle(foregroundColor)
      .background(background(isPressed: configuration.isPressed))
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      .overlay {
        if variant == .outlined {
          RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(theme.colors.primary, lineWidth: 1.5)
        }
      }
      .shadow(
        color: shadowColor(isPressed: configuration.isPressed),
        radius: shadowRadius(isPressed: configuration.isPressed),
        y: shadowY(isPressed: configuration.isPressed),
      )
      .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
      .animation(theme.animation.snappy, value: configuration.isPressed)
  }

  // MARK: Private

  /// Minimum touch target size per Apple HIG (44pt).
  private let minTouchTarget: CGFloat = 44

  private var font: Font {
    switch size {
    case .small:
      theme.typography.labelMedium
    case .medium:
      theme.typography.labelLarge
    case .large:
      theme.typography.bodyLarge
    }
  }

  private var horizontalPadding: CGFloat {
    switch size {
    case .small:
      theme.spacing.sm
    case .medium:
      theme.spacing.md
    case .large:
      theme.spacing.lg
    }
  }

  private var verticalPadding: CGFloat {
    switch size {
    case .small:
      theme.spacing.xs
    case .medium:
      theme.spacing.sm
    case .large:
      theme.spacing.md
    }
  }

  private var cornerRadius: CGFloat {
    switch size {
    case .small:
      theme.radii.sm
    case .medium:
      theme.radii.md
    case .large:
      theme.radii.lg
    }
  }

  private var foregroundColor: Color {
    switch variant {
    case .filled, .elevated:
      theme.colors.onPrimary
    case .outlined, .ghost:
      theme.colors.primary
    }
  }

  private var pressedScale: CGFloat {
    switch variant {
    case .filled, .elevated:
      0.97
    case .outlined, .ghost:
      0.98
    }
  }

  private func background(isPressed: Bool) -> Color {
    switch variant {
    case .filled:
      isPressed ? theme.colors.primaryVariant : theme.colors.primary
    case .outlined:
      isPressed ? theme.colors.primary.opacity(0.08) : .clear
    case .ghost:
      isPressed ? theme.colors.primary.opacity(0.08) : .clear
    case .elevated:
      isPressed ? theme.colors.primaryVariant : theme.colors.primary
    }
  }

  private func shadowColor(isPressed: Bool) -> Color {
    guard variant == .elevated else { return .clear }
    return isPressed
      ? theme.colors.primary.opacity(0.15)
      : theme.colors.primary.opacity(0.3)
  }

  private func shadowRadius(isPressed: Bool) -> CGFloat {
    guard variant == .elevated else { return 0 }
    return isPressed ? 4 : 8
  }

  private func shadowY(isPressed: Bool) -> CGFloat {
    guard variant == .elevated else { return 0 }
    return isPressed ? 2 : 4
  }
}

// MARK: - Previews

#Preview("IronButton - Variants") {
  VStack(spacing: 16) {
    ForEach(IronButtonVariant.allCases, id: \.self) { variant in
      IronButton("\(variant)".capitalized, variant: variant) { }
    }
  }
  .padding()
}

#Preview("IronButton - Sizes") {
  VStack(spacing: 16) {
    ForEach(IronButtonSize.allCases, id: \.self) { size in
      IronButton("\(size)".capitalized, size: size) { }
    }
  }
  .padding()
}

#Preview("IronButton - Full Width") {
  VStack(spacing: 16) {
    IronButton("Full Width Button", isFullWidth: true) { }
    IronButton("Full Width Outlined", variant: .outlined, isFullWidth: true) { }
  }
  .padding()
}

#Preview("IronButton - Disabled") {
  VStack(spacing: 16) {
    IronButton("Enabled") { }
    IronButton("Disabled") { }
      .disabled(true)
  }
  .padding()
}

#Preview("IronButton - Custom Label") {
  IronButton {
    // Action
  } label: {
    HStack(spacing: 8) {
      Image(systemName: "arrow.up.circle.fill")
      Text("Upload")
    }
  }
  .padding()
}
