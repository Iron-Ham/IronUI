import IronCore
import SwiftUI

// MARK: - IronToastModifier

/// A view modifier that presents an `IronToast` overlay.
struct IronToastModifier<ToastContent: View>: ViewModifier {

  // MARK: Lifecycle

  init(
    isPresented: Binding<Bool>,
    position: IronToastPosition,
    duration: TimeInterval,
    @ViewBuilder content: () -> ToastContent,
  ) {
    _isPresented = isPresented
    self.position = position
    self.duration = duration
    toastContent = content()
  }

  // MARK: Internal

  func body(content: Content) -> some View {
    content
      .overlay(alignment: overlayAlignment) {
        if isPresented {
          toastView
            .transition(toastTransition)
            .padding(.horizontal, theme.spacing.md)
            .padding(edgePadding)
            .gesture(swipeDismissGesture)
            .onAppear {
              announceToVoiceOver()
              startDismissTimer()
            }
            .onDisappear {
              dismissTask?.cancel()
            }
        }
      }
      .animation(animation, value: isPresented)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @Binding private var isPresented: Bool

  @State private var dismissTask: Task<Void, Never>?
  @State private var dragOffset: CGFloat = 0

  private let position: IronToastPosition
  private let duration: TimeInterval
  private let toastContent: ToastContent

  private var toastView: some View {
    toastContent
      .offset(y: dragOffset)
  }

  private var animation: Animation {
    reduceMotion ? .linear(duration: 0) : theme.animation.smooth
  }

  private var toastTransition: AnyTransition {
    switch position {
    case .top:
      .asymmetric(
        insertion: .move(edge: .top).combined(with: .opacity),
        removal: .move(edge: .top).combined(with: .opacity),
      )

    case .bottom:
      .asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .move(edge: .bottom).combined(with: .opacity),
      )
    }
  }

  private var overlayAlignment: Alignment {
    switch position {
    case .top(let alignment):
      Alignment(horizontal: alignment, vertical: .top)
    case .bottom(let alignment):
      Alignment(horizontal: alignment, vertical: .bottom)
    }
  }

  private var edgePadding: EdgeInsets {
    switch position {
    case .top:
      EdgeInsets(top: theme.spacing.lg, leading: 0, bottom: 0, trailing: 0)
    case .bottom:
      EdgeInsets(top: 0, leading: 0, bottom: theme.spacing.lg, trailing: 0)
    }
  }

  private var swipeDismissGesture: some Gesture {
    DragGesture()
      .onChanged { value in
        // Only allow dragging in dismiss direction
        switch position {
        case .top:
          dragOffset = min(0, value.translation.height)
        case .bottom:
          dragOffset = max(0, value.translation.height)
        }
      }
      .onEnded { value in
        let threshold: CGFloat = 50
        let shouldDismiss: Bool =
          switch position {
          case .top:
            value.translation.height < -threshold
          case .bottom:
            value.translation.height > threshold
          }

        if shouldDismiss {
          dismiss()
        } else {
          withAnimation(animation) {
            dragOffset = 0
          }
        }
      }
  }

  private func startDismissTimer() {
    dismissTask?.cancel()
    dismissTask = Task { @MainActor in
      try? await Task.sleep(for: .seconds(duration))
      if !Task.isCancelled {
        dismiss()
      }
    }
  }

  private func dismiss() {
    withAnimation(animation) {
      isPresented = false
      dragOffset = 0
    }
  }

  private func announceToVoiceOver() {
    // VoiceOver will automatically read the accessibilityLabel
    // when the toast appears due to the accessibility configuration
  }
}

// MARK: - IronToastContainerModifier

/// A view modifier that displays toasts from an `IronToastContainer`.
struct IronToastContainerModifier: ViewModifier {

  // MARK: Internal

  @Bindable var container: IronToastContainer

  let position: IronToastPosition
  let showsProgress: Bool

