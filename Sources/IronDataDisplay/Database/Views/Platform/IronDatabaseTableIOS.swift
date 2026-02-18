#if os(iOS)
import IronCore
import IronPrimitives
import ListKit // @MainActor-safe async diffable data source wrappers (replaces UIKit's NSDiffableDataSourceSnapshot / UICollectionViewDiffableDataSource)
import SwiftUI
import UIKit

// MARK: - IronDatabaseCellItem

/// Type-safe item identifier for collection view cells.
///
/// This replaces string-based identifiers with a proper model type,
/// enabling modern `CellRegistration` patterns.
///
/// The layout uses rows as sections, with each item representing a cell
/// at a specific column within that row. The `rowID` ensures diffable
/// data source detects changes when row order changes due to sorting.
struct IronDatabaseCellItem: Hashable, Sendable {
  /// The column index (0 = selection column if shown, then data columns).
  let columnIndex: Int
  /// The display row index (section index in the layout).
  let rowIndex: Int
  /// The actual row UUID for identity tracking.
  let rowID: UUID
}

// MARK: - IronDatabaseTableIOS

/// iOS implementation of `IronDatabaseTable` using `UICollectionView`.
///
/// This view uses a compositional layout with sticky headers for optimal
/// performance with large datasets while maintaining IronUI theming.
struct IronDatabaseTableIOS: UIViewRepresentable {

  // MARK: Lifecycle

  init(configuration: IronDatabaseTableConfiguration) {
    self.configuration = configuration
  }

  // MARK: Internal

  @Environment(\.ironTheme) var theme

  let configuration: IronDatabaseTableConfiguration

  func makeUIView(context: Context) -> IronDatabaseTableContainerView {
    // Pass theme's divider color for selection column background (subtle gray)
    let selectionColumnBackgroundColor = UIColor(theme.colors.divider)
    let containerView = IronDatabaseTableContainerView(
      configuration: configuration,
      selectionColumnBackgroundColor: selectionColumnBackgroundColor,
    )
    containerView.coordinator = context.coordinator
    context.coordinator.containerView = containerView

    // Initial data load after coordinator is connected
    context.coordinator.recomputeDisplayIndices()
    containerView.reloadData()

    return containerView
  }

  func updateUIView(_ containerView: IronDatabaseTableContainerView, context: Context) {
    let coordinator = context.coordinator

    // Track previous editing state before updating configuration
    let wasEditing = coordinator.configuration.isEditing

    // Update coordinator's configuration (updates bindings to selection/sort/filter)
    coordinator.configuration = configuration

    // Check for structural changes using count-based tracking
    // (array equality doesn't work with @Observable since it's the same object)
    let needsLayoutRebuild = coordinator.columnsChanged
    let needsDataReload = coordinator.rowsOrOrderChanged

    if needsLayoutRebuild {
      containerView.rebuildLayout()
    }

    if needsDataReload {
      coordinator.recomputeDisplayIndices()
      containerView.reloadData()
    }

    // Sync edit mode state
    if configuration.isEditing != wasEditing {
      containerView.setEditing(configuration.isEditing, animated: true)
    }

    // Update tracked state for next comparison
    coordinator.snapshotCurrentState()
  }

  func makeCoordinator() -> IronDatabaseIOSCoordinator {
    IronDatabaseIOSCoordinator(configuration: configuration)
  }
}

// MARK: - IronDatabaseIOSCoordinator

/// Coordinator for the iOS collection view.
@MainActor
final class IronDatabaseIOSCoordinator: IronDatabaseTableCoordinatorBase {

  // MARK: Internal

  weak var containerView: IronDatabaseTableContainerView?

  /// Tracks the state of column resize operations.
  let resizeState = IronColumnResizeState()

