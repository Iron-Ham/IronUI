import IronCore
import IronPrimitives
import SwiftUI

// MARK: - IronTray

/// A dynamic content-sized card that overlays the current interface.
///
/// `IronTray` implements the Family-style tray pattern where:
/// - The tray **sizes itself to fit its content** (not fixed detents)
/// - Height changes animate smoothly to signal progression
/// - Sequential flows use a navigation stack within the tray
/// - Each tray focuses on a single piece of content or action
///
/// ## Basic Usage
///
/// ```swift
/// @State private var showTray = false
///
/// Button("Show") { showTray = true }
///   .ironTray(isPresented: $showTray) {
///     VStack {
///       Text("Welcome!")
///       Button("Continue") { /* next step */ }
///     }
///   }
/// ```
///
/// ## Sequential Flows
///
/// For multi-step flows, use `IronTrayStack` to manage navigation:
///
/// ```swift
/// .ironTray(isPresented: $showTray) {
///   IronTrayStack {
///     StepOne()
///   }
/// }
/// ```
public struct IronTray<Content: View>: View {

  // MARK: Lifecycle

  /// Creates a content-sized tray.
  ///
  /// - Parameters:
  ///   - isDragIndicatorVisible: Whether to show the drag handle.
  ///   - onDismiss: Called when the tray is dismissed.
  ///   - content: The tray content - height is determined by this content.
  public init(
    isDragIndicatorVisible: Bool = true,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: () -> Content,
  ) {
    self.isDragIndicatorVisible = isDragIndicatorVisible
    self.onDismiss = onDismiss
    self.content = content()
  }

  // MARK: Public

  public var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .bottom) {
        // Background dimming
        Color.black
          .opacity(isVisible ? 0.4 : 0)
          .ignoresSafeArea()
          .onTapGesture {
            dismissTray()
          }
          .accessibilityHidden(true)

        // Tray card
        VStack(spacing: 0) {
          // Drag indicator
          if isDragIndicatorVisible {
            dragIndicator
          }

          // Content - sizes the tray
          content
            .frame(maxWidth: .infinity)
            .padding(.bottom, geometry.safeAreaInsets.bottom)
        }
        .background(trayBackground)
        .clipShape(
          UnevenRoundedRectangle(
            topLeadingRadius: theme.radii.xl,
            topTrailingRadius: theme.radii.xl,
          )
        )
        .ignoresSafeArea(edges: .bottom)
        .ironShadow(theme.shadows.xl)
        .offset(y: dragOffset + (isVisible ? 0 : 500))
        .gesture(dragGesture)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityLabel("Tray")
      }
      .animation(animation, value: isVisible)
      .animation(animation, value: dragOffset)
      .onAppear {
        withAnimation(animation) {
          isVisible = true
        }
      }
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @State private var isVisible = false
  @State private var dragOffset: CGFloat = 0

  private let isDragIndicatorVisible: Bool
  private let onDismiss: (() -> Void)?
  private let content: Content

  private var animation: Animation {
    reduceMotion ? .linear(duration: 0) : theme.animation.smooth
  }

  private var trayBackground: some View {
    Rectangle()
      .fill(.ultraThinMaterial)
      .overlay {
        theme.colors.surface
          .opacity(0.85)
      }
  }

  private var dragIndicator: some View {
    Capsule()
      .fill(theme.colors.textSecondary.opacity(0.4))
      .frame(width: 36, height: 5)
      .padding(.top, theme.spacing.sm)
      .padding(.bottom, theme.spacing.xs)
  }

  private var dragGesture: some Gesture {
    DragGesture()
      .onChanged { value in
        // Only allow dragging down
        dragOffset = max(0, value.translation.height)
      }
      .onEnded { value in
        let velocity = value.predictedEndTranslation.height - value.translation.height

        // Dismiss if dragged down significantly with downward velocity
        if value.translation.height > 100 || velocity > 500 {
          dismissTray()
        } else {
          withAnimation(animation) {
            dragOffset = 0
          }
        }
      }
  }

  private func dismissTray() {
    withAnimation(animation) {
      isVisible = false
      dragOffset = 0
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      onDismiss?()
    }
  }
}

// MARK: - IronTrayHeader

