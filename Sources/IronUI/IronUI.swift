// IronUI - Umbrella module re-exporting all IronUI modules

@_exported import IronComponents
@_exported import IronCore
@_exported import IronDataDisplay
@_exported import IronForms
@_exported import IronKitBridge
@_exported import IronLayouts
@_exported import IronNavigation
@_exported import IronPrimitives

/// IronUI is a comprehensive SwiftUI component library.
///
/// Import this umbrella module to access all IronUI components, or import
/// individual modules for more granular control:
///
/// ```swift
/// // Import everything
/// import IronUI
///
/// // Or import specific modules
/// import IronCore
/// import IronPrimitives
/// ```
///
/// ## Topics
///
/// ### Foundation
/// - ``IronCore``
///
/// ### Components
/// - ``IronPrimitives``
/// - ``IronComponents``
/// - ``IronLayouts``
///
/// ### Specialized
/// - ``IronNavigation``
/// - ``IronForms``
/// - ``IronDataDisplay``
/// - ``IronKitBridge``
public enum IronUI {
  /// The current version of IronUI.
  public static let version = "0.1.0"
}
