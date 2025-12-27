import IronCore
import IronPrimitives
import SwiftUI

// MARK: - IronAccordion

/// A collapsible section with a header and expandable content.
///
/// `IronAccordion` provides a styled collapsible component that follows
/// IronUI's design patterns with smooth animations, full accessibility
/// support, and theme integration.
///
/// ## Basic Usage
///
/// ```swift
/// IronAccordion("Settings") {
///   Text("Settings content here")
/// }
/// ```
///
/// ## Controlled Expansion
///
/// ```swift
/// @State private var isExpanded = false
///
/// IronAccordion("Details", isExpanded: $isExpanded) {
///   Text("Detailed information")
/// }
/// ```
///
/// ## With Icon
///
/// ```swift
/// IronAccordion("Settings", icon: "gear") {
///   Text("Settings content")
/// }
/// ```
///
/// ## Custom Header
///
/// ```swift
/// IronAccordion {
///   HStack {
///     IronIcon(systemName: "star.fill", color: .warning)
///     IronText("Premium Features", style: .headlineSmall)
///   }
/// } content: {
///   Text("Premium content here")
/// }
/// ```
///
/// ## Accordion Groups
///
/// For multiple coordinated accordions, use ``IronAccordionGroup``:
///
/// ```swift
/// IronAccordionGroup(expandBehavior: .exclusive) {
///   IronAccordion("General") { Text("General settings") }
///   IronAccordion("Privacy") { Text("Privacy settings") }
///   IronAccordion("Notifications") { Text("Notifications") }
/// }
/// ```
public struct IronAccordion<Header: View, Content: View>: View {

  // MARK: Lifecycle

  /// Creates an accordion with a custom header.
  ///
  /// - Parameters:
  ///   - isExpanded: An optional binding to control the expansion state.
  ///   - header: A view builder that creates the header content.
  ///   - content: A view builder that creates the expandable content.
  public init(
    isExpanded: Binding<Bool>? = nil,
    @ViewBuilder header: () -> Header,
    @ViewBuilder content: () -> Content
  ) {
    _localExpanded = State(initialValue: isExpanded?.wrappedValue ?? false)
    externalExpanded = isExpanded
    self.header = header()
    self.content = content()
    id = UUID().uuidString
  }

  // MARK: Public

  public var body: some View {
    VStack(spacing: 0) {
      headerButton
      expandableContent
    }
    .clipped()
    .accessibleAnimation(theme.animation.smooth, value: isExpanded)
    .environment(\.ironAccordionDepth, depth + 1)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.ironSkipEntranceAnimations) private var skipEntranceAnimations
  @Environment(\.ironAccordionCoordinator) private var coordinator
  @Environment(\.ironAccordionInGroup) private var inGroup
  @Environment(\.ironAccordionDepth) private var depth

  @State private var localExpanded: Bool
  private let externalExpanded: Binding<Bool>?
  private let header: Header
  private let content: Content
  private let id: String

  private let minTouchTarget: CGFloat = 44

  private var isExpanded: Bool {
    if let coordinator, inGroup {
      return coordinator.isExpanded(id)
    }
    return externalExpanded?.wrappedValue ?? localExpanded
  }

  private var shouldAnimate: Bool {
    !reduceMotion && !skipEntranceAnimations
  }

  private var nestingIndent: CGFloat {
    CGFloat(depth) * theme.spacing.md
  }

  @ViewBuilder
  private var headerButton: some View {
    Button {
      toggleExpansion()
    } label: {
      HStack(spacing: theme.spacing.md) {
        header
          .frame(maxWidth: .infinity, alignment: .leading)

        IronIcon(systemName: "chevron.right", size: .small, color: .secondary)
          .rotationEffect(.degrees(isExpanded ? 90 : 0))
          .accessibleAnimation(theme.animation.bouncy, value: isExpanded)
          .accessibilityHidden(true)
      }
      .padding(.horizontal, theme.spacing.md)
      .padding(.vertical, theme.spacing.sm)
      .frame(minHeight: minTouchTarget)
      .background(theme.colors.surface)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .combine)
    .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
    .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")
    .accessibilityAddTraits(.isButton)
  }

  @ViewBuilder
  private var expandableContent: some View {
    if isExpanded {
      content
        .padding(.top, theme.spacing.sm)
        .padding(.horizontal, theme.spacing.md)
        .padding(.leading, nestingIndent)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
  }

  private func toggleExpansion() {
    let newValue = !isExpanded

    withAnimation(shouldAnimate ? theme.animation.smooth : nil) {
      if let coordinator, inGroup {
        coordinator.toggleExpansion(for: id)
      } else if let externalExpanded {
        externalExpanded.wrappedValue = newValue
      } else {
        localExpanded = newValue
      }
    }

    IronLogger.ui.debug(
      "IronAccordion toggled",
      metadata: ["expanded": .string("\(newValue)"), "id": .string(id)]
    )
  }
}

// MARK: - LocalizedStringKey Convenience Initializers

extension IronAccordion where Header == IronText {

