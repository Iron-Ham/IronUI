import IronCore
import IronPrimitives
import SwiftUI

// MARK: - IronToast

/// A themed toast notification for displaying ephemeral messages.
///
/// `IronToast` provides a transient notification that auto-dismisses
/// after a configurable duration. Use toasts for non-critical feedback
/// that doesn't require user action.
///
/// ## Basic Usage
///
/// ```swift
/// .ironToast(isPresented: $showToast) {
///     IronToast("Item saved successfully", variant: .success)
/// }
/// ```
///
/// ## With Title
///
/// ```swift
/// .ironToast(isPresented: $showToast) {
///     IronToast("Success", message: "Your changes have been saved", variant: .success)
/// }
/// ```
///
/// ## With Action
///
/// ```swift
/// .ironToast(isPresented: $showToast) {
///     IronToast(
///         "Item deleted",
///         variant: .info,
///         action: IronToastAction("Undo") { /* restore item */ }
///     )
/// }
/// ```
///
/// ## Queue-Based Usage
///
/// ```swift
/// @State private var toasts = IronToastContainer()
///
/// ContentView()
///     .ironToastContainer(toasts)
///
/// func save() {
///     toasts.show("Saved!", variant: .success)
/// }
/// ```
public struct IronToast<Icon: View>: View {

  // MARK: Lifecycle

  /// Creates a toast with a message.
  ///
  /// - Parameters:
  ///   - message: The toast message.
  ///   - variant: The semantic variant of the toast.
  ///   - action: An optional action button.
  public init(
    _ message: LocalizedStringKey,
    variant: IronToastVariant = .info,
    action: IronToastAction? = nil,
  ) where Icon == IronIcon {
    title = nil
    self.message = message
    self.variant = variant
    customIcon = nil
    self.action = action
  }

  /// Creates a toast with a message from a string.
  ///
  /// - Parameters:
  ///   - message: The toast message string.
  ///   - variant: The semantic variant of the toast.
  ///   - action: An optional action button.
  public init(
    _ message: some StringProtocol,
    variant: IronToastVariant = .info,
    action: IronToastAction? = nil,
  ) where Icon == IronIcon {
    title = nil
    self.message = LocalizedStringKey(String(message))
    self.variant = variant
    customIcon = nil
    self.action = action
  }

  /// Creates a toast with a title and message.
  ///
  /// - Parameters:
  ///   - title: The toast title.
  ///   - message: The toast message.
  ///   - variant: The semantic variant of the toast.
  ///   - action: An optional action button.
  public init(
    _ title: LocalizedStringKey,
    message: LocalizedStringKey,
    variant: IronToastVariant = .info,
    action: IronToastAction? = nil,
  ) where Icon == IronIcon {
    self.title = title
    self.message = message
    self.variant = variant
    customIcon = nil
    self.action = action
  }

  /// Creates a toast with a custom icon.
  ///
  /// - Parameters:
  ///   - message: The toast message.
  ///   - variant: The semantic variant of the toast.
  ///   - action: An optional action button.
  ///   - icon: A custom icon view.
  public init(
    _ message: LocalizedStringKey,
    variant: IronToastVariant = .info,
    action: IronToastAction? = nil,
    @ViewBuilder icon: () -> Icon,
  ) {
    title = nil
    self.message = message
    self.variant = variant
    customIcon = icon()
    self.action = action
  }

  /// Creates a toast with title, message, and custom icon.
  ///
  /// - Parameters:
  ///   - title: The toast title.
  ///   - message: The toast message.
  ///   - variant: The semantic variant of the toast.
  ///   - action: An optional action button.
  ///   - icon: A custom icon view.
  public init(
    _ title: LocalizedStringKey,
    message: LocalizedStringKey,
    variant: IronToastVariant = .info,
    action: IronToastAction? = nil,
    @ViewBuilder icon: () -> Icon,
  ) {
    self.title = title
    self.message = message
    self.variant = variant
    customIcon = icon()
    self.action = action
  }

  // MARK: Public