  /// Calculates the width for a column using `fitHeader` mode.
  ///
  /// This measures the actual header content: type icon + text + indicators + padding.
  /// The calculation matches the layout in `IronDatabaseHeaderCellContent.headerLabelContent`.
  ///
  /// - Parameter column: The column to calculate width for.
  /// - Returns: The calculated width based on header content.
  func calculateFitHeaderWidth(for column: IronColumn) -> CGFloat {
    // Measure column name with subheadline font (matches header text style)
    let textFont = UIFont.preferredFont(forTextStyle: .subheadline)
    let textAttributes: [NSAttributedString.Key: Any] = [.font: textFont]
    let textSize = (column.name as NSString).size(withAttributes: textAttributes)

    // Measure column type icon with caption font
    let captionFont = UIFont.preferredFont(forTextStyle: .caption1)
    let iconWidth = captionFont.pointSize // SF Symbols are roughly square

    // Get extra padding from the width mode, or use default
    let extraPadding: CGFloat =
      if case .fitHeader(let customPadding) = column.widthMode {
        customPadding
      } else {
        0
      }

    // Calculate total width per layout spec:
    // Resizable: | -(12)- [Icon] -(4)- [Title] -(8)- [GrabBar ~9pt] -(12)- |
    // Don't reserve space for sort/filter indicators - they fit in the gap or text truncates
    // This matches Notion's behavior where columns fit the name, not all possible states
    let leadingPadding: CGFloat = 12
    let trailingPadding: CGFloat = 29 // 8pt gap + ~9pt dots + 12pt to separator
    let hstackSpacing: CGFloat = 4

    return leadingPadding
      + iconWidth // Type icon
      + hstackSpacing // After icon
      + ceil(textSize.width) // Text
      + trailingPadding
      + extraPadding
  }

  /// Finds the column at a resize boundary for the given location.
  ///
  /// - Parameters:
  ///   - location: The point in the header scroll view's coordinate space (content coordinates).
  ///   - scrollView: The scroll view (unused, kept for API compatibility).
  /// - Returns: The column ID and current width if the location is on a resize boundary, nil otherwise.
  func columnAtResizeBoundary(location: CGPoint, in _: UIScrollView?) -> (columnID: UUID, width: CGFloat)? {
    // Only detect boundaries in the header area
    // Note: For UIScrollView, gesture.location(in: scrollView) returns coordinates in the
    // scroll view's bounds system, where bounds.origin = contentOffset. So the location
    // is already in content coordinates - no need to add scroll offset.
    guard location.y >= 0, location.y <= configuration.headerHeight else { return nil }

    // Location is already in content coordinates (bounds.origin = contentOffset for scroll views)
    let contentX = location.x

    // Use containerView's effectiveColumnWidth for consistency with layout
    guard let containerView else { return nil }

    var accumulatedX: CGFloat = 0

    // Account for selection column
    if configuration.showsSelectionColumn {
      accumulatedX += configuration.selectionColumnWidth
    }

    // Read columns from database and use container's width calculation
    // This ensures boundaries match the visual layout positions
    for column in configuration.database.columns {
      let columnWidth = containerView.effectiveColumnWidth(for: column)
      accumulatedX += columnWidth

      // Skip non-resizable columns for boundary detection
      // Check both the explicit isResizable flag AND widthMode (fixed columns can't be resized)
      guard column.isResizable, column.widthMode.allowsUserResizing else {
        continue
      }

      // Detection zone matches the grip position: inside the cell, 44pt from the boundary
      // The grip is at .trailing alignment with 44pt width, so it spans from
      // (boundary - 44) to boundary. Detect touches in this same range.
      let distanceFromBoundary = accumulatedX - contentX
      if distanceFromBoundary >= 0, distanceFromBoundary <= resizeHandleWidth {
        return (column.id, columnWidth)
      }
    }

    return nil
  }

  func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    // In the row-based layout:
    // - indexPath.section = row index
    // - indexPath.item = column index within the row
    // Note: Body no longer contains selection column (it's in a separate view)
    let rowIndex = indexPath.section
    let columnIndex = indexPath.item

    guard let row = row(at: rowIndex) else {
      IronLogger.ui.warning(
        "Cell selection: row not found at index",
        metadata: ["rowIndex": .int(rowIndex)],
      )
      return
    }
    guard columnIndex >= 0, columnIndex < configuration.database.columns.count else {
      IronLogger.ui.warning(
        "Cell selection: column index out of bounds",
        metadata: ["columnIndex": .int(columnIndex), "columnCount": .int(configuration.database.columns.count)],
      )
      return
    }