  func body(content: Content) -> some View {
    content
      .overlay(alignment: overlayAlignment) {
        if let item = container.currentToast {
          IronToastItemView(
            item: item,
            showsProgress: showsProgress,
            onDismiss: { container.dismiss() },
          )
          .transition(toastTransition)
          .padding(.horizontal, theme.spacing.md)
          .padding(edgePadding)
          .gesture(swipeDismissGesture)
          .id(item.id)
        }
      }
      .animation(animation, value: container.currentToast?.id)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @State private var dragOffset: CGFloat = 0

  private var animation: Animation {
    reduceMotion ? .linear(duration: 0) : theme.animation.smooth
  }

  private var toastTransition: AnyTransition {
    switch position {
    case .top:
      .asymmetric(
        insertion: .move(edge: .top).combined(with: .opacity),
        removal: .move(edge: .top).combined(with: .opacity),
      )

    case .bottom:
      .asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .move(edge: .bottom).combined(with: .opacity),
      )
    }
  }

  private var overlayAlignment: Alignment {
    switch position {
    case .top(let alignment):
      Alignment(horizontal: alignment, vertical: .top)
    case .bottom(let alignment):
      Alignment(horizontal: alignment, vertical: .bottom)
    }
  }

  private var edgePadding: EdgeInsets {
    switch position {
    case .top:
      EdgeInsets(top: theme.spacing.lg, leading: 0, bottom: 0, trailing: 0)
    case .bottom:
      EdgeInsets(top: 0, leading: 0, bottom: theme.spacing.lg, trailing: 0)
    }
  }

  private var swipeDismissGesture: some Gesture {
    DragGesture()
      .onChanged { value in
        switch position {
        case .top:
          dragOffset = min(0, value.translation.height)
        case .bottom:
          dragOffset = max(0, value.translation.height)
        }
      }
      .onEnded { value in
        let threshold: CGFloat = 50
        let shouldDismiss: Bool =
          switch position {
          case .top:
            value.translation.height < -threshold
          case .bottom:
            value.translation.height > threshold
          }

        if shouldDismiss {
          container.dismiss()
        }
        withAnimation(animation) {
          dragOffset = 0
        }
      }
  }
}

// MARK: - IronToastItemView

/// Internal view that renders an IronToastItem from the container.
private struct IronToastItemView: View {

  // MARK: Internal

  let item: IronToastItem
  let showsProgress: Bool
  let onDismiss: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      toastView

      if showsProgress {
        progressView
      }
    }
    .offset(y: dragOffset)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  @State private var progress: Double = 0
  @State private var dragOffset: CGFloat = 0

  private var toastView: some View {
    var toast = IronToast(
      item.message,
      variant: item.variant,
      action: item.action,
    )
    toast.showsDismissButton = true
    toast.onDismiss = onDismiss
    return toast
  }

  private var progressView: some View {
    GeometryReader { geo in
      Rectangle()
        .fill(progressColor)
        .frame(width: geo.size.width * (1 - progress))
    }
    .frame(height: 3)
    .clipShape(
      UnevenRoundedRectangle(
        bottomLeadingRadius: theme.radii.md,
        bottomTrailingRadius: theme.radii.md,
      )
    )
    .onAppear {
      withAnimation(.linear(duration: item.duration)) {
        progress = 1.0
      }
    }
  }

  private var progressColor: Color {
    switch item.variant {
    case .info: theme.colors.info
    case .success: theme.colors.success
    case .warning: theme.colors.warning
    case .error: theme.colors.error
    }
  }
}

// MARK: - IronToastItem

/// Internal model representing a queued toast.
///
/// - Note: This type is `@unchecked Sendable` because `LocalizedStringKey`
///   does not conform to `Sendable`, but is effectively immutable and safe to share.
struct IronToastItem: Identifiable, @unchecked Sendable {

  // MARK: Lifecycle

  init(
    id: UUID = UUID(),
    message: LocalizedStringKey,
    title: LocalizedStringKey? = nil,
    variant: IronToastVariant = .info,
    action: IronToastAction? = nil,
    duration: TimeInterval = 3.0,
  ) {
    self.id = id
    self.message = message
    self.title = title
    self.variant = variant
    self.action = action
    self.duration = duration
  }

  // MARK: Internal