  public var body: some View {
    HStack(spacing: theme.spacing.sm) {
      // Icon
      iconView
        .padding(.leading, theme.spacing.xs)

      // Content
      VStack(alignment: .leading, spacing: theme.spacing.xxs) {
        if let title {
          IronText(title, style: .labelMedium, color: .onSurface)
            .fontWeight(.semibold)
        }
        IronText(message, style: .bodySmall, color: .onSurface)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      // Action button
      if let action {
        Button {
          action.action()
          IronLogger.ui.debug("IronToast action tapped", metadata: ["variant": .string("\(variant)")])
        } label: {
          IronText(action.title, style: .labelMedium, color: .inherited)
            .fontWeight(.medium)
        }
        .buttonStyle(.plain)
        .foregroundStyle(actionColor)
        .frame(minWidth: minTouchTarget, minHeight: minTouchTarget)
        .contentShape(Rectangle())
        .accessibilityLabel(action.title)
      }

      // Dismiss button (internal, controlled by modifier)
      if showsDismissButton, let onDismiss {
        Button {
          withAnimation(shouldAnimate ? theme.animation.snappy : nil) {
            onDismiss()
          }
          IronLogger.ui.debug("IronToast dismissed", metadata: ["variant": .string("\(variant)")])
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
    .padding(.horizontal, theme.spacing.md)
    .padding(.vertical, theme.spacing.sm)
    .frame(minHeight: minTouchTarget)
    .background {
      ZStack {
        // Base background with variant tint
        backgroundColor

        // Subtle leading accent bar
        HStack(spacing: 0) {
          foregroundColor
            .frame(width: 4)
          Spacer()
        }
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
    .overlay {
      RoundedRectangle(cornerRadius: theme.radii.md)
        .strokeBorder(borderColor, lineWidth: 1)
    }
    .ironShadow(theme.shadows.lg)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(accessibilityLabel)
    .accessibilityHint(Text("Swipe to dismiss"))
  }

  // MARK: Internal

  /// Controls whether the dismiss button is shown.
  var showsDismissButton = true

  /// Called when the dismiss button is tapped.
  var onDismiss: (() -> Void)?

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.ironSkipEntranceAnimations) private var skipEntranceAnimations

  private let title: LocalizedStringKey?
  private let message: LocalizedStringKey
  private let variant: IronToastVariant
  private let customIcon: Icon?
  private let action: IronToastAction?

  /// Minimum touch target size per Apple HIG (44pt).
  private let minTouchTarget: CGFloat = 44

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

  private var actionColor: Color {
    foregroundColor
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

// MARK: - IronToastVariant

/// Semantic variants for `IronToast`.
public enum IronToastVariant: Sendable, CaseIterable {
  /// Informational message.
  case info
  /// Success/positive message.
  case success
  /// Warning message.
  case warning
  /// Error/destructive message.
  case error
}

// MARK: - IronToastPosition

/// Position options for `IronToast`.
public enum IronToastPosition: Sendable {
  /// Top of screen with alignment.
  case top(alignment: HorizontalAlignment = .center)
  /// Bottom of screen with alignment.
  case bottom(alignment: HorizontalAlignment = .center)

  /// Top center (convenience).
  public static var top: IronToastPosition {
    .top(alignment: .center)
  }

  /// Bottom center (convenience).
  public static var bottom: IronToastPosition {
    .bottom(alignment: .center)
  }
}

// MARK: - IronToastAction

/// An action button for `IronToast`.
///
/// - Note: This type is `@unchecked Sendable` because `LocalizedStringKey`
///   does not conform to `Sendable`, but is effectively immutable and safe to share.
public struct IronToastAction: @unchecked Sendable {

  // MARK: Lifecycle

  /// Creates a toast action with a localized title.
  ///
  /// - Parameters:
  ///   - title: The button title.
  ///   - action: The action to perform when tapped.
  public init(_ title: LocalizedStringKey, action: @escaping @Sendable @MainActor () -> Void) {
    self.title = title
    self.action = action
  }

  /// Creates a toast action with a string title.
  ///
  /// - Parameters:
  ///   - title: The button title string.
  ///   - action: The action to perform when tapped.
  public init(_ title: some StringProtocol, action: @escaping @Sendable @MainActor () -> Void) {
    self.title = LocalizedStringKey(String(title))
    self.action = action
  }

  // MARK: Public

  /// The button title.
  public let title: LocalizedStringKey
  /// The action to perform when tapped.
  public let action: @Sendable @MainActor () -> Void
}

// MARK: - Previews

#Preview("IronToast - Variants") {
  VStack(spacing: 16) {
    IronToast("This is an informational message", variant: .info)
    IronToast("Your changes have been saved successfully", variant: .success)
    IronToast("Please review the highlighted fields", variant: .warning)
    IronToast("An error occurred while processing", variant: .error)
  }
  .padding()
}

#Preview("IronToast - With Titles") {
  VStack(spacing: 16) {
    IronToast("Update Available", message: "A new version is ready", variant: .info)
    IronToast("Payment Successful", message: "Your order has been confirmed", variant: .success)
    IronToast("Low Storage", message: "Less than 500MB remaining", variant: .warning)
    IronToast("Connection Failed", message: "Check your internet", variant: .error)
  }
  .padding()
}

#Preview("IronToast - With Actions") {
  VStack(spacing: 16) {
    IronToast(
      "Item deleted",
      variant: .info,
      action: IronToastAction("Undo") { },
    )

    IronToast(
      "Network error",
      variant: .error,
      action: IronToastAction("Retry") { },
    )

    IronToast(
      "File Uploaded",
      message: "document.pdf uploaded successfully",
      variant: .success,
      action: IronToastAction("View") { },
    )
  }
  .padding()
}

#Preview("IronToast - Custom Icons") {
  VStack(spacing: 16) {
    IronToast("Celebration time!", variant: .success, icon: {
      Text("🎉")
        .font(.title3)
    })

    IronToast("Sparkly success", variant: .success, icon: {
      Image(systemName: "sparkles")
        .foregroundStyle(.yellow)
        .font(.title3)
    })
  }
  .padding()
}

#Preview("IronToast - In Context (Bottom)") {
  ZStack {
    Color.gray.opacity(0.15)
      .ignoresSafeArea()

    VStack {
      Text("Main Content")
        .font(.title)

      Spacer()
    }
    .padding(.top, 100)

    VStack {
      Spacer()

      IronToast("Item saved successfully", variant: .success)
        .padding(.horizontal)
        .padding(.bottom, 32)
    }
  }
}

#Preview("IronToast - In Context (Top)") {
  ZStack {
    Color.gray.opacity(0.15)
      .ignoresSafeArea()

    VStack {
      IronToast("New message received", variant: .info)
        .padding(.horizontal)
        .padding(.top, 60)

      Spacer()

      Text("Main Content")
        .font(.title)
    }
    .padding(.bottom, 100)
  }
}
