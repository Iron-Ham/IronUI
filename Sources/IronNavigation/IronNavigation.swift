// IronNavigation - Custom navigation transitions and presentation styles
// NOT replacements for UINavigationController/UISplitView

import IronComponents
import IronCore
import IronPrimitives

/// The IronNavigation module provides custom navigation transitions and presentation styles.
///
/// This module focuses on:
/// - Custom navigation transitions
/// - Presentation modifiers (IronTray, IronToast)
/// - Navigation chrome (accessories, back buttons)
/// - Hero transitions
/// - Matched geometry presentations
///
/// ## IronTray
///
/// A dynamic bottom sheet inspired by Family's tray system:
///
/// ```swift
/// @State private var showTray = false
///
/// Button("Show") { showTray = true }
///   .ironTray(isPresented: $showTray, detents: [.medium, .large]) {
///     TrayContent()
///   }
/// ```
///
/// ## IronToast
///
/// Ephemeral notification messages that auto-dismiss:
///
/// ```swift
/// @State private var showToast = false
///
/// Button("Save") { showToast = true }
///   .ironToast(isPresented: $showToast) {
///     IronToast("Saved!", variant: .success)
///   }
/// ```
///
/// For queue-managed toasts:
///
/// ```swift
/// @State private var toasts = IronToastContainer()
///
/// ContentView()
///   .ironToastContainer(toasts)
///
/// func save() {
///   toasts.show("Saved!", variant: .success)
/// }
/// ```
///
/// > Important: This module does NOT provide replacements for system navigation
/// > containers like UINavigationController or UISplitView. Use SwiftUI's native
/// > navigation APIs for those patterns.
public enum IronNavigation {
  /// The current version of IronNavigation.
  public static let version = "0.1.0"
}
