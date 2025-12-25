import IronCore
import IronPrimitives
import SwiftUI

// MARK: - IronMenu

/// A themed menu component for presenting a list of actions.
///
/// `IronMenu` wraps SwiftUI's `Menu` with consistent styling and
/// convenient APIs for common menu patterns.
///
/// ## Basic Usage
///
/// ```swift
/// IronMenu("Options") {
///   IronMenuItem("Edit", icon: "pencil") { }
///   IronMenuItem("Duplicate", icon: "doc.on.doc") { }
///   IronMenuDivider()
///   IronMenuItem("Delete", icon: "trash", role: .destructive) { }
/// }
/// ```
///
/// ## With Custom Trigger
///
/// ```swift
/// IronMenu {
///   IronMenuItem("Profile") { }
///   IronMenuItem("Settings") { }
///   IronMenuItem("Sign Out") { }
/// } label: {
///   IronAvatar(name: "John Doe")
/// }
/// ```
///
/// ## With Sections
///
/// ```swift
/// IronMenu("Actions") {
///   IronMenuSection("Edit") {
///     IronMenuItem("Cut", icon: "scissors") { }
///     IronMenuItem("Copy", icon: "doc.on.doc") { }
///     IronMenuItem("Paste", icon: "doc.on.clipboard") { }
///   }
///
///   IronMenuSection("Share") {
///     IronMenuItem("AirDrop", icon: "airplay") { }
///     IronMenuItem("Messages", icon: "message") { }
///   }
/// }
/// ```
public struct IronMenu<Label: View, Content: View>: View {

  // MARK: Lifecycle

  /// Creates a menu with a custom label.
  ///
  /// - Parameters:
  ///   - content: The menu content.
  ///   - label: The menu trigger label.
  public init(
    @ViewBuilder content: () -> Content,
    @ViewBuilder label: () -> Label,
  ) {
    self.content = content()
    self.label = label()
  }

  // MARK: Public

  public var body: some View {
    Menu {
      content
    } label: {
      label
    }
    .menuStyle(.borderlessButton)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private let content: Content
  private let label: Label
}

// MARK: - Text Label Convenience

extension IronMenu where Label == IronMenuLabel {
  /// Creates a menu with a text label.
  ///
  /// - Parameters:
  ///   - title: The menu trigger text.
  ///   - icon: Optional SF Symbol name.
  ///   - content: The menu content.
  public init(
    _ title: LocalizedStringKey,
    icon: String? = nil,
    @ViewBuilder content: () -> Content,
  ) {
    self.content = content()
    label = IronMenuLabel(title: title, icon: icon)
  }

  /// Creates a menu with a text label from a string.
  ///
  /// - Parameters:
  ///   - title: The menu trigger string.
  ///   - icon: Optional SF Symbol name.
  ///   - content: The menu content.
  public init(
    _ title: some StringProtocol,
    icon: String? = nil,
    @ViewBuilder content: () -> Content,
  ) {
    self.content = content()
    label = IronMenuLabel(title: LocalizedStringKey(String(title)), icon: icon)
  }
}

// MARK: - IronMenuLabel

/// The default label style for `IronMenu`.
public struct IronMenuLabel: View {

  // MARK: Lifecycle

  init(title: LocalizedStringKey, icon: String?) {
    self.title = title
    self.icon = icon
  }

  // MARK: Public

