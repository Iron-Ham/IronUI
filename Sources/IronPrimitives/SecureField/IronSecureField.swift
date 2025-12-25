import IronCore
import SwiftUI

// MARK: - IronSecureField

/// A themed secure text input field for passwords and sensitive data.
///
/// `IronSecureField` provides a password entry field with optional
/// visibility toggle, consistent styling, and validation states.
///
/// ## Basic Usage
///
/// ```swift
/// @State private var password = ""
///
/// IronSecureField("Password", text: $password)
/// ```
///
/// ## With Visibility Toggle
///
/// ```swift
/// IronSecureField("Password", text: $password, isToggleVisible: true)
/// ```
///
/// ## Styles
///
/// ```swift
/// IronSecureField("Password", text: $password, style: .outlined)
/// IronSecureField("Password", text: $password, style: .filled)
/// IronSecureField("Password", text: $password, style: .underlined)
/// ```
///
/// ## With Leading Icon
///
/// ```swift
/// IronSecureField("Password", text: $password) {
///   Image(systemName: "lock")
/// }
/// ```
///
/// ## Validation States
///
/// ```swift
/// IronSecureField("Password", text: $password, state: .error("Password too weak"))
/// IronSecureField("Password", text: $password, state: .success)
/// ```
public struct IronSecureField<Leading: View>: View {

  // MARK: Lifecycle

  /// Creates a secure field with a placeholder.
  ///
  /// - Parameters:
  ///   - placeholder: The placeholder text.
  ///   - text: Binding to the text value.
  ///   - style: The visual style of the field.
  ///   - size: The size of the field.
  ///   - state: The validation state.
  ///   - isToggleVisible: Whether to show the visibility toggle.
  public init(
    _ placeholder: LocalizedStringKey,
    text: Binding<String>,
    style: IronTextFieldStyle = .outlined,
    size: IronTextFieldSize = .medium,
    state: IronTextFieldState = .normal,
    isToggleVisible: Bool = true,
  ) where Leading == EmptyView {
    self.placeholder = placeholder
    _text = text
    self.style = style
    self.size = size
    self.state = state
    self.isToggleVisible = isToggleVisible
    leading = nil
  }

  /// Creates a secure field with a placeholder from a string.
  ///
  /// - Parameters:
  ///   - placeholder: The placeholder string.
  ///   - text: Binding to the text value.
  ///   - style: The visual style of the field.
  ///   - size: The size of the field.
  ///   - state: The validation state.
  ///   - isToggleVisible: Whether to show the visibility toggle.
  public init(
    _ placeholder: some StringProtocol,
    text: Binding<String>,
    style: IronTextFieldStyle = .outlined,
    size: IronTextFieldSize = .medium,
    state: IronTextFieldState = .normal,
    isToggleVisible: Bool = true,
  ) where Leading == EmptyView {
    self.placeholder = LocalizedStringKey(String(placeholder))
    _text = text
    self.style = style
    self.size = size
    self.state = state
    self.isToggleVisible = isToggleVisible
    leading = nil
  }

  /// Creates a secure field with a leading accessory.
  ///
  /// - Parameters:
  ///   - placeholder: The placeholder text.
  ///   - text: Binding to the text value.
  ///   - style: The visual style of the field.
  ///   - size: The size of the field.
  ///   - state: The validation state.
  ///   - isToggleVisible: Whether to show the visibility toggle.
  ///   - leading: The leading accessory view.
  public init(
    _ placeholder: LocalizedStringKey,
    text: Binding<String>,
    style: IronTextFieldStyle = .outlined,
    size: IronTextFieldSize = .medium,
    state: IronTextFieldState = .normal,
    isToggleVisible: Bool = true,
    @ViewBuilder leading: () -> Leading,
  ) {
    self.placeholder = placeholder
    _text = text
    self.style = style
    self.size = size
    self.state = state
    self.isToggleVisible = isToggleVisible
    self.leading = leading()
  }

  // MARK: Public