  /// Creates an accordion with a localized text title.
  ///
  /// - Parameters:
  ///   - title: The localized title for the accordion header.
  ///   - isExpanded: An optional binding to control the expansion state.
  ///   - content: A view builder that creates the expandable content.
  public init(
    _ title: LocalizedStringKey,
    isExpanded: Binding<Bool>? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.init(isExpanded: isExpanded) {
      IronText(title, style: .labelLarge, color: .primary)
    } content: {
      content()
    }
  }
}

// MARK: - String Convenience Initializers

extension IronAccordion where Header == IronText {

  /// Creates an accordion with a string title.
  ///
  /// - Parameters:
  ///   - title: The string title for the accordion header.
  ///   - isExpanded: An optional binding to control the expansion state.
  ///   - content: A view builder that creates the expandable content.
  public init(
    _ title: some StringProtocol,
    isExpanded: Binding<Bool>? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.init(isExpanded: isExpanded) {
      IronText(title, style: .labelLarge, color: .primary)
    } content: {
      content()
    }
  }
}

// MARK: - Icon Header Convenience Initializers

extension IronAccordion where Header == HStack<TupleView<(IronIcon, IronText)>> {

  /// Creates an accordion with an icon and localized title.
  ///
  /// - Parameters:
  ///   - title: The localized title for the accordion header.
  ///   - icon: The SF Symbol name for the leading icon.
  ///   - isExpanded: An optional binding to control the expansion state.
  ///   - content: A view builder that creates the expandable content.
  public init(
    _ title: LocalizedStringKey,
    icon: String,
    isExpanded: Binding<Bool>? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.init(isExpanded: isExpanded) {
      HStack {
        IronIcon(systemName: icon, size: .medium, color: .primary)
        IronText(title, style: .labelLarge, color: .primary)
      }
    } content: {
      content()
    }
  }

  /// Creates an accordion with an icon and string title.
  ///
  /// - Parameters:
  ///   - title: The string title for the accordion header.
  ///   - icon: The SF Symbol name for the leading icon.
  ///   - isExpanded: An optional binding to control the expansion state.
  ///   - content: A view builder that creates the expandable content.
  public init(
    _ title: some StringProtocol,
    icon: String,
    isExpanded: Binding<Bool>? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.init(isExpanded: isExpanded) {
      HStack {
        IronIcon(systemName: icon, size: .medium, color: .primary)
        IronText(title, style: .labelLarge, color: .primary)
      }
    } content: {
      content()
    }
  }
}

// MARK: - Previews

#Preview("IronAccordion - Basic") {
  VStack(spacing: 0) {
    IronAccordion("Basic Accordion") {
      VStack(alignment: .leading, spacing: 8) {
        Text("This is the accordion content.")
        Text("It can contain any views.")
      }
    }
  }
  .padding()
}

#Preview("IronAccordion - Controlled") {
  @Previewable @State var expanded = true

  VStack(spacing: 0) {
    IronAccordion("Controlled Accordion", isExpanded: $expanded) {
      VStack(alignment: .leading, spacing: 8) {
        Text("This accordion's state is controlled externally.")
        Text("The binding allows for programmatic control.")
      }
    }

    Button(expanded ? "Collapse" : "Expand") {
      expanded.toggle()
    }
    .padding(.top, 16)
  }
  .padding()
}

#Preview("IronAccordion - With Icon") {
  VStack(spacing: 0) {
    IronAccordion("Settings", icon: "gear") {
      Text("Settings content goes here.")
    }

    IronAccordion("Privacy", icon: "lock.shield") {
      Text("Privacy settings content.")
    }

    IronAccordion("Notifications", icon: "bell") {
      Text("Notification preferences.")
    }
  }
  .padding()
}

#Preview("IronAccordion - Custom Header") {
  VStack(spacing: 0) {
    IronAccordion {
      HStack(spacing: 8) {
        IronIcon(systemName: "star.fill", color: .warning)
        IronText("Premium Features", style: .headlineSmall, color: .primary)
        Spacer()
        Text("PRO")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.white)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Capsule().fill(.blue))
      }
    } content: {
      VStack(alignment: .leading, spacing: 8) {
        Text("Unlock all premium features with a subscription.")
        Text("- Advanced analytics")
        Text("- Priority support")
        Text("- Custom themes")
      }
    }
  }
  .padding()
}

#Preview("IronAccordion - Nested") {
  VStack(spacing: 0) {
    IronAccordion("Parent Accordion", isExpanded: .constant(true)) {
      VStack(alignment: .leading, spacing: 8) {
        Text("Parent content")

        IronAccordion("Nested Child", isExpanded: .constant(true)) {
          VStack(alignment: .leading, spacing: 8) {
            Text("Child content")

            IronAccordion("Deeply Nested") {
              Text("Deep content")
            }
          }
        }
      }
    }
  }
  .padding()
}
