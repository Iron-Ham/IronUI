import IronCore
import SwiftUI

// MARK: - IronAlert

/// A themed inline alert for displaying messages, warnings, and notifications.
///
/// `IronAlert` provides a customizable alert banner with semantic colors,
/// icons, and optional dismiss functionality.
///
/// ## Basic Usage
///
/// ```swift
/// IronAlert("Your changes have been saved", variant: .success)
/// IronAlert("Please check your input", variant: .warning)
/// IronAlert("An error occurred", variant: .error)
/// IronAlert("Tip: You can drag to reorder", variant: .info)
/// ```
///
/// ## With Title
///
/// ```swift
/// IronAlert(
///   "Update Available",
///   message: "A new version is ready to install",
///   variant: .info
/// )
/// ```
///
/// ## Dismissible Alert
///
/// ```swift
/// IronAlert("Notification", variant: .info, onDismiss: {
///   // Handle dismiss
/// })
/// ```
///
/// ## With Custom Actions
///
/// ```swift
/// IronAlert("Update Available", variant: .info, actions: {
///   Button("Update Now") { }
///   Button("Later") { }
/// })
/// ```
///
/// ## With Custom Icon
///
/// ```swift
/// IronAlert("Custom notification", variant: .info, icon: {
///   AsyncImage(url: iconURL) { image in
///     image.resizable().frame(width: 20, height: 20)
///   } placeholder: {
///     ProgressView()
///   }
/// })
/// ```
public struct IronAlert<Icon: View, Actions: View>: View {

  // MARK: Lifecycle

  /// Creates an alert with a message.
  ///
  /// - Parameters:
  ///   - message: The alert message.
  ///   - variant: The semantic variant of the alert.
  public init(
    _ message: LocalizedStringKey,
    variant: IronAlertVariant = .info,
  ) where Icon == IronIcon, Actions == EmptyView {
    title = nil
    self.message = message
    self.variant = variant
    customIcon = nil
    onDismiss = nil
    actions = nil
  }

  /// Creates an alert with a message from a string.
  ///
  /// - Parameters:
  ///   - message: The alert message string.
  ///   - variant: The semantic variant of the alert.
  public init(
    _ message: some StringProtocol,
    variant: IronAlertVariant = .info,
  ) where Icon == IronIcon, Actions == EmptyView {
    title = nil
    self.message = LocalizedStringKey(String(message))
    self.variant = variant
    customIcon = nil
    onDismiss = nil
    actions = nil
  }

  /// Creates an alert with a title and message.
  ///
  /// - Parameters:
  ///   - title: The alert title.
  ///   - message: The alert message.
  ///   - variant: The semantic variant of the alert.
  public init(
    _ title: LocalizedStringKey,
    message: LocalizedStringKey,
    variant: IronAlertVariant = .info,
  ) where Icon == IronIcon, Actions == EmptyView {
    self.title = title
    self.message = message
    self.variant = variant
    customIcon = nil
    onDismiss = nil
    actions = nil
  }

  /// Creates a dismissible alert.
  ///
  /// - Parameters:
  ///   - message: The alert message.
  ///   - variant: The semantic variant of the alert.
  ///   - onDismiss: Called when the dismiss button is tapped.
  public init(
    _ message: LocalizedStringKey,
    variant: IronAlertVariant = .info,
    onDismiss: @escaping () -> Void,
  ) where Icon == IronIcon, Actions == EmptyView {
    title = nil
    self.message = message
    self.variant = variant
    customIcon = nil
    self.onDismiss = onDismiss
    actions = nil
  }

  /// Creates an alert with title, message, and dismiss action.
  ///
  /// - Parameters:
  ///   - title: The alert title.
  ///   - message: The alert message.
  ///   - variant: The semantic variant of the alert.
  ///   - onDismiss: Called when the dismiss button is tapped.
  public init(
    _ title: LocalizedStringKey,
    message: LocalizedStringKey,
    variant: IronAlertVariant = .info,
    onDismiss: @escaping () -> Void,
  ) where Icon == IronIcon, Actions == EmptyView {
    self.title = title
    self.message = message
    self.variant = variant
    customIcon = nil
    self.onDismiss = onDismiss
    actions = nil
  }

