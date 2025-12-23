// IronDataDisplay - Data display components
// Contains: Timeline, Kanban, Database

@_exported import IronComponents
@_exported import IronCore
@_exported import IronPrimitives

/// The IronDataDisplay module provides data visualization components.
///
/// Includes:
/// - ``IronTimeline`` - Vertical event timeline with entries
/// - ``IronKanban`` - Project management board with draggable cards
/// - ``IronDatabase`` - Notion-style runtime-configurable database
/// - ``IronDatabaseTable`` - Table view for database content
public enum IronDataDisplay {
  /// The current version of IronDataDisplay.
  public static let version = "0.1.0"
}
