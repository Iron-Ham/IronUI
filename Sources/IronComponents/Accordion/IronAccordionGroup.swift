import IronCore
import IronPrimitives
import SwiftUI

// MARK: - IronAccordionGroup

/// A container for multiple accordions with coordinated expand behavior.
///
/// `IronAccordionGroup` manages the expand/collapse state of multiple
/// ``IronAccordion`` items, supporting both exclusive (one at a time)
/// and independent (multiple open) expand behaviors.
///
/// ## Basic Usage
///
/// ```swift
/// IronAccordionGroup {
///   IronAccordion("General") {
///     Text("General settings")
///   }
///   IronAccordion("Privacy") {
///     Text("Privacy settings")
///   }
///   IronAccordion("Notifications") {
///     Text("Notification settings")
///   }
/// }
/// ```
///
/// ## Exclusive Expand (Classic Accordion)
///
/// Only one section can be open at a time:
///
/// ```swift
/// IronAccordionGroup(expandBehavior: .exclusive) {
///   IronAccordion("Section 1") { Text("Content 1") }
///   IronAccordion("Section 2") { Text("Content 2") }
///   IronAccordion("Section 3") { Text("Content 3") }
/// }
/// ```
///
/// ## Independent Expand
///
/// Multiple sections can be open simultaneously:
///
/// ```swift
/// IronAccordionGroup(expandBehavior: .independent) {
///   IronAccordion("Section 1") { Text("Content 1") }
///   IronAccordion("Section 2") { Text("Content 2") }
/// }
/// ```
///
/// ## Without Dividers
///
/// ```swift
/// IronAccordionGroup(showDividers: false) {
///   IronAccordion("Section 1") { Text("Content 1") }
///   IronAccordion("Section 2") { Text("Content 2") }
/// }
/// ```
public struct IronAccordionGroup<Content: View>: View {

  // MARK: Lifecycle

  /// Creates an accordion group.
  ///
  /// - Parameters:
  ///   - expandBehavior: How accordions expand/collapse. Defaults to `.independent`.
  ///   - showDividers: Whether to show dividers between items. Defaults to `true`.
  ///   - content: A view builder that creates the accordion items.
  public init(
    expandBehavior: IronAccordionExpandBehavior = .independent,
    showDividers: Bool = true,
    @ViewBuilder content: () -> Content
  ) {
    self.expandBehavior = expandBehavior
    self.showDividers = showDividers
    self.content = content()
    _coordinator = State(initialValue: IronAccordionCoordinator(expandBehavior: expandBehavior))
  }

  // MARK: Public

  public var body: some View {
    VStack(spacing: 0) {
      if showDividers {
        _VariadicView.Tree(DividerLayout(theme: theme)) {
          content
        }
      } else {
        content
      }
    }
    .environment(\.ironAccordionCoordinator, coordinator)
    .environment(\.ironAccordionInGroup, true)
    .onChange(of: expandBehavior) { _, newValue in
      coordinator.expandBehavior = newValue
    }
    .accessibilityElement(children: .contain)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  @State private var coordinator: IronAccordionCoordinator

  private let expandBehavior: IronAccordionExpandBehavior
  private let showDividers: Bool
  private let content: Content
}

// MARK: - DividerLayout

/// A variadic view layout that inserts dividers between children.
private struct DividerLayout: _VariadicView_UnaryViewRoot {
  let theme: AnyIronTheme

  func body(children: _VariadicView.Children) -> some View {
    VStack(spacing: 0) {
      ForEach(Array(children.enumerated()), id: \.offset) { index, child in
        child

        if index < children.count - 1 {
          IronDivider(style: .subtle)
        }
      }
    }
  }
}

// MARK: - Previews

#Preview("IronAccordionGroup - Independent") {
  IronAccordionGroup(expandBehavior: .independent) {
    IronAccordion("General") {
      VStack(alignment: .leading, spacing: 4) {
        Text("General settings content")
        Text("Multiple sections can be open")
      }
    }
    IronAccordion("Privacy") {
      VStack(alignment: .leading, spacing: 4) {
        Text("Privacy settings content")
        Text("This can be open at the same time as General")
      }
    }
    IronAccordion("Notifications") {
      VStack(alignment: .leading, spacing: 4) {
        Text("Notification settings content")
      }
    }
  }
  .padding()
}

#Preview("IronAccordionGroup - Exclusive") {
  IronAccordionGroup(expandBehavior: .exclusive) {
    IronAccordion("Section 1", icon: "1.circle") {
      Text("Only one section can be open at a time.")
    }
    IronAccordion("Section 2", icon: "2.circle") {
      Text("Opening this will close Section 1.")
    }
    IronAccordion("Section 3", icon: "3.circle") {
      Text("Opening this will close the previously open section.")
    }
  }
  .padding()
}

#Preview("IronAccordionGroup - No Dividers") {
  IronAccordionGroup(showDividers: false) {
    IronAccordion("First") {
      Text("First section content")
    }
    IronAccordion("Second") {
      Text("Second section content")
    }
    IronAccordion("Third") {
      Text("Third section content")
    }
  }
  .padding()
}

#Preview("IronAccordionGroup - FAQ Example") {
  ScrollView {
    VStack(alignment: .leading, spacing: 16) {
      IronText("Frequently Asked Questions", style: .headlineMedium)

      IronAccordionGroup(expandBehavior: .exclusive) {
        IronAccordion("What is IronUI?") {
          Text("IronUI is a modern, accessible SwiftUI design system for iOS and macOS.")
        }
        IronAccordion("How do I install it?") {
          VStack(alignment: .leading, spacing: 8) {
            Text("Add IronUI to your project using Swift Package Manager:")
            Text(".package(url: \"...\", from: \"1.0.0\")")
              .font(.system(.body, design: .monospaced))
              .padding(8)
              .background(Color.gray.opacity(0.1))
              .cornerRadius(4)
          }
        }
        IronAccordion("Is it accessible?") {
          Text("Yes! IronUI is built with accessibility as a core requirement. All components support VoiceOver, Dynamic Type, and reduced motion preferences.")
        }
        IronAccordion("What platforms are supported?") {
          VStack(alignment: .leading, spacing: 4) {
            Text("• iOS 26+")
            Text("• macOS 26+")
          }
        }
      }
    }
    .padding()
  }
}
