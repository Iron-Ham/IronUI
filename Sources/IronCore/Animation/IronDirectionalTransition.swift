import SwiftUI

// MARK: - IronDirection

/// Represents a navigation direction for transitions.
public enum IronDirection: Sendable {
  case forward
  case backward
  case up
  case down

  // MARK: Public

  /// The horizontal edge for this direction.
  public var horizontalEdge: Edge {
    switch self {
    case .forward: .trailing
    case .backward: .leading
    case .up, .down: .leading
    }
  }

  /// The vertical edge for this direction.
  public var verticalEdge: Edge {
    switch self {
    case .up: .top
    case .down: .bottom
    case .forward, .backward: .bottom
    }
  }

  /// The opposite direction.
  public var opposite: IronDirection {
    switch self {
    case .forward: .backward
    case .backward: .forward
    case .up: .down
    case .down: .up
    }
  }
}

// MARK: - Directional Transitions

extension AnyTransition {
  /// A transition that slides in the specified direction.
  ///
  /// Use this for tab switches or page navigation where the motion
  /// should communicate direction.
  ///
  /// ```swift
  /// TabView(selection: $tab) {
  ///   ForEach(tabs) { tab in
  ///     TabContent(tab: tab)
  ///       .transition(.ironSlide(direction))
  ///   }
  /// }
  /// ```
  ///
  /// - Parameter direction: The direction of the transition.
  /// - Returns: A directional slide transition.
  public static func ironSlide(_ direction: IronDirection) -> AnyTransition {
    .asymmetric(
      insertion: .move(edge: direction.horizontalEdge).combined(with: .opacity),
      removal: .move(edge: direction.opposite.horizontalEdge).combined(with: .opacity),
    )
  }

  /// A transition that pushes content like a navigation stack.
  ///
  /// The incoming view slides in from the direction while the
  /// outgoing view slides out in the opposite direction.
  ///
  /// - Parameter direction: The direction of the push.
  /// - Returns: A push-style transition.
  public static func ironPush(_ direction: IronDirection) -> AnyTransition {
    .asymmetric(
      insertion: .move(edge: direction.horizontalEdge),
      removal: .move(edge: direction.opposite.horizontalEdge),
    )
  }
}

// MARK: - DirectionalTransitionModifier

/// A modifier that applies directional transitions based on index changes.
struct DirectionalTransitionModifier: ViewModifier {
  init(currentIndex: Int) {
    self.currentIndex = currentIndex
    _previousIndex = State(initialValue: currentIndex)
  }

  let currentIndex: Int

  func body(content: Content) -> some View {
    content
      .transition(.ironSlide(direction))
      .onChange(of: currentIndex) { oldValue, newValue in
        direction = newValue > oldValue ? .forward : .backward
        previousIndex = newValue
      }
  }

  @State private var previousIndex: Int
  @State private var direction = IronDirection.forward

}

extension View {
  /// Applies a directional transition based on index changes.
  ///
  /// Automatically determines the transition direction based on
  /// whether the index increased or decreased.
  ///
  /// ```swift
  /// ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
  ///   if selectedIndex == index {
  ///     TabContent(tab: tab)
  ///       .ironDirectionalTransition(index: selectedIndex)
  ///   }
  /// }
  /// ```
  ///
  /// - Parameter index: The current index to track for direction.
  /// - Returns: A view with directional transition applied.
  public func ironDirectionalTransition(index: Int) -> some View {
    modifier(DirectionalTransitionModifier(currentIndex: index))
  }
}

// MARK: - IronDirectionalContainer

/// A container that manages directional transitions for indexed content.
///
/// `IronDirectionalContainer` automatically applies the correct transition
/// direction when switching between indexed views, like tabs or pages.
///
/// ## Usage
///
/// ```swift
/// @State private var selectedTab = 0
///
/// IronDirectionalContainer(selection: $selectedTab) { index in
///   switch index {
///   case 0: HomeView()
///   case 1: SearchView()
///   case 2: ProfileView()
///   default: EmptyView()
///   }
/// }
/// ```
public struct IronDirectionalContainer<Content: View>: View {

  // MARK: Lifecycle

  /// Creates a directional container.
  ///
  /// - Parameters:
  ///   - selection: Binding to the currently selected index.
  ///   - content: A closure that returns the view for a given index.
  public init(
    selection: Binding<Int>,
    @ViewBuilder content: @escaping (Int) -> Content,
  ) {
    _selection = selection
    self.content = content
  }

  // MARK: Public

  public var body: some View {
    ZStack {
      content(selection)
        .id(selection)
        .transition(.ironSlide(direction))
    }
    .onChange(of: selection) { oldValue, newValue in
      direction = newValue > oldValue ? .forward : .backward
    }
    .animation(.smooth, value: selection)
  }

  // MARK: Private

  @Binding private var selection: Int
  @State private var direction = IronDirection.forward

  private let content: (Int) -> Content
}

// MARK: - Previews

#Preview("Directional Transitions") {
  @Previewable @State var selectedTab = 0

  let tabs = ["Home", "Search", "Profile"]
  let colors: [Color] = [.blue, .green, .purple]

  VStack(spacing: 0) {
    // Content
    IronDirectionalContainer(selection: $selectedTab) { index in
      ZStack {
        colors[index].opacity(0.2)
        Text(tabs[index])
          .font(.largeTitle)
          .fontWeight(.bold)
      }
    }

    Divider()

    // Tab bar
    HStack {
      ForEach(0 ..< 3) { index in
        Button {
          withAnimation(.smooth) {
            selectedTab = index
          }
        } label: {
          Text(tabs[index])
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selectedTab == index ? colors[index].opacity(0.2) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
      }
    }
    .padding()
  }
}

#Preview("Slide Transition") {
  @Previewable @State var showDetail = false

  VStack {
    if showDetail {
      VStack {
        Text("Detail View")
          .font(.title)
        Text("Slide back to dismiss")
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.purple.opacity(0.2))
      .transition(.ironSlide(.forward))
    } else {
      VStack {
        Text("Main View")
          .font(.title)
        Text("Tap to show detail")
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.blue.opacity(0.2))
      .transition(.ironSlide(.backward))
    }
  }
  .onTapGesture {
    withAnimation(.smooth) {
      showDetail.toggle()
    }
  }
}
