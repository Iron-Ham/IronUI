import Foundation

// MARK: - IronColumnResizeState

/// Tracks the state of a column resize operation in `IronDatabaseTable`.
///
/// This class manages the transient state during a drag-to-resize gesture,
/// including the column being resized, the original width, and the drag origin.
///
/// ## Usage
///
/// ```swift
/// let resizeState = IronColumnResizeState()
///
/// // When drag begins
/// resizeState.beginResize(columnID: column.id, startX: location.x, originalWidth: 150)
///
/// // During drag
/// let newWidth = resizeState.newWidth(for: translation, constraints: (min: 40, max: nil))
///
/// // When drag ends
/// resizeState.endResize()
/// ```
@MainActor
public final class IronColumnResizeState: ObservableObject {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  /// The ID of the column currently being resized, or nil if no resize is active.
  @Published public private(set) var resizingColumnID: UUID?

  /// The X coordinate where the drag gesture started.
  @Published public private(set) var dragStartX: CGFloat = 0

  /// The width of the column before the resize operation began.
  @Published public private(set) var originalWidth: CGFloat = 0

  /// Whether a resize operation is currently active.
  public var isResizing: Bool {
    resizingColumnID != nil
  }

  /// Begins a resize operation for the specified column.
  ///
  /// - Parameters:
  ///   - columnID: The ID of the column being resized.
  ///   - startX: The X coordinate where the drag began.
  ///   - originalWidth: The current width of the column.
  public func beginResize(columnID: UUID, startX: CGFloat, originalWidth: CGFloat) {
    resizingColumnID = columnID
    dragStartX = startX
    self.originalWidth = originalWidth
  }

  /// Calculates the new width based on drag translation.
  ///
  /// - Parameters:
  ///   - translation: The horizontal distance dragged from the start position.
  ///   - constraints: A tuple of (minimum, maximum) width constraints.
  /// - Returns: The new width, clamped to the given constraints.
  public func newWidth(for translation: CGFloat, constraints: (min: CGFloat, max: CGFloat?)) -> CGFloat {
    let proposed = originalWidth + translation
    let clamped = max(constraints.min, proposed)
    if let maxWidth = constraints.max {
      return min(maxWidth, clamped)
    }
    return clamped
  }

  /// Ends the current resize operation and resets state.
  public func endResize() {
    resizingColumnID = nil
    dragStartX = 0
    originalWidth = 0
  }
}
