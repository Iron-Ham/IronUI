import IronCore
import SwiftUI

// MARK: - IronTrayModifier

/// A view modifier that presents an `IronTray` overlay.
struct IronTrayModifier<TrayContent: View, TrayHeader: View>: ViewModifier {

  // MARK: Lifecycle

  init(
    isPresented: Binding<Bool>,
    detents: Set<IronTrayDetent>,
    selectedDetent: Binding<IronTrayDetent>?,
    showsDragIndicator: Bool,
    onDismiss: (() -> Void)?,
    @ViewBuilder content: () -> TrayContent,
    @ViewBuilder header: () -> TrayHeader,
  ) {
    _isPresented = isPresented
    self.detents = detents
    _selectedDetent = selectedDetent ?? .constant(.medium)
    self.showsDragIndicator = showsDragIndicator
    self.onDismiss = onDismiss
    trayContent = content()
    trayHeader = header()
  }

  // MARK: Internal

  func body(content: Content) -> some View {
    content
      .overlay {
        if isPresented {
          IronTray(
            detents: detents,
            selectedDetent: $selectedDetent,
            showsDragIndicator: showsDragIndicator,
          ) {
            trayContent
          } header: {
            trayHeader
          }
          .transition(.move(edge: .bottom).combined(with: .opacity))
          .onDisappear {
            if !isPresented {
              onDismiss?()
            }
          }
        }
      }
      .animation(animation, value: isPresented)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @Binding private var isPresented: Bool
  @Binding private var selectedDetent: IronTrayDetent

  private let detents: Set<IronTrayDetent>
  private let showsDragIndicator: Bool
  private let onDismiss: (() -> Void)?
  private let trayContent: TrayContent
  private let trayHeader: TrayHeader

  private var animation: Animation {
    reduceMotion ? .linear(duration: 0) : theme.animation.smooth
  }
}

// MARK: - View Extension

extension View {
  /// Presents an `IronTray` when a binding is true.
  ///
  /// ```swift
  /// @State private var showSettings = false
  ///
  /// ContentView()
  ///   .ironTray(isPresented: $showSettings) {
  ///     SettingsContent()
  ///   }
  /// ```
  ///
  /// - Parameters:
  ///   - isPresented: Binding controlling tray visibility.
  ///   - detents: Available height detents. Defaults to `[.medium]`.
  ///   - selectedDetent: Optional binding to track/control current detent.
  ///   - showsDragIndicator: Whether to show the drag handle. Defaults to `true`.
  ///   - onDismiss: Called when the tray is dismissed.
  ///   - content: The tray content builder.
  /// - Returns: A view with tray presentation capability.
  public func ironTray(
    isPresented: Binding<Bool>,
    detents: Set<IronTrayDetent> = [.medium],
    selectedDetent: Binding<IronTrayDetent>? = nil,
    showsDragIndicator: Bool = true,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: () -> some View,
  ) -> some View {
    modifier(
      IronTrayModifier(
        isPresented: isPresented,
        detents: detents,
        selectedDetent: selectedDetent,
        showsDragIndicator: showsDragIndicator,
        onDismiss: onDismiss,
        content: content,
        header: { EmptyView() },
      )
    )
  }

  /// Presents an `IronTray` with a custom header when a binding is true.
  ///
  /// ```swift
  /// @State private var showSettings = false
  ///
  /// ContentView()
  ///   .ironTray(isPresented: $showSettings) {
  ///     SettingsContent()
  ///   } header: {
  ///     IronTrayHeader(title: "Settings") {
  ///       showSettings = false
  ///     }
  ///   }
  /// ```
  ///
  /// - Parameters:
  ///   - isPresented: Binding controlling tray visibility.
  ///   - detents: Available height detents. Defaults to `[.medium]`.
  ///   - selectedDetent: Optional binding to track/control current detent.
  ///   - showsDragIndicator: Whether to show the drag handle. Defaults to `true`.
  ///   - onDismiss: Called when the tray is dismissed.
  ///   - content: The tray content builder.
  ///   - header: The tray header builder.
  /// - Returns: A view with tray presentation capability.
  public func ironTray(
    isPresented: Binding<Bool>,
    detents: Set<IronTrayDetent> = [.medium],
    selectedDetent: Binding<IronTrayDetent>? = nil,
    showsDragIndicator: Bool = true,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: () -> some View,
    @ViewBuilder header: () -> some View,
  ) -> some View {
    modifier(
      IronTrayModifier(
        isPresented: isPresented,
        detents: detents,
        selectedDetent: selectedDetent,
        showsDragIndicator: showsDragIndicator,
        onDismiss: onDismiss,
        content: content,
        header: header,
      )
    )
  }
}

// MARK: - Preview

#Preview("ironTray Modifier") {
  @Previewable @State var showTray = false
  @Previewable @State var currentDetent = IronTrayDetent.medium

  NavigationStack {
    List {
      Section("Tray Demo") {
        Button("Show Tray") {
          showTray = true
        }

        Text("Current detent: \(String(describing: currentDetent))")
      }
    }
    .navigationTitle("IronTray Demo")
  }
  .ironTray(
    isPresented: $showTray,
    detents: [.small, .medium, .large],
    selectedDetent: $currentDetent,
  ) {
    VStack(spacing: 16) {
      Text("Hello from Tray!")
        .font(.headline)

      Text("Drag up or down to change detents")
        .foregroundStyle(.secondary)

      Button("Dismiss") {
        showTray = false
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
  } header: {
    IronTrayHeader(title: "Demo Tray") {
      showTray = false
    }
  }
}