  let id: UUID
  let message: LocalizedStringKey
  let title: LocalizedStringKey?
  let variant: IronToastVariant
  let action: IronToastAction?
  let duration: TimeInterval
}

// MARK: - IronToastContainer

/// Manages a queue of toast notifications.
///
/// Use `IronToastContainer` to coordinate multiple toasts, ensuring
/// they display sequentially rather than overlapping.
///
/// ## Usage
///
/// ```swift
/// @State private var toastContainer = IronToastContainer()
///
/// var body: some View {
///     ContentView()
///         .ironToastContainer(toastContainer, position: .bottom)
/// }
///
/// func showSuccess() {
///     toastContainer.show("Saved!", variant: .success)
/// }
/// ```
@Observable
@MainActor
public final class IronToastContainer {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  /// Whether a toast is currently visible.
  public var isShowingToast: Bool {
    currentToast != nil
  }

  /// Shows a toast with a message.
  ///
  /// - Parameters:
  ///   - message: The toast message.
  ///   - variant: The semantic variant.
  ///   - duration: How long to display the toast (default: 3 seconds).
  ///   - action: An optional action button.
  public func show(
    _ message: LocalizedStringKey,
    variant: IronToastVariant = .info,
    duration: TimeInterval = 3.0,
    action: IronToastAction? = nil,
  ) {
    let item = IronToastItem(
      message: message,
      variant: variant,
      action: action,
      duration: duration,
    )
    enqueue(item)
  }

  /// Shows a toast with a message from a string.
  ///
  /// - Parameters:
  ///   - message: The toast message string.
  ///   - variant: The semantic variant.
  ///   - duration: How long to display the toast (default: 3 seconds).
  ///   - action: An optional action button.
  public func show(
    _ message: some StringProtocol,
    variant: IronToastVariant = .info,
    duration: TimeInterval = 3.0,
    action: IronToastAction? = nil,
  ) {
    show(
      LocalizedStringKey(String(message)),
      variant: variant,
      duration: duration,
      action: action,
    )
  }

  /// Shows a toast with title and message.
  ///
  /// - Parameters:
  ///   - title: The toast title.
  ///   - message: The toast message.
  ///   - variant: The semantic variant.
  ///   - duration: How long to display the toast (default: 3 seconds).
  ///   - action: An optional action button.
  public func show(
    _ title: LocalizedStringKey,
    message: LocalizedStringKey,
    variant: IronToastVariant = .info,
    duration: TimeInterval = 3.0,
    action: IronToastAction? = nil,
  ) {
    let item = IronToastItem(
      message: message,
      title: title,
      variant: variant,
      action: action,
      duration: duration,
    )
    enqueue(item)
  }

  /// Dismisses the current toast immediately.
  public func dismiss() {
    dismissCurrent()
  }

  /// Clears all queued toasts.
  public func clearAll() {
    queue.removeAll()
    dismissCurrent()
  }

  // MARK: Internal

  /// The currently displayed toast, if any.
  private(set) var currentToast: IronToastItem?

  // MARK: Private

  private var queue = [IronToastItem]()
  private var dismissTask: Task<Void, Never>?

  private func enqueue(_ item: IronToastItem) {
    queue.append(item)
    if currentToast == nil {
      showNext()
    }
    IronLogger.ui.debug(
      "IronToast enqueued",
      metadata: [
        "variant": .string("\(item.variant)"),
        "queueSize": .int(queue.count + (currentToast == nil ? 0 : 1)),
      ],
    )
  }

  private func showNext() {
    guard !queue.isEmpty else {
      currentToast = nil
      return
    }

    let next = queue.removeFirst()
    currentToast = next

    // Schedule auto-dismiss
    dismissTask?.cancel()
    dismissTask = Task { @MainActor in
      try? await Task.sleep(for: .seconds(next.duration))
      if !Task.isCancelled {
        dismissCurrent()
      }
    }

    IronLogger.ui.debug(
      "IronToast showing",
      metadata: [
        "variant": .string("\(next.variant)"),
        "duration": .double(next.duration),
      ],
    )
  }