  /// Creates an alert with custom actions.
  ///
  /// - Parameters:
  ///   - message: The alert message.
  ///   - variant: The semantic variant of the alert.
  ///   - actions: Custom action buttons.
  public init(
    _ message: LocalizedStringKey,
    variant: IronAlertVariant = .info,
    @ViewBuilder actions: () -> Actions,
  ) where Icon == IronIcon {
    title = nil
    self.message = message
    self.variant = variant
    customIcon = nil
    onDismiss = nil
    self.actions = actions()
  }

  /// Creates an alert with title, message, and custom actions.
  ///
  /// - Parameters:
  ///   - title: The alert title.
  ///   - message: The alert message.
  ///   - variant: The semantic variant of the alert.
  ///   - actions: Custom action buttons.
  public init(
    _ title: LocalizedStringKey,
    message: LocalizedStringKey,
    variant: IronAlertVariant = .info,
    @ViewBuilder actions: () -> Actions,
  ) where Icon == IronIcon {
    self.title = title
    self.message = message
    self.variant = variant
    customIcon = nil
    onDismiss = nil
    self.actions = actions()
  }

  /// Creates an alert with a custom icon.
  ///
  /// Use this initializer when you need a custom icon, such as an image
  /// loaded from the web or a custom view.
  ///
  /// - Parameters:
  ///   - message: The alert message.
  ///   - variant: The semantic variant of the alert.
  ///   - icon: A custom icon view.
  public init(
    _ message: LocalizedStringKey,
    variant: IronAlertVariant = .info,
    @ViewBuilder icon: () -> Icon,
  ) where Actions == EmptyView {
    title = nil
    self.message = message
    self.variant = variant
    customIcon = icon()
    onDismiss = nil
    actions = nil
  }

  /// Creates an alert with title, message, and custom icon.
  ///
  /// - Parameters:
  ///   - title: The alert title.
  ///   - message: The alert message.
  ///   - variant: The semantic variant of the alert.
  ///   - icon: A custom icon view.
  public init(
    _ title: LocalizedStringKey,
    message: LocalizedStringKey,
    variant: IronAlertVariant = .info,
    @ViewBuilder icon: () -> Icon,
  ) where Actions == EmptyView {
    self.title = title
    self.message = message
    self.variant = variant
    customIcon = icon()
    onDismiss = nil
    actions = nil
  }

  /// Creates an alert with custom icon and actions.
  ///
  /// - Parameters:
  ///   - message: The alert message.
  ///   - variant: The semantic variant of the alert.
  ///   - icon: A custom icon view.
  ///   - actions: Custom action buttons.
  public init(
    _ message: LocalizedStringKey,
    variant: IronAlertVariant = .info,
    @ViewBuilder icon: () -> Icon,
    @ViewBuilder actions: () -> Actions,
  ) {
    title = nil
    self.message = message
    self.variant = variant
    customIcon = icon()
    onDismiss = nil
    self.actions = actions()
  }

  /// Creates an alert with title, message, custom icon, and actions.
  ///
  /// - Parameters:
  ///   - title: The alert title.
  ///   - message: The alert message.
  ///   - variant: The semantic variant of the alert.
  ///   - icon: A custom icon view.
  ///   - actions: Custom action buttons.
  public init(
    _ title: LocalizedStringKey,
    message: LocalizedStringKey,
    variant: IronAlertVariant = .info,
    @ViewBuilder icon: () -> Icon,
    @ViewBuilder actions: () -> Actions,
  ) {
    self.title = title
    self.message = message
    self.variant = variant
    customIcon = icon()
    onDismiss = nil
    self.actions = actions()
  }

  // MARK: Public

