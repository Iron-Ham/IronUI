import SwiftUI

// MARK: - IronAccordionExpandBehavior

/// Defines how accordions in a group expand and collapse.
public enum IronAccordionExpandBehavior: Sendable, CaseIterable {
  /// Multiple accordions can be open simultaneously.
  case independent
  /// Only one accordion can be open at a time (classic accordion pattern).
  case exclusive
}

// MARK: - IronAccordionCoordinator

/// Coordinates expand/collapse behavior for accordion groups.
///
/// This coordinator manages the expanded state of accordions within an
/// ``IronAccordionGroup``, enabling exclusive expand behavior where only
/// one accordion can be open at a time.
@MainActor
@Observable
public final class IronAccordionCoordinator: Sendable {

  // MARK: Lifecycle

  /// Creates a new accordion coordinator.
  ///
  /// - Parameter expandBehavior: The expand behavior for the group.
  public init(expandBehavior: IronAccordionExpandBehavior = .independent) {
    self.expandBehavior = expandBehavior
  }

  // MARK: Public

  /// The expand behavior for accordions in this group.
  public var expandBehavior: IronAccordionExpandBehavior

  /// The set of currently expanded accordion IDs.
  public private(set) var expandedIDs: Set<String> = []

  /// Toggles the expansion state of an accordion.
  ///
  /// - Parameter id: The unique identifier of the accordion.
  public func toggleExpansion(for id: String) {
    if expandBehavior == .exclusive {
      if expandedIDs.contains(id) {
        expandedIDs.remove(id)
      } else {
        expandedIDs = [id]
      }
    } else {
      if expandedIDs.contains(id) {
        expandedIDs.remove(id)
      } else {
        expandedIDs.insert(id)
      }
    }
  }

  /// Checks if an accordion is currently expanded.
  ///
  /// - Parameter id: The unique identifier of the accordion.
  /// - Returns: `true` if the accordion is expanded.
  public func isExpanded(_ id: String) -> Bool {
    expandedIDs.contains(id)
  }

  /// Sets the expansion state of an accordion.
  ///
  /// - Parameters:
  ///   - id: The unique identifier of the accordion.
  ///   - expanded: Whether the accordion should be expanded.
  public func setExpanded(_ id: String, expanded: Bool) {
    if expanded {
      if expandBehavior == .exclusive {
        expandedIDs = [id]
      } else {
        expandedIDs.insert(id)
      }
    } else {
      expandedIDs.remove(id)
    }
  }
}

// MARK: - Environment Keys

extension EnvironmentValues {
  /// The coordinator for accordion group behavior.
  ///
  /// When an accordion is inside an ``IronAccordionGroup``, this coordinator
  /// manages the expand/collapse state across all accordions in the group.
  @Entry public var ironAccordionCoordinator: IronAccordionCoordinator? = nil

  /// Whether the accordion is inside a group.
  ///
  /// When `true`, the accordion uses the coordinator for state management
  /// instead of its own local state.
  @Entry public var ironAccordionInGroup: Bool = false

  /// The nesting depth for nested accordions.
  ///
  /// Used to calculate indentation for nested accordion content.
  @Entry public var ironAccordionDepth: Int = 0
}
