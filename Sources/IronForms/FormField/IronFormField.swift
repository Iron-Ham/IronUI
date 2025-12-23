import IronCore
import IronPrimitives
import SwiftUI

// MARK: - IronFormField

/// A form field wrapper that provides consistent labeling, hints, and error display.
///
/// `IronFormField` wraps any input control with optional label, hint text,
/// and error message, providing a consistent form field experience.
///
/// ## Basic Usage
///
/// ```swift
/// @State private var email = ""
///
/// IronFormField("Email", hint: "We'll never share your email") {
///   IronTextField("Enter email", text: $email)
/// }
/// ```
///
/// ## With Error State
///
/// ```swift
/// IronFormField(
///   "Password",
///   error: passwordError
/// ) {
///   IronSecureField("Enter password", text: $password)
/// }
/// ```
///
/// ## Required Fields
///
/// ```swift
/// IronFormField("Username", isRequired: true) {
///   IronTextField("Choose a username", text: $username)
/// }
/// ```
public struct IronFormField<Content: View>: View {

  // MARK: Lifecycle

  /// Creates a form field with a label and content.
  ///
  /// - Parameters:
  ///   - label: The field label.
  ///   - hint: Optional hint text displayed below the input.
  ///   - error: Optional error message (overrides hint when present).
  ///   - isRequired: Whether to show a required indicator.
  ///   - content: The input control.
  public init(
    _ label: LocalizedStringKey,
    hint: LocalizedStringKey? = nil,
    error: String? = nil,
    isRequired: Bool = false,
    @ViewBuilder content: () -> Content,
  ) {
    self.label = label
    self.hint = hint
    self.error = error
    self.isRequired = isRequired
    self.content = content()
  }

  /// Creates a form field with a string label and content.
  ///
  /// - Parameters:
  ///   - label: The field label.
  ///   - hint: Optional hint text displayed below the input.
  ///   - error: Optional error message (overrides hint when present).
  ///   - isRequired: Whether to show a required indicator.
  ///   - content: The input control.
  public init(
    _ label: String,
    hint: String? = nil,
    error: String? = nil,
    isRequired: Bool = false,
    @ViewBuilder content: () -> Content,
  ) {
    self.label = LocalizedStringKey(label)
    self.hint = hint.map { LocalizedStringKey($0) }
    self.error = error
    self.isRequired = isRequired
    self.content = content()
  }

  // MARK: Public

  public var body: some View {
    VStack(alignment: .leading, spacing: theme.spacing.xs) {
      // Label row
      if showLabel {
        HStack(spacing: theme.spacing.xxs) {
          IronText(label, style: .labelMedium, color: labelColor)

          if isRequired {
            IronText("*", style: .labelMedium, color: .error)
          }
        }
      }

      // Content
      content

      // Hint or error message
      if let error {
        HStack(spacing: theme.spacing.xxs) {
          IronIcon(systemName: "exclamationmark.circle.fill", size: .small, color: .error)
          IronText(error, style: .caption, color: .error)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
      } else if let hint {
        IronText(hint, style: .caption, color: .secondary)
      }
    }
    .animation(.easeInOut(duration: 0.2), value: error)
    .accessibilityElement(children: .contain)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private let label: LocalizedStringKey
  private let hint: LocalizedStringKey?
  private let error: String?
  private let isRequired: Bool
  private let content: Content

  private var showLabel: Bool {
    // Label is always shown unless it's empty
    true
  }

  private var labelColor: IronTextColor {
    error != nil ? .error : .secondary
  }
}

// MARK: - IronFormFieldStyle

/// Styles for form field layout.
public enum IronFormFieldStyle: Sendable {
  /// Stacked layout with label above input.
  case stacked
  /// Horizontal layout with label beside input.
  case horizontal
  /// Floating label that animates into the field.
  case floating
}

// MARK: - Previews

#Preview("IronFormField - Basic") {
  VStack(spacing: 24) {
    IronFormField("Email Address", hint: "We'll never share your email") {
      IronTextField("Enter your email", text: .constant(""))
    }

    IronFormField("Username", isRequired: true) {
      IronTextField("Choose a username", text: .constant("john_doe"))
    }

    IronFormField("Password", error: "Password must be at least 8 characters") {
      IronSecureField("Enter password", text: .constant("123"))
    }
  }
  .padding()
}

#Preview("IronFormField - States") {
  VStack(spacing: 24) {
    IronFormField("Normal Field") {
      IronTextField("Enter text", text: .constant(""))
    }

    IronFormField("With Hint", hint: "This is helpful information") {
      IronTextField("Enter text", text: .constant(""))
    }

    IronFormField("Required Field", isRequired: true) {
      IronTextField("Enter text", text: .constant(""))
    }

    IronFormField("With Error", error: "This field is required") {
      IronTextField("Enter text", text: .constant(""))
    }
  }
  .padding()
}

#Preview("IronFormField - Different Inputs") {
  VStack(spacing: 24) {
    IronFormField("Text Input") {
      IronTextField("Enter text", text: .constant("Hello"))
    }

    IronFormField("Secure Input") {
      IronSecureField("Enter password", text: .constant("secret"))
    }

    IronFormField("Toggle Option") {
      IronToggle("Enable notifications", isOn: .constant(true))
    }

    IronFormField("Checkbox Option") {
      IronCheckbox("I agree to the terms", isChecked: .constant(true))
    }
  }
  .padding()
}
