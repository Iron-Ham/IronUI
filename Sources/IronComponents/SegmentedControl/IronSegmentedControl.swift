import IronCore
import IronPrimitives
import SwiftUI

// MARK: - IronSegmentedControl

/// A themed segmented control with spring-based selection animation.
///
/// `IronSegmentedControl` provides a horizontal set of mutually exclusive
/// options with a sliding selection indicator.
///
/// ## Basic Usage
///
/// ```swift
/// enum Tab: String, CaseIterable {
///   case posts, photos, videos
/// }
///
/// @State private var selectedTab: Tab = .posts
///
/// IronSegmentedControl(
///   selection: $selectedTab,
///   options: Tab.allCases
/// ) { tab in
///   Text(tab.rawValue.capitalized)
/// }
/// ```
///
/// ## With Icons
///
/// ```swift
/// IronSegmentedControl(
///   selection: $selectedTab,
///   options: Tab.allCases
/// ) { tab in
///   Label(tab.rawValue.capitalized, systemImage: tab.icon)
/// }
/// ```
///
/// ## Sizes
///
/// ```swift
/// IronSegmentedControl(selection: $tab, options: tabs, size: .small) { ... }
/// IronSegmentedControl(selection: $tab, options: tabs, size: .large) { ... }
/// ```
public struct IronSegmentedControl<Option: Hashable, Label: View>: View {

  // MARK: Lifecycle

  /// Creates a segmented control.
  ///
  /// - Parameters:
  ///   - selection: Binding to the selected option.
  ///   - options: The available options.
  ///   - size: The size of the control.
  ///   - label: A view builder that creates the label for each option.
  public init(
    selection: Binding<Option>,
    options: [Option],
    size: IronSegmentedControlSize = .medium,
    @ViewBuilder label: @escaping (Option) -> Label,
  ) {
    _selection = selection
    self.options = options
    self.size = size
    labelBuilder = label
  }

  // MARK: Public

  public var body: some View {
    GeometryReader { geometry in
      let segmentWidth = geometry.size.width / CGFloat(options.count)

      ZStack(alignment: .leading) {
        // Background (decorative)
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(theme.colors.surface)
          .accessibilityHidden(true)

        // Selection indicator (decorative)
        RoundedRectangle(cornerRadius: innerCornerRadius)
          .fill(theme.colors.surfaceElevated)
          .shadow(color: theme.colors.primary.opacity(0.1), radius: 2, y: 1)
          .overlay {
            RoundedRectangle(cornerRadius: innerCornerRadius)
              .strokeBorder(theme.colors.primary.opacity(0.3), lineWidth: 1)
          }
          .frame(width: segmentWidth - indicatorPadding * 2)
          .padding(indicatorPadding)
          .offset(x: selectedIndex * segmentWidth)
          .animation(shouldAnimate ? theme.animation.bouncy : nil, value: selection)
          .accessibilityHidden(true)

        // Segments
        HStack(spacing: 0) {
          ForEach(Array(options.enumerated()), id: \.offset) { index, option in
            Button {
              withAnimation(shouldAnimate ? theme.animation.bouncy : nil) {
                selection = option
              }
              IronLogger.ui.debug(
                "IronSegmentedControl selected",
                metadata: ["index": .string("\(index)")],
              )
            } label: {
              labelBuilder(option)
                .font(textFont)
                .fontWeight(selection == option ? .semibold : .regular)
                .foregroundStyle(selection == option ? theme.colors.primary : theme.colors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: controlHeight - indicatorPadding * 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(selection == option ? [.isSelected] : [])
          }
        }
      }
      .frame(height: controlHeight)
    }
    .frame(height: controlHeight)
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Segmented control")
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.ironSkipEntranceAnimations) private var skipEntranceAnimations
  @Namespace private var namespace

  @Binding private var selection: Option

  private let options: [Option]
  private let size: IronSegmentedControlSize
  private let labelBuilder: (Option) -> Label

  private var selectedIndex: CGFloat {
    guard let index = options.firstIndex(of: selection) else { return 0 }
    return CGFloat(index)
  }

  private var controlHeight: CGFloat {
    switch size {
    case .small: 32
    case .medium: 40
    case .large: 48
    }
  }

  private var cornerRadius: CGFloat {
    switch size {
    case .small: theme.radii.sm
    case .medium: theme.radii.md
    case .large: theme.radii.lg
    }
  }

  private var innerCornerRadius: CGFloat {
    cornerRadius - indicatorPadding
  }

  private var indicatorPadding: CGFloat {
    switch size {
    case .small: 3
    case .medium: 4
    case .large: 5
    }
  }

  private var textFont: Font {
    switch size {
    case .small: theme.typography.labelSmall
    case .medium: theme.typography.labelMedium
    case .large: theme.typography.labelLarge
    }
  }

  private var shouldAnimate: Bool {
    !reduceMotion && !skipEntranceAnimations
  }
}

// MARK: - Convenience for String-based options

extension IronSegmentedControl where Label == IronText, Option: CustomStringConvertible {
  /// Creates a segmented control with text labels.
  ///
  /// - Parameters:
  ///   - selection: Binding to the selected option.
  ///   - options: The available options.
  ///   - size: The size of the control.
  public init(
    selection: Binding<Option>,
    options: [Option],
    size: IronSegmentedControlSize = .medium,
  ) {
    _selection = selection
    self.options = options
    self.size = size
    labelBuilder = { option in
      IronText(option.description, style: .labelMedium, color: .primary)
    }
  }
}

// MARK: - IronSegmentedControlSize

/// Size options for `IronSegmentedControl`.
public enum IronSegmentedControlSize: Sendable, CaseIterable {
  /// A compact segmented control.
  case small
  /// The default size.
  case medium
  /// A larger segmented control.
  case large
}

// MARK: - PreviewTab

private enum PreviewTab: String, CaseIterable, CustomStringConvertible {
  case posts
  case photos
  case videos

  var description: String {
    rawValue.capitalized
  }
}

#Preview("IronSegmentedControl - Basic") {
  @Previewable @State var selection = PreviewTab.posts

  IronSegmentedControl(
    selection: $selection,
    options: PreviewTab.allCases,
  )
  .padding()
}

#Preview("IronSegmentedControl - Custom Labels") {
  struct Demo: View {
    @State private var selection = PreviewTab.posts