  public var body: some View {
    HStack(spacing: theme.spacing.xs) {
      if let icon {
        IronIcon(systemName: icon, size: .small, color: .primary)
      }

      IronText(title, style: .labelMedium, color: .primary)

      IronIcon(systemName: "chevron.down", size: .small, color: .secondary)
    }
    .padding(.horizontal, theme.spacing.md)
    .padding(.vertical, theme.spacing.sm)
    .frame(minWidth: minTouchTarget, minHeight: minTouchTarget)
    .background(theme.colors.surface)
    .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
    .overlay {
      RoundedRectangle(cornerRadius: theme.radii.md)
        .strokeBorder(theme.colors.onSurface.opacity(0.3), lineWidth: 1)
    }
    .contentShape(RoundedRectangle(cornerRadius: theme.radii.md))
    .accessibilityElement(children: .combine)
    .accessibilityHint("Opens menu")
    .accessibilityAddTraits(.isButton)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private let title: LocalizedStringKey
  private let icon: String?

  /// Minimum touch target size per Apple HIG (44pt).
  private let minTouchTarget: CGFloat = 44
}

// MARK: - IronMenuItem

/// A menu item with an action.
public struct IronMenuItem: View {

  // MARK: Lifecycle

  /// Creates a menu item.
  ///
  /// - Parameters:
  ///   - title: The item title.
  ///   - icon: Optional SF Symbol name.
  ///   - role: The button role (e.g., destructive).
  ///   - onTap: The action to perform.
  public init(
    _ title: LocalizedStringKey,
    icon: String? = nil,
    role: ButtonRole? = nil,
    onTap: @escaping () -> Void,
  ) {
    self.title = title
    self.icon = icon
    self.role = role
    self.onTap = onTap
  }

  /// Creates a menu item from a string.
  ///
  /// - Parameters:
  ///   - title: The item title string.
  ///   - icon: Optional SF Symbol name.
  ///   - role: The button role (e.g., destructive).
  ///   - onTap: The action to perform.
  public init(
    _ title: some StringProtocol,
    icon: String? = nil,
    role: ButtonRole? = nil,
    onTap: @escaping () -> Void,
  ) {
    self.title = LocalizedStringKey(String(title))
    self.icon = icon
    self.role = role
    self.onTap = onTap
  }

  // MARK: Public

  public var body: some View {
    Button(role: role) {
      onTap()
      IronLogger.ui.debug(
        "IronMenuItem tapped",
        metadata: ["role": .string("\(String(describing: role))")],
      )
    } label: {
      if let icon {
        Label {
          IronText(title, style: .bodyMedium, color: .primary)
        } icon: {
          IronIcon(systemName: icon, size: .small, color: .primary)
        }
      } else {
        IronText(title, style: .bodyMedium, color: .primary)
      }
    }
  }

  // MARK: Private

  private let title: LocalizedStringKey
  private let icon: String?
  private let role: ButtonRole?
  private let onTap: () -> Void
}

// MARK: - IronMenuSection

/// A section within a menu for grouping related items.
public struct IronMenuSection<Content: View>: View {

  // MARK: Lifecycle

  /// Creates a menu section with a header.
  ///
  /// - Parameters:
  ///   - header: The section header text.
  ///   - content: The section content.
  public init(
    _ header: LocalizedStringKey,
    @ViewBuilder content: () -> Content,
  ) {
    self.header = header
    self.content = content()
  }

  /// Creates a menu section with a header from a string.
  ///
  /// - Parameters:
  ///   - header: The section header string.
  ///   - content: The section content.
  public init(
    _ header: some StringProtocol,
    @ViewBuilder content: () -> Content,
  ) {
    self.header = LocalizedStringKey(String(header))
    self.content = content()
  }

  // MARK: Public

  public var body: some View {
    Section {
      content
    } header: {
      IronText(header, style: .labelSmall, color: .secondary)
    }
  }

  // MARK: Private

  private let header: LocalizedStringKey
  private let content: Content
}

// MARK: - IronMenuDivider

/// A divider within a menu.
public struct IronMenuDivider: View {
  public init() { }

  public var body: some View {
    Divider()
  }
}

// MARK: - IronMenuPicker

/// A picker-style menu for selecting from a list of options.
public struct IronMenuPicker<Option: Hashable, Label: View>: View {

  // MARK: Lifecycle