/// A header for `IronTray` with title and dismiss/back action.
///
/// The icon adapts based on navigation depth:
/// - First tray: Shows close (X) icon
/// - Subsequent trays: Shows back (chevron) icon
///
/// ```swift
/// IronTray {
///   VStack {
///     IronTrayHeader("Settings", onDismiss: { showTray = false })
///     // Content...
///   }
/// }
/// ```
public struct IronTrayHeader: View {

  // MARK: Lifecycle

  /// Creates a tray header.
  ///
  /// - Parameters:
  ///   - title: The header title.
  ///   - isBackButtonVisible: If true, shows back arrow instead of close.
  ///   - onDismiss: Action when the button is tapped.
  public init(
    _ title: LocalizedStringKey,
    isBackButtonVisible: Bool = false,
    onDismiss: @escaping () -> Void,
  ) {
    self.title = title
    self.isBackButtonVisible = isBackButtonVisible
    self.onDismiss = onDismiss
  }

  // MARK: Public

  public var body: some View {
    HStack {
      Button {
        IronLogger.ui.debug(
          "IronTrayHeader tapped",
          metadata: ["isBack": .string("\(isBackButtonVisible)")],
        )
        onDismiss()
      } label: {
        IronIcon(
          systemName: isBackButtonVisible ? "chevron.left" : "xmark",
          size: .small,
          color: .secondary,
        )
        .fontWeight(.semibold)
        .frame(width: 32, height: 32)
        .background {
          Circle()
            .fill(theme.colors.surfaceElevated)
        }
      }
      .buttonStyle(.plain)
      .accessibilityLabel(isBackButtonVisible ? "Back" : "Close")

      Spacer()

      IronText(title, style: .headlineSmall, color: .primary)

      Spacer()

      // Invisible spacer for centering
      Color.clear
        .frame(width: 32, height: 32)
    }
    .padding(.horizontal, theme.spacing.md)
    .padding(.vertical, theme.spacing.sm)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private let title: LocalizedStringKey
  private let isBackButtonVisible: Bool
  private let onDismiss: () -> Void
}

// MARK: - IronTrayStack

/// Manages sequential navigation within a tray.
///
/// Use `IronTrayStack` for multi-step flows where each step
/// should animate with a height change to signal progression.
///
/// ```swift
/// struct OnboardingTray: View {
///   var body: some View {
///     IronTrayStack { navigator in
///       WelcomeStep(onContinue: {
///         navigator.push { DetailsStep() }
///       })
///     }
///   }
/// }
/// ```
public struct IronTrayStack<Root: View>: View {

  // MARK: Lifecycle

  /// Creates a tray navigation stack.
  ///
  /// - Parameter root: The initial view, receiving a navigator for pushing new views.
  public init(@ViewBuilder root: @escaping (IronTrayNavigator) -> Root) {
    self.root = root
  }

  // MARK: Public

  public var body: some View {
    ZStack {
      // Show current view from stack
      if let current = stack.last {
        current.view
          .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity),
          ))
      } else {
        root(navigator)
          .transition(.opacity)
      }
    }
    .animation(animation, value: stack.count)
  }

  // MARK: Private

  private struct StackEntry: Identifiable {
    let id = UUID()
    let view: AnyView
  }

  @Environment(\.ironTheme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @State private var stack = [StackEntry]()

  private let root: (IronTrayNavigator) -> Root

  private var animation: Animation {
    reduceMotion ? .linear(duration: 0) : theme.animation.smooth
  }

  private var navigator: IronTrayNavigator {
    IronTrayNavigator(
      push: { view in
        withAnimation(animation) {
          stack.append(StackEntry(view: AnyView(view)))
        }
      },
      pop: {
        withAnimation(animation) {
          _ = stack.popLast()
        }
      },
      popToRoot: {
        withAnimation(animation) {
          stack.removeAll()
        }
      },
      depth: stack.count,
    )
  }
}

// MARK: - IronTrayNavigator

/// Provides navigation control within an `IronTrayStack`.
public struct IronTrayNavigator {

  // MARK: Lifecycle

  fileprivate init(
    push: @escaping (AnyView) -> Void,
    pop: @escaping () -> Void,
    popToRoot: @escaping () -> Void,
    depth: Int,
  ) {
    pushAction = push
    popAction = pop
    popToRootAction = popToRoot
    self.depth = depth
  }

