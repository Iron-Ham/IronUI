import IronCore
import SwiftUI

// MARK: - IronCard

/// A container for grouping related content with consistent styling.
///
/// `IronCard` provides a themed container with configurable elevation,
/// padding, and corner radius. Use cards to group related information
/// and create visual hierarchy.
///
/// ## Basic Usage
///
/// ```swift
/// IronCard {
///   VStack(alignment: .leading) {
///     Text("Card Title")
///       .font(.headline)
///     Text("Card content goes here")
///   }
/// }
/// ```
///
/// ## Styles
///
/// ```swift
/// IronCard(style: .elevated) { content }  // Shadow elevation
/// IronCard(style: .filled) { content }    // Solid background
/// IronCard(style: .outlined) { content }  // Border only
/// ```
///
/// ## Tappable Cards
///
/// ```swift
/// IronCard {
///   Text("Tap me")
/// } action: {
///   print("Card tapped")
/// }
/// ```
///
/// ## Structured Content
///
/// ```swift
/// IronCard {
///   Text("Body content")
/// } header: {
///   Label("Settings", systemImage: "gear")
/// } footer: {
///   Button("Save") { }
/// }
/// ```
public struct IronCard<Content: View, Header: View, Footer: View>: View {

  // MARK: Lifecycle

  /// Creates a card with content only.
  ///
  /// - Parameters:
  ///   - style: The visual style of the card.
  ///   - padding: The padding inside the card.
  ///   - content: The main content of the card.
  public init(
    style: IronCardStyle = .elevated,
    padding: IronCardPadding = .standard,
    @ViewBuilder content: () -> Content,
  ) where Header == EmptyView, Footer == EmptyView {
    self.style = style
    self.padding = padding
    self.content = content()
    header = nil
    footer = nil
    action = nil
  }

  /// Creates a tappable card with content.
  ///
  /// - Parameters:
  ///   - style: The visual style of the card.
  ///   - padding: The padding inside the card.
  ///   - content: The main content of the card.
  ///   - action: The action to perform when tapped.
  public init(
    style: IronCardStyle = .elevated,
    padding: IronCardPadding = .standard,
    @ViewBuilder content: () -> Content,
    action: @escaping () -> Void,
  ) where Header == EmptyView, Footer == EmptyView {
    self.style = style
    self.padding = padding
    self.content = content()
    header = nil
    footer = nil
    self.action = action
  }

  /// Creates a card with header, content, and footer.
  ///
  /// - Parameters:
  ///   - style: The visual style of the card.
  ///   - padding: The padding inside the card.
  ///   - content: The main content of the card.
  ///   - header: The header content.
  ///   - footer: The footer content.
  public init(
    style: IronCardStyle = .elevated,
    padding: IronCardPadding = .standard,
    @ViewBuilder content: () -> Content,
    @ViewBuilder header: () -> Header,
    @ViewBuilder footer: () -> Footer,
  ) {
    self.style = style
    self.padding = padding
    self.content = content()
    self.header = header()
    self.footer = footer()
    action = nil
  }

  /// Creates a card with header and content.
  ///
  /// - Parameters:
  ///   - style: The visual style of the card.
  ///   - padding: The padding inside the card.
  ///   - content: The main content of the card.
  ///   - header: The header content.
  public init(
    style: IronCardStyle = .elevated,
    padding: IronCardPadding = .standard,
    @ViewBuilder content: () -> Content,
    @ViewBuilder header: () -> Header,
  ) where Footer == EmptyView {
    self.style = style
    self.padding = padding
    self.content = content()
    self.header = header()
    footer = nil
    action = nil
  }

  /// Creates a card with content and footer.
  ///
  /// - Parameters:
  ///   - style: The visual style of the card.
  ///   - padding: The padding inside the card.
  ///   - content: The main content of the card.
  ///   - footer: The footer content.
  public init(
    style: IronCardStyle = .elevated,
    padding: IronCardPadding = .standard,
    @ViewBuilder content: () -> Content,
    @ViewBuilder footer: () -> Footer,
  ) where Header == EmptyView {
    self.style = style
    self.padding = padding
    self.content = content()
    header = nil
    self.footer = footer()
    action = nil
  }