    var body: some View {
      IronSegmentedControl(
        selection: $selection,
        options: PreviewTab.allCases,
      ) { tab in
        HStack(spacing: 4) {
          Image(systemName: iconName(for: tab))
          Text(tab.rawValue.capitalized)
        }
      }
      .padding()
    }

    func iconName(for tab: PreviewTab) -> String {
      switch tab {
      case .posts: "doc.text"
      case .photos: "photo"
      case .videos: "video"
      }
    }
  }

  return Demo()
}

#Preview("IronSegmentedControl - Sizes") {
  @Previewable @State var selection = PreviewTab.posts

  VStack(spacing: 24) {
    VStack(alignment: .leading) {
      Text("Small").font(.caption).foregroundStyle(.secondary)
      IronSegmentedControl(
        selection: $selection,
        options: PreviewTab.allCases,
        size: .small,
      )
    }

    VStack(alignment: .leading) {
      Text("Medium").font(.caption).foregroundStyle(.secondary)
      IronSegmentedControl(
        selection: $selection,
        options: PreviewTab.allCases,
        size: .medium,
      )
    }

    VStack(alignment: .leading) {
      Text("Large").font(.caption).foregroundStyle(.secondary)
      IronSegmentedControl(
        selection: $selection,
        options: PreviewTab.allCases,
        size: .large,
      )
    }
  }
  .padding()
}

#Preview("IronSegmentedControl - Two Options") {
  struct Demo: View {
    enum Mode: String, CaseIterable, CustomStringConvertible {
      case list, grid

      var description: String {
        rawValue.capitalized
      }
    }

    @State private var mode = Mode.list

    var body: some View {
      IronSegmentedControl(
        selection: $mode,
        options: Mode.allCases,
      ) { mode in
        HStack(spacing: 4) {
          Image(systemName: mode == .list ? "list.bullet" : "square.grid.2x2")
          Text(mode.rawValue.capitalized)
        }
      }
      .frame(width: 200)
      .padding()
    }
  }

  return Demo()
}

#if os(iOS)
#Preview("IronSegmentedControl - In Context") {
  struct Demo: View {
    @State private var selection = PreviewTab.posts

    var body: some View {
      VStack(spacing: 0) {
        IronSegmentedControl(
          selection: $selection,
          options: PreviewTab.allCases,
        )
        .padding()

        Divider()

        TabView(selection: $selection) {
          ForEach(PreviewTab.allCases, id: \.self) { tab in
            VStack {
              IronText("\(tab.rawValue.capitalized) Content", style: .titleMedium, color: .primary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tag(tab)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
      }
    }
  }

  return Demo()
}
#endif