  /// Creates a menu picker.
  ///
  /// - Parameters:
  ///   - title: The picker title (shown in menu trigger).
  ///   - selection: Binding to the selected option.
  ///   - options: The available options.
  ///   - label: A view builder for option labels.
  public init(
    _ title: LocalizedStringKey,
    selection: Binding<Option>,
    options: [Option],
    @ViewBuilder label: @escaping (Option) -> Label,
  ) {
    self.title = title
    _selection = selection
    self.options = options
    labelBuilder = label
  }

  // MARK: Public

  public var body: some View {
    Menu {
      ForEach(options, id: \.self) { option in
        Button {
          selection = option
          IronLogger.ui.debug("IronMenuPicker selected option")
        } label: {
          HStack {
            labelBuilder(option)
            Spacer()
            if option == selection {
              IronIcon(systemName: "checkmark", size: .xSmall, color: .primary)
            }
          }
        }
      }
    } label: {
      IronMenuLabel(title: title, icon: nil)
    }
  }

  // MARK: Private

  @Binding private var selection: Option

  private let title: LocalizedStringKey
  private let options: [Option]
  private let labelBuilder: (Option) -> Label
}

// MARK: - Previews

#Preview("IronMenu - Basic") {
  IronMenu("Options") {
    IronMenuItem("Edit", icon: "pencil") { }
    IronMenuItem("Duplicate", icon: "doc.on.doc") { }
    IronMenuDivider()
    IronMenuItem("Delete", icon: "trash", role: .destructive) { }
  }
  .padding()
}

#Preview("IronMenu - With Icon") {
  IronMenu("Sort By", icon: "arrow.up.arrow.down") {
    IronMenuItem("Name") { }
    IronMenuItem("Date") { }
    IronMenuItem("Size") { }
  }
  .padding()
}

#Preview("IronMenu - Sections") {
  IronMenu("Actions") {
    IronMenuSection("Edit") {
      IronMenuItem("Cut", icon: "scissors") { }
      IronMenuItem("Copy", icon: "doc.on.doc") { }
      IronMenuItem("Paste", icon: "doc.on.clipboard") { }
    }

    IronMenuSection("Share") {
      IronMenuItem("AirDrop", icon: "airplay") { }
      IronMenuItem("Messages", icon: "message") { }
    }
  }
  .padding()
}

#Preview("IronMenu - Custom Trigger") {
  IronMenu {
    IronMenuItem("Profile", icon: "person") { }
    IronMenuItem("Settings", icon: "gear") { }
    IronMenuDivider()
    IronMenuItem("Sign Out", icon: "arrow.right.square", role: .destructive) { }
  } label: {
    HStack(spacing: 8) {
      IronAvatar(name: "John Doe", size: .small)
      IronText("John Doe", style: .labelMedium, color: .primary)
    }
    .padding(8)
    .background(Color.gray.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }
  .padding()
}

#Preview("IronMenu - Context Menu Style") {
  struct Demo: View {
    var body: some View {
      VStack(spacing: 24) {
        IronCard {
          VStack(alignment: .leading, spacing: 8) {
            IronText("Document.pdf", style: .labelLarge, color: .primary)
            IronText("2.4 MB", style: .caption, color: .secondary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding()
        }
        .contextMenu {
          IronMenuItem("Open", icon: "doc") { }
          IronMenuItem("Share", icon: "square.and.arrow.up") { }
          IronMenuDivider()
          IronMenuItem("Delete", icon: "trash", role: .destructive) { }
        }
      }
      .padding()
    }
  }

  return Demo()
}

#Preview("IronMenuPicker") {
  enum SortOption: String, CaseIterable {
    case name, date, size
  }

  @Previewable @State var sortBy = SortOption.name

  return IronMenuPicker("Sort by: \(sortBy.rawValue.capitalized)", selection: $sortBy, options: SortOption.allCases) { option in
    Text(option.rawValue.capitalized)
  }
  .padding()
}