  // MARK: Public

  public var body: some View {
    Group {
      if let action {
        Button(action: action) {
          cardContent
        }
        .buttonStyle(IronCardButtonStyle(style: style, isPressed: false))
      } else {
        cardContent
          .background(backgroundColor, in: cardShape)
          .overlay {
            if style == .outlined {
              cardShape
                .strokeBorder(theme.colors.border, lineWidth: 1)
            }
          }
          .shadow(
            color: shadowColor,
            radius: shadowRadius,
            x: 0,
            y: shadowY,
          )
      }
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private let style: IronCardStyle
  private let padding: IronCardPadding
  private let content: Content
  private let header: Header?
  private let footer: Footer?
  private let action: (() -> Void)?

  private var cardShape: some InsettableShape {
    RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous)
  }

  private var cardContent: some View {
    VStack(alignment: .leading, spacing: 0) {
      if let header {
        header
          .padding(.horizontal, horizontalPadding)
          .padding(.top, verticalPadding)
          .padding(.bottom, theme.spacing.sm)
      }

      content
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, header == nil && footer == nil ? verticalPadding : theme.spacing.sm)

      if let footer {
        footer
          .padding(.horizontal, horizontalPadding)
          .padding(.top, theme.spacing.sm)
          .padding(.bottom, verticalPadding)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var horizontalPadding: CGFloat {
    switch padding {
    case .none: 0
    case .compact: theme.spacing.sm
    case .standard: theme.spacing.md
    case .spacious: theme.spacing.lg
    }
  }

  private var verticalPadding: CGFloat {
    switch padding {
    case .none: 0
    case .compact: theme.spacing.sm
    case .standard: theme.spacing.md
    case .spacious: theme.spacing.lg
    }
  }

  private var backgroundColor: Color {
    switch style {
    case .elevated, .filled:
      theme.colors.surface
    case .outlined:
      Color.clear
    }
  }

  private var shadowColor: Color {
    switch style {
    case .elevated:
      Color.black.opacity(0.1)
    case .filled, .outlined:
      Color.clear
    }
  }

  private var shadowRadius: CGFloat {
    switch style {
    case .elevated: 8
    case .filled, .outlined: 0
    }
  }

  private var shadowY: CGFloat {
    switch style {
    case .elevated: 2
    case .filled, .outlined: 0
    }
  }
}

// MARK: - IronCardButtonStyle

private struct IronCardButtonStyle: ButtonStyle {

  // MARK: Internal

  let style: IronCardStyle
  let isPressed: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .background(backgroundColor(isPressed: configuration.isPressed))
      .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous))
      .overlay {
        if style == .outlined {
          RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous)
            .strokeBorder(theme.colors.border, lineWidth: 1)
        }
      }
      .shadow(
        color: shadowColor,
        radius: shadowRadius(isPressed: configuration.isPressed),
        x: 0,
        y: shadowY(isPressed: configuration.isPressed),
      )
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .animation(theme.animation.snappy, value: configuration.isPressed)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private var shadowColor: Color {
    switch style {
    case .elevated:
      Color.black.opacity(0.1)
    case .filled, .outlined:
      Color.clear
    }
  }

  private func backgroundColor(isPressed: Bool) -> Color {
    switch style {
    case .elevated, .filled:
      isPressed ? theme.colors.surfaceElevated : theme.colors.surface
    case .outlined:
      isPressed ? theme.colors.surface.opacity(0.5) : Color.clear
    }
  }

  private func shadowRadius(isPressed: Bool) -> CGFloat {
    switch style {
    case .elevated: isPressed ? 4 : 8
    case .filled, .outlined: 0
    }
  }

  private func shadowY(isPressed: Bool) -> CGFloat {
    switch style {
    case .elevated: isPressed ? 1 : 2
    case .filled, .outlined: 0
    }
  }
}

// MARK: - IronCardStyle