    let column = configuration.database.columns[columnIndex]
    if column.type != .checkbox {
      // Use setEditingCell to reconfigure both old and new cells
      containerView?.setEditingCell(CellIdentifier(rowID: row.id, columnID: column.id), in: self)
    }
  }

  /// Handles the pan gesture for column resizing.
  @objc
  func handleResizeGesture(_ gesture: UIPanGestureRecognizer) {
    // Get the scroll view directly from the gesture's view
    guard let scrollView = gesture.view as? UIScrollView else {
      IronLogger.ui.warning("Resize gesture: gesture view is not a UIScrollView")
      return
    }

    let location = gesture.location(in: scrollView)

    switch gesture.state {
    case .began:
      // Find if we're on a column boundary
      if let (columnID, originalWidth) = columnAtResizeBoundary(location: location, in: scrollView) {
        // Store visible coordinates - translation is finger movement in screen space
        resizeState.beginResize(columnID: columnID, startX: location.x, originalWidth: originalWidth)
        IronHaptics.impact(.medium)
      }

    case .changed:
      // Not in resize mode - expected when gesture starts outside resize boundary
      guard resizeState.isResizing else { return }

      guard let columnID = resizeState.resizingColumnID else {
        IronLogger.ui.warning("Resize gesture changed: no column ID in active resize state")
        return
      }
      guard let columnIndex = configuration.database.columns.firstIndex(where: { $0.id == columnID }) else {
        IronLogger.ui.warning(
          "Resize gesture changed: column no longer exists",
          metadata: ["columnID": .string(columnID.uuidString)],
        )
        resizeState.endResize()
        return
      }

      let column = configuration.database.columns[columnIndex]
      // Use visible coordinates - measures how far finger moved in screen space
      let translation = location.x - resizeState.dragStartX
      let constraints = (min: column.widthMode.minimumWidth, max: column.widthMode.maximumWidth)
      let newWidth = resizeState.newWidth(for: translation, constraints: constraints)

      // Throttle layout updates for performance on large tables
      // Only rebuild if width changed by more than 2pt since last update
      let currentWidth = column.width ?? column.resolvedWidth
      guard abs(newWidth - currentWidth) >= 2 else { return }

      // Update column width in the binding
      configuration.database.columns[columnIndex].width = newWidth

      // Invalidate layout for live feedback (containerView reads from coordinator)
      containerView?.invalidateLayoutForResize()

    case .ended, .cancelled:
      if resizeState.isResizing {
        IronHaptics.impact(.light)

        // Announce resize completion for accessibility
        if
          let columnID = resizeState.resizingColumnID,
          let column = configuration.database.columns.first(where: { $0.id == columnID })
        {
          let newWidth = column.width ?? column.resolvedWidth
          UIAccessibility.post(
            notification: .announcement,
            argument: String(localized: "\(column.name) resized to \(Int(newWidth)) points"),
          )
        }
      }
      resizeState.endResize()

    default:
      break
    }
  }

  // MARK: Private

  /// Width of the resize handle touch target (matches the grip view's frame).
  private let resizeHandleWidth: CGFloat = 44

}

// MARK: - IronDatabaseIOSCoordinator + UIGestureRecognizerDelegate

extension IronDatabaseIOSCoordinator: UIGestureRecognizerDelegate {

  nonisolated func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else { return true }

    // This is called from the gesture recognizer's thread, need to dispatch to main
    return MainActor.assumeIsolated {
      // Get the scroll view directly from the gesture's view
      guard let scrollView = panGesture.view as? UIScrollView else { return false }
      let location = panGesture.location(in: scrollView)

      // Only begin if on a resize boundary
      return columnAtResizeBoundary(location: location, in: scrollView) != nil
    }
  }

  nonisolated func gestureRecognizer(
    _: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer,
  ) -> Bool {
    // Don't interfere with scroll gestures unless actively resizing
    MainActor.assumeIsolated {
      !resizeState.isResizing
    }
  }

  nonisolated func gestureRecognizer(
    _: UIGestureRecognizer,
    shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer,
  ) -> Bool {
    // Require navigation back gestures (UIScreenEdgePanGestureRecognizer) to wait for
    // our resize gesture to fail first. This prevents accidental navigation when
    // dragging to enlarge columns. Our gestureRecognizerShouldBegin already ensures
    // we only begin when on a resize boundary, so this won't interfere with normal navigation.
    otherGestureRecognizer is UIScreenEdgePanGestureRecognizer
  }
}

#endif
