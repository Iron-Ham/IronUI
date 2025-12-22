import IronCore
import IronPrimitives
import SwiftUI

// MARK: - IronTray

/// A dynamic bottom sheet that overlays content with configurable heights.
///
/// `IronTray` provides a Family-style tray presentation with:
/// - Multiple height detents for progressive disclosure
/// - Drag-to-dismiss with velocity detection
/// - Optional navigation header with dismiss/back actions
/// - Background dimming with tap-to-dismiss
/// - Adaptive theming support
///
/// ## Basic Usage
///
/// ```swift
/// @State private var showTray = false
///
/// Button("Show Tray") { showTray = true }
///   .ironTray(isPresented: $showTray) {
///     Text("Tray Content")
///   }
/// ```
///
/// ## Multiple Detents
///
/// ```swift
/// .ironTray(
///   isPresented: $showTray,
///   detents: [.medium, .large],
///   selectedDetent: $currentDetent
/// ) {
///   ScrollView { /* ... */ }
/// }
/// ```
///
/// ## With Navigation Header
///
/// ```swift
/// .ironTray(isPresented: $showTray) {
///   TrayContent()
/// } header: {
///   IronTrayHeader(title: "Settings") {
///     showTray = false
///   }
/// }
/// ```
public struct IronTray<Content: View, Header: View>: View {

  // MARK: Lifecycle

  /// Creates a tray with custom header.
  ///
  /// - Parameters:
  ///   - detents: The available height detents.
  ///   - selectedDetent: Binding to the current detent.
  ///   - showsDragIndicator: Whether to show the drag handle.
  ///   - content: The tray content.
  ///   - header: The header view.
  public init(
    detents: Set<IronTrayDetent> = [.medium],
    selectedDetent: Binding<IronTrayDetent>? = nil,
    showsDragIndicator: Bool = true,
    @ViewBuilder content: () -> Content,
    @ViewBuilder header: () -> Header,
  ) {
    self.detents = detents.isEmpty ? [.medium] : detents
    _externalSelectedDetent = selectedDetent ?? .constant(.medium)
    self.showsDragIndicator = showsDragIndicator
    self.content = content()
    self.header = header()
  }

  // MARK: Public