  // MARK: Public

  /// The current depth in the stack (0 = root).
  public var depth: Int

  /// Whether we're at the root level.
  public var isAtRoot: Bool {
    depth == 0
  }

  /// Pushes a new view onto the tray stack.
  public func push(@ViewBuilder _ view: () -> some View) {
    pushAction(AnyView(view()))
  }

  /// Pops the current view, returning to the previous one.
  public func pop() {
    popAction()
  }

  /// Pops all views, returning to the root.
  public func popToRoot() {
    popToRootAction()
  }

  // MARK: Private

  private let pushAction: (AnyView) -> Void
  private let popAction: () -> Void
  private let popToRootAction: () -> Void
}

// MARK: - Previews

#Preview("IronTray - Basic") {
  @Previewable @State var showTray = true

  ZStack {
    Color.blue.opacity(0.2)
      .ignoresSafeArea()

    VStack {
      Text("Background Content")
      Button("Show Tray") {
        showTray = true
      }
      .buttonStyle(.borderedProminent)
    }

    if showTray {
      IronTray(onDismiss: { showTray = false }) {
        VStack(spacing: 16) {
          IronTrayHeader("Welcome", onDismiss: { showTray = false })

          Text("This tray sizes to fit its content.")
            .foregroundStyle(.secondary)
            .padding(.horizontal)

          Button("Got it") {
            showTray = false
          }
          .buttonStyle(.borderedProminent)
          .padding(.bottom)
        }
      }
    }
  }
}

#Preview("IronTray - Varying Content") {
  @Previewable @State var showTray = true
  @Previewable @State var showMore = false

  ZStack {
    Color.green.opacity(0.2)
      .ignoresSafeArea()

    VStack {
      Text("Tap to show more content")
      Button("Show Tray") {
        showTray = true
        showMore = false
      }
      .buttonStyle(.borderedProminent)
    }

    if showTray {
      IronTray(onDismiss: { showTray = false }) {
        VStack(spacing: 16) {
          IronTrayHeader("Dynamic Height", onDismiss: { showTray = false })

          Text("Watch the height animate!")
            .padding(.horizontal)

          if showMore {
            VStack(spacing: 12) {
              ForEach(1 ... 5, id: \.self) { i in
                Text("Additional item \(i)")
                  .frame(maxWidth: .infinity)
                  .padding()
                  .background(Color.gray.opacity(0.1))
                  .clipShape(RoundedRectangle(cornerRadius: 8))
              }
            }
            .padding(.horizontal)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
          }

          Button(showMore ? "Show Less" : "Show More") {
            withAnimation(.smooth) {
              showMore.toggle()
            }
          }
          .buttonStyle(.borderedProminent)
          .padding(.bottom)
        }
      }
    }
  }
}

#Preview("IronTray - Sequential Flow") {
  @Previewable @State var showTray = true

  ZStack {
    Color.purple.opacity(0.2)
      .ignoresSafeArea()

    VStack {
      Text("Multi-step flow demo")
      Button("Show Tray") {
        showTray = true
      }
      .buttonStyle(.borderedProminent)
    }

    if showTray {
      IronTray(onDismiss: { showTray = false }) {
        IronTrayStack { navigator in
          // Step 1 - shorter
          VStack(spacing: 16) {
            IronTrayHeader("Step 1", onDismiss: { showTray = false })

            Text("This is the first step.")
              .padding(.horizontal)

            Button("Continue") {
              navigator.push {
                // Step 2 - taller
                VStack(spacing: 16) {
                  IronTrayHeader("Step 2", isBackButtonVisible: true, onDismiss: { navigator.pop() })

                  Text("Notice the height change!")
                    .padding(.horizontal)

                  ForEach(1 ... 3, id: \.self) { i in
                    Text("Detail \(i)")
                      .frame(maxWidth: .infinity)
                      .padding()
                      .background(Color.gray.opacity(0.1))
                      .clipShape(RoundedRectangle(cornerRadius: 8))
                  }
                  .padding(.horizontal)

                  Button("Finish") {
                    showTray = false
                  }
                  .buttonStyle(.borderedProminent)
                  .padding(.bottom)
                }
              }
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
          }
        }
      }
    }
  }
}