  public var body: some View {
    HStack(alignment: .top, spacing: theme.spacing.sm) {
      // Icon
      iconView
        .padding(.top, 2)

      // Content
      VStack(alignment: .leading, spacing: theme.spacing.xs) {
        if let title {
          IronText(title, style: .labelLarge, color: .onSurface)
            .fontWeight(.semibold)
        }

        IronText(message, style: .bodyMedium, color: .onSurface)

        if let actions {
          HStack(spacing: theme.spacing.sm) {
            actions
          }
          .padding(.top, theme.spacing.xs)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      // Dismiss button
      if let onDismiss {
        Button {
          withAnimation(shouldAnimate ? theme.animation.snappy : nil) {
            onDismiss()
          }
          IronLogger.ui.debug("IronAlert dismissed", metadata: ["variant": .string("\(variant)")])
        } label: {
          IronIcon(systemName: "xmark", size: .xSmall, color: .secondary)
            .frame(width: 20, height: 20)
            .background(theme.colors.onSurface.opacity(0.08), in: Circle())
            .frame(minWidth: minTouchTarget, minHeight: minTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Dismiss")
      }
    }
    .padding(.leading, theme.spacing.sm)
    .padding(.trailing, theme.spacing.md)
    .padding(.vertical, theme.spacing.md)
    .background {
      GeometryReader { geo in
        let innerRadius = max(0, theme.radii.md - borderWidth)
        let innerWidth = geo.size.width - 2 * borderWidth
        let innerHeight = geo.size.height - 2 * borderWidth

        ZStack(alignment: .leading) {
          backgroundColor

          UnevenRoundedRectangle(
            topLeadingRadius: innerRadius,
            bottomLeadingRadius: innerRadius,
            bottomTrailingRadius: 0,
            topTrailingRadius: 0,
          )
          .fill(foregroundColor)
          .frame(width: 4)
        }
        .frame(width: innerWidth, height: innerHeight)
        .clipShape(RoundedRectangle(cornerRadius: innerRadius))
        .position(x: geo.size.width / 2, y: geo.size.height / 2)
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
    .overlay {
      RoundedRectangle(cornerRadius: theme.radii.md)
        .strokeBorder(borderColor, lineWidth: borderWidth)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(accessibilityLabel)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.ironSkipEntranceAnimations) private var skipEntranceAnimations

  private let title: LocalizedStringKey?
  private let message: LocalizedStringKey
  private let variant: IronAlertVariant
  private let customIcon: Icon?
  private let onDismiss: (() -> Void)?
  private let actions: Actions?

  /// Minimum touch target size per Apple HIG (44pt).
  private let minTouchTarget: CGFloat = 44

  /// Border stroke width.
  private let borderWidth: CGFloat = 1

  @ViewBuilder
  private var iconView: some View {
    if let customIcon {
      customIcon
    } else if Icon.self == IronIcon.self {
      IronIcon(systemName: defaultIconName, size: .medium, color: iconColor)
    }
  }

  private var defaultIconName: String {
    switch variant {
    case .info: "info.circle.fill"
    case .success: "checkmark.circle.fill"
    case .warning: "exclamationmark.triangle.fill"
    case .error: "xmark.circle.fill"
    }
  }

  private var iconColor: IronIconColor {
    switch variant {
    case .info: .info
    case .success: .success
    case .warning: .warning
    case .error: .error
    }
  }

  private var foregroundColor: Color {
    switch variant {
    case .info: theme.colors.info
    case .success: theme.colors.success
    case .warning: theme.colors.warning
    case .error: theme.colors.error
    }
  }

  private var backgroundColor: Color {
    foregroundColor.opacity(0.12)
  }

  private var borderColor: Color {
    foregroundColor.opacity(0.25)
  }

  private var variantAccessibilityLabel: String {
    switch variant {
    case .info: "Information"
    case .success: "Success"
    case .warning: "Warning"
    case .error: "Error"
    }
  }

  /// Comprehensive accessibility label that announces variant, title, and message.
  ///
  /// Format: "Warning: Title. Message" or "Information: Message"
  private var accessibilityLabel: Text {
    if let title {
      Text("\(variantAccessibilityLabel): \(Text(title)). \(Text(message))")
    } else {
      Text("\(variantAccessibilityLabel): \(Text(message))")
    }
  }

  private var shouldAnimate: Bool {
    !reduceMotion && !skipEntranceAnimations
  }
}

// MARK: - IronAlertVariant

/// Semantic variants for `IronAlert`.
public enum IronAlertVariant: Sendable, CaseIterable {
  /// Informational message.
  case info
  /// Success/positive message.
  case success
  /// Warning message.
  case warning
  /// Error/destructive message.
  case error
}

// MARK: - Previews

#Preview("IronAlert - Variants") {
  VStack(spacing: 16) {
    IronAlert("This is an informational message", variant: .info)
    IronAlert("Your changes have been saved successfully", variant: .success)
    IronAlert("Please review the highlighted fields", variant: .warning)
    IronAlert("An error occurred while processing your request", variant: .error)
  }
  .padding()
}

#Preview("IronAlert - With Titles") {
  VStack(spacing: 16) {
    IronAlert("Update Available", message: "A new version is ready to install", variant: .info)
    IronAlert("Payment Successful", message: "Your order has been confirmed", variant: .success)
    IronAlert("Low Storage", message: "You have less than 500MB remaining", variant: .warning)
    IronAlert("Connection Failed", message: "Please check your internet connection", variant: .error)
  }
  .padding()
}

#Preview("IronAlert - Dismissible") {
  struct Demo: View {
    @State private var showInfo = true
    @State private var showSuccess = true
    @State private var showWarning = true
    @State private var showError = true

    var body: some View {
      VStack(spacing: 16) {
        if showInfo {
          IronAlert("Tap the X to dismiss", variant: .info, onDismiss: {
            showInfo = false
          })
        }

        if showSuccess {
          IronAlert("Saved", message: "Your profile has been updated", variant: .success, onDismiss: {
            showSuccess = false
          })
        }

        if showWarning {
          IronAlert("Warning", message: "This action cannot be undone", variant: .warning, onDismiss: {
            showWarning = false
          })
        }

        if showError {
          IronAlert("Error", message: "Failed to load data", variant: .error, onDismiss: {
            showError = false
          })
        }

        if !showInfo, !showSuccess, !showWarning, !showError {
          Button("Reset All") {
            showInfo = true
            showSuccess = true
            showWarning = true
            showError = true
          }
        }
      }
      .padding()
      .animation(.default, value: showInfo)
      .animation(.default, value: showSuccess)
      .animation(.default, value: showWarning)
      .animation(.default, value: showError)
    }
  }

  return Demo()
}

#Preview("IronAlert - With Actions") {
  VStack(spacing: 16) {
    IronAlert("Update Available", message: "Version 2.0 is ready to install", variant: .info, actions: {
      Button("Update Now") { }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
      Button("Later") { }
        .buttonStyle(.bordered)
        .controlSize(.small)
    })

    IronAlert("Delete Item?", message: "This will permanently remove the item", variant: .warning, actions: {
      Button("Delete") { }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .controlSize(.small)
      Button("Cancel") { }
        .buttonStyle(.bordered)
        .controlSize(.small)
    })
  }
  .padding()
}

#Preview("IronAlert - Custom Icon") {
  VStack(spacing: 16) {
    IronAlert("Custom emoji icon", variant: .info, icon: {
      Text("🎉")
        .font(.title3)
    })

    IronAlert("Custom SF Symbol", variant: .success, icon: {
      Image(systemName: "sparkles")
        .foregroundStyle(.yellow)
        .font(.title3)
    })
  }
  .padding()
}

#Preview("IronAlert - In Context") {
  VStack(spacing: 24) {
    Text("Account Settings")
      .font(.title2)
      .fontWeight(.bold)
      .frame(maxWidth: .infinity, alignment: .leading)

    IronAlert(
      "Verification Required",
      message: "Please verify your email address to access all features",
      variant: .warning,
      actions: {
        Button("Verify Email") { }
          .buttonStyle(.borderedProminent)
          .controlSize(.small)
      },
    )

    VStack(alignment: .leading, spacing: 12) {
      Text("Email")
        .font(.subheadline)
        .foregroundStyle(.secondary)
      Text("user@example.com")
    }
    .frame(maxWidth: .infinity, alignment: .leading)

    Divider()

    VStack(alignment: .leading, spacing: 12) {
      Text("Password")
        .font(.subheadline)
        .foregroundStyle(.secondary)
      Text("••••••••")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
  .padding()
}
