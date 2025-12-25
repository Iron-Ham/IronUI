import IronCore
import SwiftUI

// MARK: - IronTextField

/// A themed text input field with consistent styling and animations.
///
/// `IronTextField` provides a customizable text input with support for
/// multiple styles, validation states, and leading/trailing accessories.
///
/// ## Basic Usage
///
/// ```swift
/// @State private var email = ""
///
/// IronTextField("Email", text: $email)
/// ```
///
/// ## Styles
///
/// ```swift
/// IronTextField("Outlined", text: $text, style: .outlined)
/// IronTextField("Filled", text: $text, style: .filled)
/// IronTextField("Underlined", text: $text, style: .underlined)
/// ```
///
/// ## With Icons
///
/// ```swift
/// IronTextField("Search", text: $query) {
///   Image(systemName: "magnifyingglass")
/// }
///
/// IronTextField("Password", text: $password) {
///   Image(systemName: "lock")
/// } trailing: {
///   Button { showPassword.toggle() } label: {
///     Image(systemName: showPassword ? "eye.slash" : "eye")
///   }
/// }
/// ```
///
/// ## Validation States
///
/// ```swift
/// IronTextField("Email", text: $email, state: .error("Invalid email"))
/// IronTextField("Username", text: $username, state: .success)
/// ```
public struct IronTextField<Leading: View, Trailing: View>: View {

  // MARK: Lifecycle

  /// Creates a text field with a placeholder.
  ///
  /// - Parameters:
  ///   - placeholder: The placeholder text.
  ///   - text: Binding to the text value.
  ///   - style: The visual style of the text field.
  ///   - size: The size of the text field.
  ///   - state: The validation state.
  public init(
    _ placeholder: LocalizedStringKey,
    text: Binding<String>,
    style: IronTextFieldStyle = .outlined,
    size: IronTextFieldSize = .medium,
    state: IronTextFieldState = .normal,
  ) where Leading == EmptyView, Trailing == EmptyView {
    self.placeholder = placeholder
    _text = text
    self.style = style
    self.size = size
    self.state = state
    leading = nil
    trailing = nil
  }

  /// Creates a text field with a placeholder from a string.
  ///
  /// - Parameters:
  ///   - placeholder: The placeholder string.
  ///   - text: Binding to the text value.
  ///   - style: The visual style of the text field.
  ///   - size: The size of the text field.
  ///   - state: The validation state.
  public init(
    _ placeholder: some StringProtocol,
    text: Binding<String>,
    style: IronTextFieldStyle = .outlined,
    size: IronTextFieldSize = .medium,
    state: IronTextFieldState = .normal,
  ) where Leading == EmptyView, Trailing == EmptyView {
    self.placeholder = LocalizedStringKey(String(placeholder))
    _text = text
    self.style = style
    self.size = size
    self.state = state
    leading = nil
    trailing = nil
  }

  /// Creates a text field with a leading accessory.
  ///
  /// - Parameters:
  ///   - placeholder: The placeholder text.
  ///   - text: Binding to the text value.
  ///   - style: The visual style of the text field.
  ///   - size: The size of the text field.
  ///   - state: The validation state.
  ///   - leading: The leading accessory view.
  public init(
    _ placeholder: LocalizedStringKey,
    text: Binding<String>,
    style: IronTextFieldStyle = .outlined,
    size: IronTextFieldSize = .medium,
    state: IronTextFieldState = .normal,
    @ViewBuilder leading: () -> Leading,
  ) where Trailing == EmptyView {
    self.placeholder = placeholder
    _text = text
    self.style = style
    self.size = size
    self.state = state
    self.leading = leading()
    trailing = nil
  }

  /// Creates a text field with leading and trailing accessories.
  ///
  /// - Parameters:
  ///   - placeholder: The placeholder text.
  ///   - text: Binding to the text value.
  ///   - style: The visual style of the text field.
  ///   - size: The size of the text field.
  ///   - state: The validation state.
  ///   - leading: The leading accessory view.
  ///   - trailing: The trailing accessory view.
  public init(
    _ placeholder: LocalizedStringKey,
    text: Binding<String>,
    style: IronTextFieldStyle = .outlined,
    size: IronTextFieldSize = .medium,
    state: IronTextFieldState = .normal,
    @ViewBuilder leading: () -> Leading,
    @ViewBuilder trailing: () -> Trailing,
  ) {
    self.placeholder = placeholder
    _text = text
    self.style = style
    self.size = size
    self.state = state
    self.leading = leading()
    self.trailing = trailing()
  }

  /// Creates a text field with a trailing accessory only.
  ///
  /// - Parameters:
  ///   - placeholder: The placeholder text.
  ///   - text: Binding to the text value.
  ///   - style: The visual style of the text field.
  ///   - size: The size of the text field.
  ///   - state: The validation state.
  ///   - trailing: The trailing accessory view.
  public init(
    _ placeholder: LocalizedStringKey,
    text: Binding<String>,
    style: IronTextFieldStyle = .outlined,
    size: IronTextFieldSize = .medium,
    state: IronTextFieldState = .normal,
    @ViewBuilder trailing: () -> Trailing,
  ) where Leading == EmptyView {
    self.placeholder = placeholder
    _text = text
    self.style = style
    self.size = size
    self.state = state
    leading = nil
    self.trailing = trailing()
  }

  // MARK: Public

  public var body: some View {
    VStack(alignment: .leading, spacing: theme.spacing.xs) {
      fieldContainer
      errorMessage
    }
    .accessibilityElement(children: .contain)
    .accessibilityValue(accessibilityStateValue)
  }

  // MARK: Internal