/// Visual styles for `IronCard`.
public enum IronCardStyle: Sendable, CaseIterable {
  /// Elevated card with shadow for depth.
  case elevated
  /// Filled card with solid background.
  case filled
  /// Outlined card with border only.
  case outlined
}

// MARK: - IronCardPadding

/// Padding options for `IronCard`.
public enum IronCardPadding: Sendable, CaseIterable {
  /// No padding.
  case none
  /// Compact padding for dense layouts.
  case compact
  /// Standard padding for most use cases.
  case standard
  /// Spacious padding for prominent cards.
  case spacious
}

// MARK: - Previews

#Preview("IronCard - Basic") {
  VStack(spacing: 16) {
    IronCard {
      VStack(alignment: .leading, spacing: 8) {
        Text("Card Title")
          .font(.headline)
        Text("This is some card content that demonstrates the basic card layout.")
          .foregroundStyle(.secondary)
      }
    }

    IronCard(style: .filled) {
      Text("Filled card style")
    }

    IronCard(style: .outlined) {
      Text("Outlined card style")
    }
  }
  .padding()
}

#Preview("IronCard - Styles") {
  VStack(spacing: 16) {
    IronCard(style: .elevated) {
      Label("Elevated", systemImage: "square.stack.3d.up")
    }

    IronCard(style: .filled) {
      Label("Filled", systemImage: "square.fill")
    }

    IronCard(style: .outlined) {
      Label("Outlined", systemImage: "square")
    }
  }
  .padding()
}

#Preview("IronCard - Padding") {
  VStack(spacing: 16) {
    IronCard(padding: .none) {
      Text("No padding")
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.2))
    }

    IronCard(padding: .compact) {
      Text("Compact padding")
    }

    IronCard(padding: .standard) {
      Text("Standard padding")
    }

    IronCard(padding: .spacious) {
      Text("Spacious padding")
    }
  }
  .padding()
}

#Preview("IronCard - With Header & Footer") {
  IronCard {
    Text("This is the main content area of the card. It can contain any views you need.")
      .foregroundStyle(.secondary)
  } header: {
    HStack {
      Image(systemName: "person.circle.fill")
        .font(.title2)
        .foregroundStyle(.blue)
      VStack(alignment: .leading) {
        Text("John Doe")
          .font(.headline)
        Text("Posted 2 hours ago")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Button { } label: {
        Image(systemName: "ellipsis")
      }
    }
  } footer: {
    HStack {
      Button { } label: {
        Label("Like", systemImage: "heart")
      }
      Button { } label: {
        Label("Comment", systemImage: "bubble.right")
      }
      Spacer()
      Button { } label: {
        Image(systemName: "bookmark")
      }
    }
    .buttonStyle(.borderless)
  }
  .padding()
}

#Preview("IronCard - Tappable") {
  VStack(spacing: 16) {
    IronCard {
      HStack {
        Image(systemName: "gear")
          .font(.title2)
          .foregroundStyle(.blue)
        VStack(alignment: .leading) {
          Text("Settings")
            .font(.headline)
          Text("Customize your experience")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Image(systemName: "chevron.right")
          .foregroundStyle(.secondary)
      }
    } action: {
      // Handle tap
    }

    IronCard(style: .outlined) {
      HStack {
        Image(systemName: "bell")
          .font(.title2)
          .foregroundStyle(.orange)
        VStack(alignment: .leading) {
          Text("Notifications")
            .font(.headline)
          Text("Manage alerts")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Image(systemName: "chevron.right")
          .foregroundStyle(.secondary)
      }
    } action: {
      // Handle tap
    }
  }
  .padding()
}

#Preview("IronCard - List") {
  ScrollView {
    VStack(spacing: 12) {
      ForEach(0..<5) { index in
        IronCard {
          HStack {
            Circle()
              .fill(Color.blue.opacity(0.2))
              .frame(width: 44, height: 44)
              .overlay {
                Text("\(index + 1)")
                  .font(.headline)
              }
            VStack(alignment: .leading) {
              Text("Item \(index + 1)")
                .font(.headline)
              Text("Description for item \(index + 1)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
          }
        } action: {
          // Handle tap
        }
      }
    }
    .padding()
  }
}
