import IronCore
import IronPrimitives
import SwiftUI

// MARK: - IronForm

/// A form container that organizes fields into sections with consistent spacing.
///
/// `IronForm` provides a scrollable container for form content with
/// support for sections, headers, and footers.
///
/// ## Basic Usage
///
/// ```swift
/// IronForm {
///   IronFormSection("Account") {
///     IronFormField("Email") {
///       IronTextField("Enter email", text: $email)
///     }
///     IronFormField("Password") {
///       IronSecureField("Enter password", text: $password)
///     }
///   }
/// }
/// ```
///
/// ## With Multiple Sections
///
/// ```swift
/// IronForm {
///   IronFormSection("Personal Info") {
///     IronFormField("Name") { ... }
///     IronFormField("Email") { ... }
///   }
///
///   IronFormSection("Preferences") {
///     IronFormField("Notifications") { ... }
///     IronFormField("Theme") { ... }
///   }
/// }
/// ```
public struct IronForm<Content: View>: View {

  // MARK: Lifecycle

  /// Creates a form with the given content.
  ///
  /// - Parameters:
  ///   - spacing: Spacing between sections.
  ///   - content: The form content (sections and fields).
  public init(
    spacing: CGFloat? = nil,
    @ViewBuilder content: () -> Content,
  ) {
    self.spacing = spacing
    self.content = content()
  }

  // MARK: Public

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: spacing ?? theme.spacing.xl) {
        content
      }
      .padding(.horizontal, theme.spacing.md)
      .padding(.vertical, theme.spacing.lg)
    }
    .background(theme.colors.surface.opacity(0.5))
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private let spacing: CGFloat?
  private let content: Content
}

// MARK: - IronFormSection

/// A section within an IronForm that groups related fields.
///
/// ```swift
/// IronFormSection("Account Settings") {
///   IronFormField("Email") { ... }
///   IronFormField("Password") { ... }
/// }
/// ```
public struct IronFormSection<Content: View>: View {

  // MARK: Lifecycle

  /// Creates a form section with a header and content.
  ///
  /// - Parameters:
  ///   - header: The section header text.
  ///   - footer: Optional footer text.
  ///   - content: The section content.
  public init(
    _ header: LocalizedStringKey,
    footer: LocalizedStringKey? = nil,
    @ViewBuilder content: () -> Content,
  ) {
    self.header = header
    self.footer = footer
    self.content = content()
  }

  /// Creates a form section with a string header and content.
  ///
  /// - Parameters:
  ///   - header: The section header string.
  ///   - footer: Optional footer text.
  ///   - content: The section content.
  public init(
    _ header: String,
    footer: String? = nil,
    @ViewBuilder content: () -> Content,
  ) {
    self.header = LocalizedStringKey(header)
    self.footer = footer.map { LocalizedStringKey($0) }
    self.content = content()
  }

  /// Creates a form section without a header.
  ///
  /// - Parameters:
  ///   - footer: Optional footer text.
  ///   - content: The section content.
  public init(
    footer: LocalizedStringKey? = nil,
    @ViewBuilder content: () -> Content,
  ) {
    header = nil
    self.footer = footer
    self.content = content()
  }

  // MARK: Public

  public var body: some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      // Section header
      if let header {
        IronText(header, style: .headlineMedium, color: .primary)
          .padding(.bottom, theme.spacing.xxs)
      }

      // Section content in a card
      VStack(alignment: .leading, spacing: theme.spacing.md) {
        content
      }
      .padding(theme.spacing.md)
      .background(theme.colors.background)
      .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg))

      // Section footer
      if let footer {
        IronText(footer, style: .caption, color: .secondary)
          .padding(.horizontal, theme.spacing.xs)
      }
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private let header: LocalizedStringKey?
  private let footer: LocalizedStringKey?
  private let content: Content
}

// MARK: - IronFormRow

/// A horizontal row within a form section for side-by-side fields.
///
/// ```swift
/// IronFormRow {
///   IronFormField("First Name") { ... }
///   IronFormField("Last Name") { ... }
/// }
/// ```
public struct IronFormRow<Content: View>: View {

  // MARK: Lifecycle

  /// Creates a form row with horizontal content.
  ///
  /// - Parameters:
  ///   - spacing: Spacing between items.
  ///   - content: The row content.
  public init(
    spacing: CGFloat? = nil,
    @ViewBuilder content: () -> Content,
  ) {
    self.spacing = spacing
    self.content = content()
  }

  // MARK: Public

  public var body: some View {
    HStack(alignment: .top, spacing: spacing ?? theme.spacing.md) {
      content
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private let spacing: CGFloat?
  private let content: Content
}

// MARK: - IronFormDivider

/// A divider for separating content within a form section.
public struct IronFormDivider: View {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  public var body: some View {
    IronDivider()
      .padding(.vertical, theme.spacing.xs)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
}

// MARK: - Previews

#Preview("IronForm - Basic") {
  IronForm {
    IronFormSection("Account") {
      IronFormField("Email", hint: "Your login email") {
        IronTextField("Enter email", text: .constant(""))
      }

      IronFormField("Password", isRequired: true) {
        IronSecureField("Enter password", text: .constant(""))
      }
    }

    IronFormSection("Profile", footer: "This information will be visible to other users") {
      IronFormField("Display Name") {
        IronTextField("Enter name", text: .constant("John Doe"))
      }

      IronFormField("Bio") {
        IronTextField("Tell us about yourself", text: .constant(""))
      }
    }
  }
}

#Preview("IronForm - With Rows") {
  IronForm {
    IronFormSection("Personal Information") {
      IronFormRow {
        IronFormField("First Name") {
          IronTextField("First", text: .constant("John"))
        }
        IronFormField("Last Name") {
          IronTextField("Last", text: .constant("Doe"))
        }
      }

      IronFormField("Email") {
        IronTextField("Enter email", text: .constant("john@example.com"))
      }

      IronFormDivider()

      IronFormField("Phone") {
        IronTextField("Enter phone", text: .constant(""))
      }
    }
  }
}

#Preview("IronForm - Settings Style") {
  IronForm {
    IronFormSection("Notifications") {
      IronFormField("Push Notifications") {
        IronToggle("Enable push notifications", isOn: .constant(true))
      }

      IronFormField("Email Notifications") {
        IronToggle("Receive email updates", isOn: .constant(false))
      }
    }

    IronFormSection("Privacy") {
      IronFormField("Profile Visibility") {
        IronToggle("Make profile public", isOn: .constant(true))
      }

      IronFormField("Activity Status") {
        IronToggle("Show when I'm active", isOn: .constant(false))
      }
    }
  }
}