  public var body: some View {
    VStack(alignment: .leading, spacing: theme.spacing.xs) {
      fieldContainer
      errorMessage
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @Environment(\.isEnabled) private var isEnabled
  @FocusState private var isFocused: Bool
  @State private var isRevealed = false

  @Binding private var text: String

  @ScaledMetric(relativeTo: .caption2)
  private var smallHeight: CGFloat = 36

  @ScaledMetric(relativeTo: .body)
  private var mediumHeight: CGFloat = 44

  @ScaledMetric(relativeTo: .title3)
  private var largeHeight: CGFloat = 52

  private let placeholder: LocalizedStringKey
  private let style: IronTextFieldStyle
  private let size: IronTextFieldSize
  private let state: IronTextFieldState
  private let isToggleVisible: Bool
  private let leading: Leading?

  private var fieldContainer: some View {
    HStack(spacing: theme.spacing.sm) {
      if let leading {
        leading
          .foregroundStyle(iconColor)
          .font(iconFont)
      }

      Group {
        if isRevealed {
          TextField(placeholder, text: $text)
        } else {
          SecureField(placeholder, text: $text)
        }
      }
      .textFieldStyle(.plain)
      .font(textFont)
      .focused($isFocused)
      .onChange(of: isFocused) { _, newValue in
        IronLogger.ui.debug(
          "IronSecureField focus changed",
          metadata: ["focused": .string("\(newValue)")],
        )
      }

      if isToggleVisible {
        Button {
          withAnimation(theme.animation.snappy) {
            isRevealed.toggle()
          }
          IronLogger.ui.debug(
            "IronSecureField visibility toggled",
            metadata: ["revealed": .string("\(isRevealed)")],
          )
        } label: {
          Image(systemName: isRevealed ? "eye.slash" : "eye")
            .foregroundStyle(iconColor)
            .font(iconFont)
            .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
      }
    }
    .padding(.horizontal, horizontalPadding)
    .frame(height: fieldHeight)
    .background {
      switch style {
      case .outlined, .filled:
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(backgroundColor)

      case .underlined:
        Rectangle()
          .fill(backgroundColor)
      }
    }
    .overlay {
      switch style {
      case .outlined:
        RoundedRectangle(cornerRadius: cornerRadius)
          .strokeBorder(borderColor, lineWidth: isFocused ? 2 : 1)

      case .filled:
        EmptyView()

      case .underlined:
        VStack {
          Spacer()
          Rectangle()
            .fill(borderColor)
            .frame(height: isFocused ? 2 : 1)
        }
      }
    }
    .scaleEffect(isFocused ? 1.01 : 1.0)
    .animation(theme.animation.snappy, value: isFocused)
  }

  @ViewBuilder
  private var errorMessage: some View {
    if case .error(let message) = state {
      IronText(message, style: .caption, color: .error)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
  }

  private var fieldHeight: CGFloat {
    switch size {
    case .small: smallHeight
    case .medium: mediumHeight
    case .large: largeHeight
    }
  }

  private var horizontalPadding: CGFloat {
    switch size {
    case .small: theme.spacing.sm
    case .medium: theme.spacing.md
    case .large: theme.spacing.lg
    }
  }

  private var cornerRadius: CGFloat {
    switch size {
    case .small: theme.radii.sm
    case .medium: theme.radii.md
    case .large: theme.radii.lg
    }
  }

  private var textFont: Font {
    switch size {
    case .small: theme.typography.bodySmall
    case .medium: theme.typography.bodyMedium
    case .large: theme.typography.bodyLarge
    }
  }

  private var iconFont: Font {
    switch size {
    case .small: theme.typography.labelSmall
    case .medium: theme.typography.labelMedium
    case .large: theme.typography.labelLarge
    }
  }

  private var backgroundColor: Color {
    switch style {
    case .outlined:
      Color.clear

    case .filled:
      isEnabled
        ? theme.colors.surface
        : theme.colors.surface.opacity(0.5)

    case .underlined:
      Color.clear
    }
  }

  private var borderColor: Color {
    if !isEnabled {
      return theme.colors.border.opacity(0.5)
    }

    switch state {
    case .normal:
      return isFocused ? theme.colors.primary : theme.colors.border

    case .success:
      return theme.colors.success

    case .error:
      return theme.colors.error
    }
  }

  private var iconColor: Color {
    if !isEnabled {
      return theme.colors.textDisabled
    }

    switch state {
    case .normal:
      return isFocused ? theme.colors.primary : theme.colors.textSecondary

    case .success:
      return theme.colors.success

    case .error:
      return theme.colors.error
    }
  }
}

// MARK: - Previews

#Preview("IronSecureField - Basic") {
  @Previewable @State var password = ""

  return VStack(spacing: 16) {
    IronSecureField("Password", text: $password)
    IronSecureField("With text", text: .constant("secret123"))
  }
  .padding()
}

#Preview("IronSecureField - Styles") {
  @Previewable @State var text1 = ""
  @Previewable @State var text2 = ""
  @Previewable @State var text3 = ""

  return VStack(spacing: 24) {
    VStack(alignment: .leading) {
      Text("Outlined").font(.caption).foregroundStyle(.secondary)
      IronSecureField("Password", text: $text1, style: .outlined)
    }

    VStack(alignment: .leading) {
      Text("Filled").font(.caption).foregroundStyle(.secondary)
      IronSecureField("Password", text: $text2, style: .filled)
    }

    VStack(alignment: .leading) {
      Text("Underlined").font(.caption).foregroundStyle(.secondary)
      IronSecureField("Password", text: $text3, style: .underlined)
    }
  }
  .padding()
}

#Preview("IronSecureField - Sizes") {
  @Previewable @State var text = ""

  return VStack(spacing: 16) {
    IronSecureField("Small", text: $text, size: .small)
    IronSecureField("Medium", text: $text, size: .medium)
    IronSecureField("Large", text: $text, size: .large)
  }
  .padding()
}

#Preview("IronSecureField - States") {
  @Previewable @State var normal = ""
  @Previewable @State var success = "strongPassword123!"
  @Previewable @State var error = "weak"

  return VStack(spacing: 16) {
    IronSecureField("Normal", text: $normal, state: .normal)
    IronSecureField("Success", text: $success, state: .success)
    IronSecureField("Error", text: $error, state: .error("Password must be at least 8 characters"))
  }
  .padding()
}

#Preview("IronSecureField - With Leading Icon") {
  @Previewable @State var password = ""

  return VStack(spacing: 16) {
    IronSecureField("Password", text: $password, leading: {
      Image(systemName: "lock")
    })

    IronSecureField("PIN", text: $password, leading: {
      Image(systemName: "number")
    })
  }
  .padding()
}

#Preview("IronSecureField - Without Toggle") {
  @Previewable @State var password = ""

  return VStack(spacing: 16) {
    IronSecureField("With toggle", text: $password, isToggleVisible: true)
    IronSecureField("Without toggle", text: $password, isToggleVisible: false)
  }
  .padding()
}

#Preview("IronSecureField - Login Form") {
  @Previewable @State var email = ""
  @Previewable @State var password = ""

  return VStack(spacing: 16) {
    IronTextField("Email", text: $email, leading: {
      Image(systemName: "envelope")
    })

    IronSecureField("Password", text: $password, leading: {
      Image(systemName: "lock")
    })

    IronButton("Sign In", isFullWidth: true) {
      // Sign in action
    }
  }
  .padding()
}
