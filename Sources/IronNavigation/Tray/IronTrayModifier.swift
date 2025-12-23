import IronCore
import SwiftUI

// MARK: - IronTrayModifier

/// A view modifier that presents an `IronTray` overlay.
struct IronTrayModifier<TrayContent: View>: ViewModifier {

  // MARK: Lifecycle

  init(
    isPresented: Binding<Bool>,
    showsDragIndicator: Bool,
    onDismiss: (() -> Void)?,
    @ViewBuilder content: () -> TrayContent
  ) {
    _isPresented = isPresented
    self.showsDragIndicator = showsDragIndicator
    self.onDismiss = onDismiss
    trayContent = content()
  }

  // MARK: Internal

  func body(content: Content) -> some View {
    content
      .overlay {
        if isPresented {
          IronTray(
            showsDragIndicator: showsDragIndicator,
            onDismiss: {
              isPresented = false
              onDismiss?()
            }
          ) {
            trayContent
          }
          .transition(.opacity)
        }
      }
      .animation(animation, value: isPresented)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @Binding private var isPresented: Bool

  private let showsDragIndicator: Bool
  private let onDismiss: (() -> Void)?
  private let trayContent: TrayContent

  private var animation: Animation {
    reduceMotion ? .linear(duration: 0) : theme.animation.smooth
  }
}

// MARK: - View Extension

extension View {
  /// Presents a content-sized `IronTray` when a binding is true.
  ///
  /// The tray automatically sizes to fit its content, with height
  /// changes animating smoothly to signal progression.
  ///
  /// ```swift
  /// @State private var showSettings = false
  ///
  /// ContentView()
  ///   .ironTray(isPresented: $showSettings) {
  ///     VStack {
  ///       IronTrayHeader("Settings", onDismiss: { showSettings = false })
  ///       SettingsContent()
  ///     }
  ///   }
  /// ```
  ///
  /// - Parameters:
  ///   - isPresented: Binding controlling tray visibility.
  ///   - showsDragIndicator: Whether to show the drag handle. Defaults to `true`.
  ///   - onDismiss: Called when the tray is dismissed.
  ///   - content: The tray content builder.
  /// - Returns: A view with tray presentation capability.
  public func ironTray(
    isPresented: Binding<Bool>,
    showsDragIndicator: Bool = true,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: () -> some View
  ) -> some View {
    modifier(
      IronTrayModifier(
        isPresented: isPresented,
        showsDragIndicator: showsDragIndicator,
        onDismiss: onDismiss,
        content: content
      )
    )
  }
}

// MARK: - Preview

#Preview("ironTray Modifier") {
  @Previewable @State var showTray = false

  NavigationStack {
    List {
      Section("Tray Demo") {
        Button("Show Tray") {
          showTray = true
        }
      }
    }
    .navigationTitle("IronTray Demo")
  }
  .ironTray(isPresented: $showTray) {
    VStack(spacing: 16) {
      IronTrayHeader("Hello!", onDismiss: { showTray = false })

      Text("This tray sizes to fit its content.")
        .foregroundStyle(.secondary)
        .padding(.horizontal)

      Button("Dismiss") {
        showTray = false
      }
      .buttonStyle(.borderedProminent)
      .padding(.bottom)
    }
  }
}
