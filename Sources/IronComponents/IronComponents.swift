// IronComponents - Composed UI components
// Contains: Avatar, Chip, Skeleton, SegmentedControl, Menu, etc.

@_exported import IronCore
@_exported import IronPrimitives

/// The IronComponents module provides composed UI components.
///
/// These are molecule-level components built from primitives:
/// - ``IronAvatar`` - User profile images with fallback initials
/// - ``IronChip`` - Tags, filters, and selections
/// - ``IronSkeleton`` - Loading placeholders with shimmer
/// - ``IronSegmentedControl`` - Horizontal segment picker
/// - ``IronMenu`` - Dropdown menus and context menus
///
/// ## Overview
///
/// IronComponents builds on IronPrimitives to provide higher-level,
/// composed components that are commonly used in applications.
///
/// ```swift
/// // Avatar with status
/// IronAvatar(name: "John Doe", status: .online)
///
/// // Selectable chips
/// IronChip("Filter", isSelected: $isSelected)
///
/// // Loading skeleton
/// IronSkeletonCard()
///
/// // Segmented control
/// IronSegmentedControl(selection: $tab, options: tabs)
/// ```
public enum IronComponents {
  /// The current version of IronComponents.
  public static let version = "0.1.0"
}