  /// Accessibility value describing the validation state
  var accessibilityStateValue: String {
    switch state {
    case .normal:
      ""
    case .success:
      "Valid"
    case .error(let message):
      "Error: \(message)"
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @Environment(\.isEnabled) private var isEnabled
  @FocusState private var isFocused: Bool

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
  private let leading: Leading?
  private let trailing: Trailing?

  private var fieldContainer: some View {
    HStack(spacing: theme.spacing.sm) {
      if let leading {
        leading
          .foregroundStyle(iconColor)
          .font(iconFont)
      }

      TextField(placeholder, text: $text)
        .textFieldStyle(.plain)
        .font(textFont)
        .focused($isFocused)
        .onChange(of: isFocused) { _, newValue in
          IronLogger.ui.debug(
            "IronTextField focus changed",
            metadata: ["focused": .string("\(newValue)")],
          )
        }

      if let trailing {
        trailing
          .foregroundStyle(iconColor)
          .font(iconFont)
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
    .accessibleAnimation(theme.animation.snappy, value: isFocused)
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

// MARK: - IronTextFieldStyle

/// Visual styles for `IronTextField`.
public enum IronTextFieldStyle: Sendable, CaseIterable {
  /// A text field with a rounded border.
  case outlined
  /// A text field with a filled background.
  case filled
  /// A text field with only an underline.
  case underlined
}

// MARK: - IronTextFieldSize

/// Size options for `IronTextField`.
public enum IronTextFieldSize: Sendable, CaseIterable {
  /// A compact text field.
  case small
  /// The default text field size.
  case medium
  /// A larger text field for prominent inputs.
  case large
}

// MARK: - IronTextFieldState

/// Validation states for `IronTextField`.
public enum IronTextFieldState: Sendable, Equatable {
  /// Normal state with no validation feedback.
  case normal
  /// Success state indicating valid input.
  case success
  /// Error state with a message.
  case error(String)
}

// MARK: - Previews

#Preview("IronTextField - Basic") {
  @Previewable @State var text = ""

  return VStack(spacing: 16) {
    IronTextField("Enter your name", text: $text)
    IronTextField("With some text", text: .constant("Hello World"))
  }
  .padding()
}

#Preview("IronTextField - Styles") {
  @Previewable @State var text1 = ""
  @Previewable @State var text2 = ""
  @Previewable @State var text3 = ""

  return VStack(spacing: 24) {
    VStack(alignment: .leading) {
      Text("Outlined").font(.caption).foregroundStyle(.secondary)
      IronTextField("Outlined style", text: $text1, style: .outlined)
    }

    VStack(alignment: .leading) {
      Text("Filled").font(.caption).foregroundStyle(.secondary)
      IronTextField("Filled style", text: $text2, style: .filled)
    }

    VStack(alignment: .leading) {
      Text("Underlined").font(.caption).foregroundStyle(.secondary)
      IronTextField("Underlined style", text: $text3, style: .underlined)
    }
  }
  .padding()
}

#Preview("IronTextField - Sizes") {
  @Previewable @State var text = ""

  return VStack(spacing: 16) {
    IronTextField("Small", text: $text, size: .small)
    IronTextField("Medium", text: $text, size: .medium)
    IronTextField("Large", text: $text, size: .large)
  }
  .padding()
}

#Preview("IronTextField - States") {
  @Previewable @State var normal = ""
  @Previewable @State var success = "valid@email.com"
  @Previewable @State var error = "invalid"

  return VStack(spacing: 16) {
    IronTextField("Normal", text: $normal, state: .normal)
    IronTextField("Success", text: $success, state: .success)
    IronTextField("Error", text: $error, state: .error("Please enter a valid email"))
  }
  .padding()
}

#Preview("IronTextField - With Icons") {
  @Previewable @State var email = ""
  @Previewable @State var search = ""
  @Previewable @State var password = ""
  @Previewable @State var showPassword = false

  return VStack(spacing: 16) {
    IronTextField("Email", text: $email, leading: {
      Image(systemName: "envelope")
    })

    IronTextField("Search", text: $search, leading: {
      Image(systemName: "magnifyingglass")
    }, trailing: {
      if !search.isEmpty {
        Button {
          search = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
        }
        .buttonStyle(.plain)
      }
    })

    IronTextField("Password", text: $password, leading: {
      Image(systemName: "lock")
    }, trailing: {
      Button {
        showPassword.toggle()
      } label: {
        Image(systemName: showPassword ? "eye.slash" : "eye")
      }
      .buttonStyle(.plain)
    })
  }
  .padding()
}

#Preview("IronTextField - Disabled") {
  VStack(spacing: 16) {
    IronTextField("Disabled field", text: .constant("Cannot edit"))
      .disabled(true)

    IronTextField("Disabled outlined", text: .constant(""), style: .outlined)
      .disabled(true)

    IronTextField("Disabled filled", text: .constant(""), style: .filled)
      .disabled(true)
  }
  .padding()
}

#Preview("IronTextField - Form Example") {
  @Previewable @State var firstName = ""
  @Previewable @State var lastName = ""
  @Previewable @State var email = ""
  @Previewable @State var phone = ""

  return VStack(spacing: 16) {
    HStack(spacing: 12) {
      IronTextField("First name", text: $firstName)
      IronTextField("Last name", text: $lastName)
    }

    IronTextField("Email", text: $email, leading: {
      Image(systemName: "envelope")
    })

    IronTextField("Phone", text: $phone, leading: {
      Image(systemName: "phone")
    })

    IronButton("Submit", isFullWidth: true) {
      // Submit action
    }
  }
  .padding()
}