  private func dismissCurrent() {
    dismissTask?.cancel()
    currentToast = nil

    // Small delay before showing next to allow exit animation
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(200))
      showNext()
    }
  }
}

// MARK: - View Extension

extension View {
  /// Presents an `IronToast` when a binding is true.
  ///
  /// The toast auto-dismisses after the specified duration. Users can
  /// also swipe to dismiss manually.
  ///
  /// ```swift
  /// @State private var showToast = false
  ///
  /// Button("Save") { showToast = true }
  ///     .ironToast(isPresented: $showToast) {
  ///         IronToast("Saved!", variant: .success)
  ///     }
  /// ```
  ///
  /// - Parameters:
  ///   - isPresented: Binding controlling toast visibility.
  ///   - position: Where to display the toast (default: `.bottom`).
  ///   - duration: How long to display before auto-dismiss (default: 3 seconds).
  ///   - content: The toast content builder.
  /// - Returns: A view with toast presentation capability.
  public func ironToast(
    isPresented: Binding<Bool>,
    position: IronToastPosition = .bottom,
    duration: TimeInterval = 3.0,
    @ViewBuilder content: @escaping () -> some View,
  ) -> some View {
    modifier(
      IronToastModifier(
        isPresented: isPresented,
        position: position,
        duration: duration,
        content: content,
      )
    )
  }

  /// Presents toasts from an `IronToastContainer`.
  ///
  /// Use this for queue-managed toasts where multiple notifications
  /// may need to be shown sequentially.
  ///
  /// ```swift
  /// @State private var toasts = IronToastContainer()
  ///
  /// ContentView()
  ///     .ironToastContainer(toasts, position: .bottom)
  ///
  /// func save() {
  ///     toasts.show("Saved!", variant: .success)
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - container: The toast container managing the queue.
  ///   - position: Where to display toasts (default: `.bottom`).
  ///   - showsProgress: Whether to show a progress bar for auto-dismiss countdown.
  /// - Returns: A view with toast presentation capability.
  public func ironToastContainer(
    _ container: IronToastContainer,
    position: IronToastPosition = .bottom,
    showsProgress: Bool = false,
  ) -> some View {
    modifier(
      IronToastContainerModifier(
        container: container,
        position: position,
        showsProgress: showsProgress,
      )
    )
  }
}

// MARK: - Previews

#Preview("ironToast Modifier - Basic") {
  @Previewable @State var showToast = false

  VStack(spacing: 20) {
    Text("Tap the button to show a toast")
      .foregroundStyle(.secondary)

    Button("Show Toast") {
      showToast = true
    }
    .buttonStyle(.borderedProminent)
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .ironToast(isPresented: $showToast) {
    IronToast("Item saved successfully", variant: .success)
  }
}

#Preview("ironToast Modifier - Top Position") {
  @Previewable @State var showToast = false

  VStack(spacing: 20) {
    Spacer()

    Text("Toast appears at the top")
      .foregroundStyle(.secondary)

    Button("Show Toast") {
      showToast = true
    }
    .buttonStyle(.borderedProminent)

    Spacer()
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .ironToast(isPresented: $showToast, position: .top) {
    IronToast("New notification received", variant: .info)
  }
}

#Preview("ironToastContainer - Queue Demo") {
  @Previewable @State var toasts = IronToastContainer()

  VStack(spacing: 20) {
    Text("Toasts appear sequentially")
      .foregroundStyle(.secondary)

    HStack(spacing: 12) {
      Button("Info") {
        toasts.show("Information toast", variant: .info)
      }
      Button("Success") {
        toasts.show("Success toast", variant: .success)
      }
      Button("Warning") {
        toasts.show("Warning toast", variant: .warning)
      }
      Button("Error") {
        toasts.show("Error toast", variant: .error)
      }
    }
    .buttonStyle(.bordered)

    Button("Add 3 Toasts") {
      toasts.show("First toast", variant: .info)
      toasts.show("Second toast", variant: .success)
      toasts.show("Third toast", variant: .warning)
    }
    .buttonStyle(.borderedProminent)
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .ironToastContainer(toasts, showsProgress: true)
}