  public var body: some View {
    GeometryReader { geometry in
      let availableHeight = geometry.size.height

      ZStack(alignment: .bottom) {
        // Background dimming
        Color.black
          .opacity(dimOpacity)
          .ignoresSafeArea()
          .onTapGesture {
            dismissTray()
          }
          .accessibilityHidden(true)

        // Tray container
        VStack(spacing: 0) {
          // Drag indicator
          if showsDragIndicator {
            dragIndicator
          }

          // Header
          header

          // Content
          content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: currentHeight + dragOffset)
        .frame(maxWidth: .infinity)
        .background(trayBackground)
        .clipShape(
          UnevenRoundedRectangle(
            topLeadingRadius: theme.radii.xl,
            topTrailingRadius: theme.radii.xl,
          )
        )
        .ironShadow(theme.shadows.lg)
        .offset(y: max(0, -dragOffset))
        .gesture(dragGesture(availableHeight: availableHeight))
        .onAppear {
          measureAndSetInitialDetent(availableHeight: availableHeight)
        }
        .onChange(of: intrinsicHeight) {
          updateCurrentHeight(availableHeight: availableHeight)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityLabel("Tray")
      }
      .animation(animation, value: currentHeight)
      .animation(animation, value: dragOffset)
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.dismiss) private var dismiss

  @Binding private var externalSelectedDetent: IronTrayDetent
  @State private var currentHeight: CGFloat = 0
  @State private var dragOffset: CGFloat = 0
  @State private var intrinsicHeight: CGFloat = 300
  @State private var isDragging = false

  private let detents: Set<IronTrayDetent>
  private let showsDragIndicator: Bool
  private let content: Content
  private let header: Header

  private var animation: Animation {
    reduceMotion ? .linear(duration: 0) : theme.animation.smooth
  }

  private var dimOpacity: Double {
    let maxOpacity = 0.4
    let progress = min(currentHeight / 500, 1.0)
    return maxOpacity * progress
  }

  private var trayBackground: some View {
    Rectangle()
      .fill(.ultraThinMaterial)
      .overlay {
        theme.colors.surface
          .opacity(0.8)
      }
  }

  private var dragIndicator: some View {
    Capsule()
      .fill(theme.colors.textSecondary.opacity(0.4))
      .frame(width: 36, height: 5)
      .padding(.top, theme.spacing.sm)
      .padding(.bottom, theme.spacing.xs)
  }

  private func dragGesture(availableHeight: CGFloat) -> some Gesture {
    DragGesture()
      .onChanged { value in
        isDragging = true
        dragOffset = -value.translation.height
      }
      .onEnded { value in
        isDragging = false
        handleDragEnd(
          translation: value.translation.height,
          velocity: value.predictedEndTranslation.height - value.translation.height,
          availableHeight: availableHeight,
        )
      }
  }

  private func handleDragEnd(
    translation: CGFloat,
    velocity: CGFloat,
    availableHeight: CGFloat,
  ) {
    let projectedHeight = currentHeight - translation - velocity * 0.3

    // Dismiss threshold: dragged down past 30% of current height with downward velocity
    if translation > currentHeight * 0.3, velocity > 0 {
      dismissTray()
      return
    }

    // Find the nearest detent
    let sortedDetents = detents.sorted()
    var nearestDetent = sortedDetents.first ?? .medium

    for detent in sortedDetents {
      let detentHeight = detent.resolvedHeight(
        availableHeight: availableHeight,
        intrinsicHeight: intrinsicHeight,
      )
      let nearestHeight = nearestDetent.resolvedHeight(
        availableHeight: availableHeight,
        intrinsicHeight: intrinsicHeight,
      )

      if abs(projectedHeight - detentHeight) < abs(projectedHeight - nearestHeight) {
        nearestDetent = detent
      }
    }

    withAnimation(animation) {
      dragOffset = 0
      externalSelectedDetent = nearestDetent
      currentHeight = nearestDetent.resolvedHeight(
        availableHeight: availableHeight,
        intrinsicHeight: intrinsicHeight,
      )
    }
  }

  private func dismissTray() {
    withAnimation(animation) {
      currentHeight = 0
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      dismiss()
    }
  }

  private func measureAndSetInitialDetent(availableHeight: CGFloat) {
    let initialDetent = detents.sorted().first ?? .medium
    externalSelectedDetent = initialDetent
    currentHeight = initialDetent.resolvedHeight(
      availableHeight: availableHeight,
      intrinsicHeight: intrinsicHeight,
    )
  }

  private func updateCurrentHeight(availableHeight: CGFloat) {
    currentHeight = externalSelectedDetent.resolvedHeight(
      availableHeight: availableHeight,
      intrinsicHeight: intrinsicHeight,
    )
  }
}

// MARK: - Convenience Initializer (No Header)

extension IronTray where Header == EmptyView {
  /// Creates a tray without a header.
  ///
  /// - Parameters:
  ///   - detents: The available height detents.
  ///   - selectedDetent: Binding to the current detent.
  ///   - showsDragIndicator: Whether to show the drag handle.
  ///   - content: The tray content.
  public init(
    detents: Set<IronTrayDetent> = [.medium],
    selectedDetent: Binding<IronTrayDetent>? = nil,
    showsDragIndicator: Bool = true,
    @ViewBuilder content: () -> Content,
  ) {
    self.init(
      detents: detents,
      selectedDetent: selectedDetent,
      showsDragIndicator: showsDragIndicator,
      content: content,
      header: { EmptyView() },
    )
  }
}

// MARK: - IronTrayHeader

/// A standard header for `IronTray` with title and dismiss/back action.
///
/// ```swift
/// IronTrayHeader(title: "Settings") {
///   dismiss()
/// }
///
/// // With back navigation
/// IronTrayHeader(title: "Details", isBackNavigation: true) {
///   navigateBack()
/// }
/// ```
public struct IronTrayHeader: View {

  // MARK: Lifecycle

  /// Creates a tray header.
  ///
  /// - Parameters:
  ///   - title: The header title.
  ///   - isBackNavigation: If true, shows a back arrow instead of close icon.
  ///   - action: The action when the icon is tapped.
  public init(
    title: LocalizedStringKey,
    isBackNavigation: Bool = false,
    action: @escaping () -> Void,
  ) {
    self.title = title
    self.isBackNavigation = isBackNavigation
    self.action = action
  }

  // MARK: Public

  public var body: some View {
    HStack {
      Button {
        IronLogger.ui.debug(
          "IronTrayHeader action",
          metadata: ["isBack": .string("\(isBackNavigation)")],
        )
        action()
      } label: {
        IronIcon(
          systemName: isBackNavigation ? "chevron.left" : "xmark",
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
      .accessibilityLabel(isBackNavigation ? "Back" : "Close")

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
  private let isBackNavigation: Bool
  private let action: () -> Void
}

// MARK: - Previews

#Preview("IronTray - Basic") {
  @Previewable @State var showTray = true

  ZStack {
    Color.blue.opacity(0.3)
      .ignoresSafeArea()

    VStack {
      Text("Background Content")
      Button("Show Tray") {
        showTray = true
      }
    }

    if showTray {
      IronTray(detents: [.small, .medium, .large]) {
        VStack(spacing: 16) {
          Text("Tray Content")
            .font(.title2)
          Text("Drag to resize or dismiss")
            .foregroundStyle(.secondary)

          ForEach(1 ... 5, id: \.self) { index in
            Text("Item \(index)")
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.gray.opacity(0.1))
              .clipShape(RoundedRectangle(cornerRadius: 8))
          }
        }
        .padding()
      }
    }
  }
}

#Preview("IronTray - With Header") {
  @Previewable @State var showTray = true

  ZStack {
    Color.green.opacity(0.3)
      .ignoresSafeArea()

    if showTray {
      IronTray(detents: [.medium, .large]) {
        VStack(spacing: 16) {
          Text("Settings Content")
          Toggle("Dark Mode", isOn: .constant(false))
          Toggle("Notifications", isOn: .constant(true))
        }
        .padding()
      } header: {
        IronTrayHeader(title: "Settings") {
          showTray = false
        }
      }
    }
  }
}

#Preview("IronTray - Intrinsic Height") {
  IronTray(detents: [.intrinsic]) {
    VStack(spacing: 12) {
      Text("Compact Tray")
        .font(.headline)
      Text("This tray sizes to fit its content")
        .foregroundStyle(.secondary)
      Button("Got it") { }
        .buttonStyle(.borderedProminent)
    }
    .padding()
  }
}
