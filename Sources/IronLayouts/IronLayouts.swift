// IronLayouts - Layout components
// Contains: Flow layout, responsive stacks, container

import IronCore

/// The IronLayouts module provides layout components that SwiftUI doesn't offer natively.
///
/// ## Flow Layout
///
/// `IronFlow` arranges items in rows, wrapping to the next line when needed:
///
/// ```swift
/// IronFlow {
///   ForEach(tags, id: \.self) { tag in
///     IronChip(tag)
///   }
/// }
/// ```
///
/// ## Responsive Stacks
///
/// Stacks that adapt their layout based on available space:
///
/// ```swift
/// // Uses ViewThatFits to determine layout
/// IronAdaptiveStack {
///   Button("Cancel") { }
///   Button("Save") { }
/// }
///
/// // Threshold-based switching
/// IronResponsiveStack(threshold: 400) {
///   Label()
///   TextField()
/// }
///
/// // Size class based
/// IronSizeClassStack {
///   Sidebar()
///   Detail()
/// }
/// ```
///
/// ## Container
///
/// Constrains content width for readability on large screens:
///
/// ```swift
/// IronContainer(maxWidth: .standard) {
///   ArticleContent()
/// }
/// ```
public enum IronLayouts {
  /// The current version of IronLayouts.
  public static let version = "0.1.0"
}
