#if os(iOS)
import IronCore
import IronPrimitives
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
struct IronDatabaseCellItem: Hashable {
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

  let configuration: IronDatabaseTableConfiguration

  func makeUIView(context: Context) -> IronDatabaseTableContainerView {
    let containerView = IronDatabaseTableContainerView(configuration: configuration)
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

    guard let row = row(at: rowIndex) else { return }
    guard columnIndex >= 0, columnIndex < configuration.database.columns.count else { return }

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
    guard let scrollView = gesture.view as? UIScrollView else { return }

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
      guard
        resizeState.isResizing,
        let columnID = resizeState.resizingColumnID,
        let columnIndex = configuration.database.columns.firstIndex(where: { $0.id == columnID })
      else { return }

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
            argument: "\(column.name) resized to \(Int(newWidth)) points",
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

  /// Calculates the effective display width for a column.
  ///
  /// - Parameter column: The column to calculate width for.
  /// - Returns: The effective width, handling `fitHeader` mode.
  private func effectiveWidth(for column: IronColumn) -> CGFloat {
    if let explicitWidth = column.width {
      return explicitWidth
    }

    if case .fitHeader = column.widthMode {
      return calculateFitHeaderWidth(for: column)
    }

    return column.resolvedWidth
  }

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
}

// MARK: - IronDatabaseTableContainerView

/// Container view that holds the header and body collection views.
final class IronDatabaseTableContainerView: UIView {

  // MARK: Lifecycle

  init(configuration: IronDatabaseTableConfiguration) {
    initialConfiguration = configuration
    super.init(frame: .zero)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  /// Configuration is accessed through the coordinator when available.
  /// Falls back to initial configuration during setup before coordinator is set.
  var configuration: IronDatabaseTableConfiguration {
    coordinator?.configuration ?? initialConfiguration
  }

  /// The coordinator, which must be set after init for gesture handling.
  /// Once set, configuration reads will go through the coordinator (single source of truth).
  weak var coordinator: IronDatabaseIOSCoordinator? {
    didSet {
      guard coordinator != nil else { return }

      // Rebuild layouts now that coordinator is available for width calculations
      // (fitHeader mode needs coordinator.calculateFitHeaderWidth)
      // Note: Only rebuild layout, not data - caller will call reloadData after recomputeDisplayIndices
      bodyCollectionView.setCollectionViewLayout(createBodyLayout(), animated: false)
      headerCollectionView.setCollectionViewLayout(createHeaderLayout(), animated: false)

      // Set up resize gesture once coordinator is available
      if resizeGesture == nil {
        setupResizeGesture()
      }
    }
  }

  /// Exposes the header scroll view for resize gesture coordinate conversion.
  var headerScrollViewForResize: UIScrollView {
    headerScrollView
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    // Rebuild layout when bounds change (needed for .fill columns)
    if previousBoundsSize != bounds.size {
      previousBoundsSize = bounds.size
      invalidateLayoutForResize()
    } else {
      updateHeaderWidth()
    }
  }

  func rebuildLayout() {
    bodyCollectionView.setCollectionViewLayout(createBodyLayout(), animated: false)
    headerCollectionView.setCollectionViewLayout(createHeaderLayout(), animated: false)
    reloadData()
  }

  /// Sets the editing state to show/hide the selection column.
  ///
  /// When editing, the selection column (checkboxes) appears on the left,
  /// allowing users to select rows by tapping checkboxes.
  func setEditing(_ editing: Bool, animated: Bool) {
    if animated {
      animateSelectionColumnTransition(visible: editing)
    } else {
      rebuildLayoutWithFullReload()
    }
  }

  /// Invalidates layout during live resize for smooth real-time feedback.
  /// This is lighter-weight than `rebuildLayout()` and avoids data source reloads.
  func invalidateLayoutForResize() {
    // Preserve scroll positions before layout change
    let bodyOffset = bodyCollectionView.contentOffset
    let headerOffset = headerScrollView.contentOffset

    // Rebuild layouts with new column widths
    bodyCollectionView.setCollectionViewLayout(createBodyLayout(), animated: false)
    headerCollectionView.setCollectionViewLayout(createHeaderLayout(), animated: false)

    // Update header scroll view content width
    updateHeaderWidth()

    // Restore scroll positions (prevent UIKit from adjusting them during layout)
    bodyCollectionView.contentOffset = bodyOffset
    headerScrollView.contentOffset = headerOffset

    // Force immediate layout pass
    headerScrollView.layoutIfNeeded()
    headerCollectionView.layoutIfNeeded()
    bodyCollectionView.layoutIfNeeded()
  }

  func reloadData() {
    let rowCount = coordinator?.displayRowCount ?? 0

    // Reload body (data columns only)
    var bodySnapshot = NSDiffableDataSourceSnapshot<Int, IronDatabaseCellItem>()
    let bodyColumnCount = configuration.database.columns.count + (configuration.showsAddColumnButton ? 1 : 0)

    for rowIndex in 0..<rowCount {
      bodySnapshot.appendSections([rowIndex])

      guard let row = coordinator?.row(at: rowIndex) else { continue }

      let items = (0..<bodyColumnCount).map { columnIndex in
        IronDatabaseCellItem(columnIndex: columnIndex, rowIndex: rowIndex, rowID: row.id)
      }
      bodySnapshot.appendItems(items, toSection: rowIndex)
    }

    bodyDataSource?.apply(bodySnapshot, animatingDifferences: true)

    // Reload selection column (if visible)
    if configuration.showsSelectionColumn {
      var selectionSnapshot = NSDiffableDataSourceSnapshot<Int, IronDatabaseCellItem>()

      for rowIndex in 0..<rowCount {
        selectionSnapshot.appendSections([rowIndex])

        guard let row = coordinator?.row(at: rowIndex) else { continue }

        // Selection column has one item per row (columnIndex 0)
        let item = IronDatabaseCellItem(columnIndex: 0, rowIndex: rowIndex, rowID: row.id)
        selectionSnapshot.appendItems([item], toSection: rowIndex)
      }

      selectionColumnDataSource?.apply(selectionSnapshot, animatingDifferences: true)
    }

    // Reload header and update width
    headerCollectionView.reloadData()
    updateHeaderWidth()
  }

  /// Reconfigures a single item using the diffable data source's reconfigure API.
  ///
  /// This method must be used instead of direct `reloadItems(at:)` calls when
  /// using a `UICollectionViewDiffableDataSource`, as direct manipulation causes crashes.
  func reconfigureItem(_ item: IronDatabaseCellItem) {
    guard var snapshot = bodyDataSource?.snapshot() else { return }
    snapshot.reconfigureItems([item])
    bodyDataSource?.apply(snapshot, animatingDifferences: true)
  }

  /// Reconfigures multiple items at once.
  func reconfigureItems(_ items: [IronDatabaseCellItem]) {
    guard !items.isEmpty, var snapshot = bodyDataSource?.snapshot() else { return }
    snapshot.reconfigureItems(items)
    bodyDataSource?.apply(snapshot, animatingDifferences: true)
  }

  /// Sets the editing cell and reconfigures both the old and new cells.
  ///
  /// This ensures the focus ring is properly removed from the old cell
  /// and added to the new cell.
  func setEditingCell(_ newEditingCell: CellIdentifier?, in coordinator: IronDatabaseIOSCoordinator?) {
    guard let coordinator else { return }

    var itemsToReconfigure = [IronDatabaseCellItem]()

    // Find the old editing cell item (to remove focus ring)
    // Body no longer contains selection column, so columnIndex = dataColumnIndex
    if
      let oldCell = coordinator.editingCell,
      let displayIndex = coordinator.displayIndex(for: oldCell.rowID),
      let dataColumnIndex = configuration.database.columns.firstIndex(where: { $0.id == oldCell.columnID })
    {
      itemsToReconfigure.append(IronDatabaseCellItem(
        columnIndex: dataColumnIndex,
        rowIndex: displayIndex,
        rowID: oldCell.rowID,
      ))
    }

    // Update the editing cell
    coordinator.editingCell = newEditingCell

    // Find the new editing cell item (to add focus ring)
    if
      let newCell = newEditingCell,
      let displayIndex = coordinator.displayIndex(for: newCell.rowID),
      let dataColumnIndex = configuration.database.columns.firstIndex(where: { $0.id == newCell.columnID })
    {
      let newItem = IronDatabaseCellItem(
        columnIndex: dataColumnIndex,
        rowIndex: displayIndex,
        rowID: newCell.rowID,
      )
      // Avoid duplicates if same cell
      if !itemsToReconfigure.contains(newItem) {
        itemsToReconfigure.append(newItem)
      }
    }

    // Reconfigure all affected cells
    reconfigureItems(itemsToReconfigure)
  }

  /// Calculates the effective width for a column, handling all width modes.
  ///
  /// - Parameter column: The column to calculate width for.
  /// - Returns: The effective display width.
  func effectiveColumnWidth(for column: IronColumn) -> CGFloat {
    // If explicit width is set (e.g., after resize), use it
    if let explicitWidth = column.width {
      return explicitWidth
    }

    switch column.widthMode {
    case .fixed(let width):
      return width

    case .flexible(let min, let max):
      // Use default within constraints
      return Swift.min(max, Swift.max(min, column.resolvedWidth))

    case .fitHeader:
      return coordinator?.calculateFitHeaderWidth(for: column) ?? column.resolvedWidth

    case .fitContent:
      return column.resolvedWidth

    case .fill:
      // Calculate fill width based on remaining space
      return calculateFillWidth(for: column)
    }
  }

  // MARK: Private

  /// Initial configuration used only during setup before coordinator is connected.
  private let initialConfiguration: IronDatabaseTableConfiguration

  /// Tracks previous bounds size to detect size changes.
  private var previousBoundsSize = CGSize.zero

  /// The resize gesture recognizer (stored to avoid duplicate setup).
  private var resizeGesture: UIPanGestureRecognizer?

  private lazy var headerScrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.bounces = false
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    return scrollView
  }()

  private lazy var headerCollectionView: UICollectionView = {
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createHeaderLayout())
    collectionView.backgroundColor = .clear
    collectionView.isScrollEnabled = false
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    // Note: No register() calls needed - using modern CellRegistration API
    return collectionView
  }()

  /// Pinned selection column header (empty cell matching header height).
  private lazy var selectionColumnHeaderView: UIView = {
    let view = UIView()
    view.backgroundColor = .systemGray6
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  /// Pinned selection column that scrolls only vertically (like a frozen spreadsheet column).
  private lazy var selectionColumnView: UICollectionView = {
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createSelectionColumnLayout())
    collectionView.backgroundColor = .clear
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.showsVerticalScrollIndicator = false
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.allowsSelection = false
    collectionView.tag = 1 // Tag to identify in scroll sync
    return collectionView
  }()

  private lazy var bodyCollectionView: UICollectionView = {
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createBodyLayout())
    collectionView.backgroundColor = .clear
    collectionView.showsHorizontalScrollIndicator = true
    collectionView.showsVerticalScrollIndicator = true
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.allowsSelection = true
    collectionView.allowsMultipleSelection = false
    // Note: No register() calls needed - using modern CellRegistration API
    return collectionView
  }()

  private var bodyDataSource: UICollectionViewDiffableDataSource<Int, IronDatabaseCellItem>?
  private var selectionColumnDataSource: UICollectionViewDiffableDataSource<Int, IronDatabaseCellItem>?
  private var headerWidthConstraint: NSLayoutConstraint?
  private var selectionColumnWidthConstraint: NSLayoutConstraint?
  private var selectionColumnHeaderWidthConstraint: NSLayoutConstraint?
  private var bodyLeadingConstraint: NSLayoutConstraint?
  private var headerLeadingConstraint: NSLayoutConstraint?

  /// Registration for selection checkbox cells.
  private lazy var selectionCellRegistration = UICollectionView.CellRegistration<
    IronDatabaseSelectionCollectionCell,
    IronDatabaseCellItem,
  > { [weak self] cell, _, item in
    guard let self, let coordinator else { return }
    guard let row = coordinator.row(at: item.rowIndex) else { return }

    let isSelected = configuration.selection.contains(row.id)
    // Row number is 1-indexed for accessibility (human-readable)
    cell.configure(isSelected: isSelected, rowNumber: item.rowIndex + 1) { [weak self, weak coordinator] in
      IronHaptics.selection()
      coordinator?.toggleSelection(for: row.id)
      self?.reconfigureItem(item)
    }
  }

  /// Registration for data cells (text, number, date, etc.).
  private lazy var dataCellRegistration = UICollectionView.CellRegistration<
    IronDatabaseDataCollectionCell,
    IronDatabaseCellItem,
  > { [weak self] cell, _, item in
    guard let self, let coordinator else { return }
    guard let row = coordinator.row(at: item.rowIndex) else { return }

    // Body no longer contains selection column, so columnIndex maps directly to data columns
    let dataColumnIndex = item.columnIndex
    guard dataColumnIndex >= 0, dataColumnIndex < configuration.database.columns.count else { return }

    let column = configuration.database.columns[dataColumnIndex]
    let isEditing =
      coordinator.editingCell?.rowID == row.id && coordinator.editingCell?.columnID == column.id
    let isSelected = configuration.selection.contains(row.id)
    let valueBinding = coordinator.cellValueBinding(row: row.id, column: column.id)

    cell.configure(
      column: column,
      value: valueBinding,
      isEditing: isEditing,
      isSelected: isSelected,
      onTap: { [weak self, weak coordinator] in
        guard let self else { return }

        // Tap starts editing (except for checkbox columns which toggle directly)
        if column.type != .checkbox {
          IronHaptics.tap()
          setEditingCell(CellIdentifier(rowID: row.id, columnID: column.id), in: coordinator)
        }
      },
      onSubmit: { [weak self, weak coordinator] in
        // Note: Haptic feedback is handled in IronDatabaseDataCellContainer
        // along with the success flash animation
        self?.setEditingCell(nil, in: coordinator)
      },
      onEdit: { [weak self, weak coordinator] in
        IronHaptics.tap()
        // Use setEditingCell to reconfigure both old and new cells
        self?.setEditingCell(CellIdentifier(rowID: row.id, columnID: column.id), in: coordinator)
      },
      onCancel: { [weak self, weak coordinator] in
        // Cancel editing without saving changes
        self?.setEditingCell(nil, in: coordinator)
      },
      onClear: configuration.onClearCell != nil
        ? { [weak self] in
          self?.configuration.onClearCell?(row.id, column.id)
          self?.reconfigureItem(item)
        }
        : nil,
      onRowAction: configuration.onRowAction != nil
        ? { [weak self] action in
          self?.configuration.onRowAction?(action, row.id)
        }
        : nil,
    )
  }

  /// Registration for empty header cells (selection column).
  private lazy var emptyHeaderCellRegistration = UICollectionView.CellRegistration<
    IronDatabaseHeaderCollectionCell,
    Int,
  > { cell, _, _ in
    cell.configureEmpty()
  }

  /// Registration for add column button header cells.
  private lazy var addColumnHeaderCellRegistration = UICollectionView.CellRegistration<
    IronDatabaseHeaderCollectionCell,
    Int,
  > { [weak self] cell, _, _ in
    cell.configureAddButton {
      self?.configuration.onAddColumn?()
    }
  }

  /// Registration for data column header cells.
  private lazy var dataHeaderCellRegistration = UICollectionView.CellRegistration<
    IronDatabaseHeaderCollectionCell,
    Int,
  > { [weak self] cell, _, sectionIndex in
    guard let self else { return }

    // Header no longer includes selection column, so sectionIndex = columnIndex
    let columnIndex = sectionIndex
    guard columnIndex >= 0, columnIndex < configuration.database.columns.count else { return }

    let column = configuration.database.columns[columnIndex]
    let isSorted = configuration.sortState?.columnID == column.id
    let sortDirection = isSorted ? configuration.sortState?.direction : nil
    let isFiltered = configuration.filterState.filters[column.id] != nil

    let currentFilter = configuration.filterState.filters[column.id]

    // Determine if this is the last column (no separator after last column)
    let isLastColumn = (columnIndex == configuration.database.columns.count - 1)
      && !configuration.showsAddColumnButton

    cell.configure(
      column: column,
      isSorted: isSorted,
      sortDirection: sortDirection,
      isFiltered: isFiltered,
      isLastColumn: isLastColumn,
      onSort: { [weak self] in
        guard let self, let coordinator else { return }
        IronHaptics.selection()
        // Write through binding to external state
        coordinator.configuration.toggleSort(for: column.id)
        coordinator.recomputeDisplayIndices()
        reloadData()
      },
      onSortAscending: { [weak self] in
        guard let self, let coordinator else { return }
        coordinator.configuration.sortState = IronDatabaseSortState(columnID: column.id, direction: .ascending)
        coordinator.recomputeDisplayIndices()
        reloadData()
      },
      onSortDescending: { [weak self] in
        guard let self, let coordinator else { return }
        coordinator.configuration.sortState = IronDatabaseSortState(columnID: column.id, direction: .descending)
        coordinator.recomputeDisplayIndices()
        reloadData()
      },
      onClearSort: { [weak self] in
        guard let self, let coordinator else { return }
        coordinator.configuration.sortState = nil
        coordinator.recomputeDisplayIndices()
        reloadData()
      },
      currentFilter: currentFilter,
      onApplyFilter: { [weak self] newFilter in
        guard let self, let coordinator else { return }
        if let newFilter {
          coordinator.configuration.filterState.filters[column.id] = newFilter
          IronHaptics.impact(.medium)
        } else {
          coordinator.configuration.filterState.filters.removeValue(forKey: column.id)
          IronHaptics.impact(.light)
        }
        coordinator.recomputeDisplayIndices()
        reloadData()
      },
      onClearFilter: { [weak self] in
        guard let self, let coordinator else { return }
        coordinator.configuration.filterState.filters.removeValue(forKey: column.id)
        coordinator.recomputeDisplayIndices()
        reloadData()
      },
      isResizable: column.isResizable && column.widthMode.allowsUserResizing,
      onAdjustWidth: column.isResizable && column.widthMode.allowsUserResizing
        ? { [weak self] delta in
          guard let self, let coordinator else { return }
          let currentWidth = effectiveColumnWidth(for: column)
          let newWidth = max(column.widthMode.minimumWidth, currentWidth + delta)
          coordinator.configuration.database.columns[columnIndex].width = newWidth
          rebuildLayout()

          // Announce for accessibility
          UIAccessibility.post(
            notification: .announcement,
            argument: "\(column.name) column width \(delta > 0 ? "increased" : "decreased") to \(Int(newWidth)) points",
          )
        }
        : nil,
      onResetWidth: column.isResizable && column.widthMode.allowsUserResizing
        ? { [weak self] in
          guard let self, let coordinator else { return }
          // Reset to fitHeader calculated width
          let calculatedWidth = coordinator.calculateFitHeaderWidth(for: column)
          coordinator.configuration.database.columns[columnIndex].width = calculatedWidth
          rebuildLayout()

          // Announce for accessibility
          UIAccessibility.post(
            notification: .announcement,
            argument: "\(column.name) column width reset to \(Int(calculatedWidth)) points",
          )
        }
        : nil,
    )
  }

  /// Registration for empty cells in the body (used for add column placeholder).
  private lazy var emptyBodyCellRegistration = UICollectionView.CellRegistration<
    UICollectionViewCell,
    IronDatabaseCellItem,
  > { cell, _, _ in
    // Clear any existing content configuration
    cell.contentConfiguration = UIHostingConfiguration {
      Color.clear
    }
    .background(.clear)
  }

  /// Calculates total content width for the header (excludes selection column which is separate).
  private var totalContentWidth: CGFloat {
    var width: CGFloat = 0

    for column in configuration.database.columns {
      width += effectiveColumnWidth(for: column)
    }

    if configuration.showsAddColumnButton {
      width += 44
    }

    // Account for selection column offset when calculating minimum width
    let availableWidth = bounds.width - (configuration.showsSelectionColumn ? configuration.selectionColumnWidth : 0)
    return max(width, availableWidth)
  }

  /// Width of body content (excludes selection column which is separate).
  private var bodyContentWidth: CGFloat {
    var width: CGFloat = 0

    for column in configuration.database.columns {
      width += effectiveColumnWidth(for: column)
    }

    if configuration.showsAddColumnButton {
      width += 44
    }

    return max(width, bounds.width - (configuration.showsSelectionColumn ? configuration.selectionColumnWidth : 0))
  }

  /// Animates the selection column sliding in or out.
  private func animateSelectionColumnTransition(visible: Bool) {
    let columnWidth = visible ? configuration.selectionColumnWidth : 0

    // Prepare layouts and data BEFORE animation to avoid pop at end
    if visible {
      // Show and position selection column at starting position (off-screen left)
      selectionColumnView.isHidden = false
      selectionColumnHeaderView.isHidden = false
      selectionColumnView.alpha = 0
      selectionColumnHeaderView.alpha = 0

      // Load selection column data
      reloadSelectionColumnData()
    }

    // Update collection view layouts to final state before animating
    bodyCollectionView.setCollectionViewLayout(createBodyLayout(), animated: false)
    headerCollectionView.setCollectionViewLayout(createHeaderLayout(), animated: false)
    reloadBodyData()
    headerCollectionView.reloadData()
    updateHeaderWidth()

    // Animate constraints and alpha
    UIView.animate(
      withDuration: 0.35,
      delay: 0,
      usingSpringWithDamping: 1.0,
      initialSpringVelocity: 0,
      options: [.beginFromCurrentState, .curveEaseOut],
    ) { [self] in
      selectionColumnWidthConstraint?.constant = columnWidth
      selectionColumnHeaderWidthConstraint?.constant = columnWidth
      bodyLeadingConstraint?.constant = columnWidth
      headerLeadingConstraint?.constant = columnWidth

      selectionColumnView.alpha = visible ? 1 : 0
      selectionColumnHeaderView.alpha = visible ? 1 : 0

      layoutIfNeeded()
    } completion: { [self] _ in
      if !visible {
        selectionColumnView.isHidden = true
        selectionColumnHeaderView.isHidden = true
      }
    }
  }

  /// Reloads only the selection column data.
  private func reloadSelectionColumnData() {
    let rowCount = coordinator?.displayRowCount ?? 0
    var selectionSnapshot = NSDiffableDataSourceSnapshot<Int, IronDatabaseCellItem>()

    for rowIndex in 0..<rowCount {
      selectionSnapshot.appendSections([rowIndex])

      guard let row = coordinator?.row(at: rowIndex) else { continue }

      let item = IronDatabaseCellItem(columnIndex: 0, rowIndex: rowIndex, rowID: row.id)
      selectionSnapshot.appendItems([item], toSection: rowIndex)
    }

    selectionColumnDataSource?.applySnapshotUsingReloadData(selectionSnapshot)
    selectionColumnView.setCollectionViewLayout(createSelectionColumnLayout(), animated: false)
  }

  /// Reloads only the body data (excludes selection column).
  private func reloadBodyData() {
    let rowCount = coordinator?.displayRowCount ?? 0
    var bodySnapshot = NSDiffableDataSourceSnapshot<Int, IronDatabaseCellItem>()
    let bodyColumnCount = configuration.database.columns.count + (configuration.showsAddColumnButton ? 1 : 0)

    for rowIndex in 0..<rowCount {
      bodySnapshot.appendSections([rowIndex])

      guard let row = coordinator?.row(at: rowIndex) else { continue }

      let items = (0..<bodyColumnCount).map { columnIndex in
        IronDatabaseCellItem(columnIndex: columnIndex, rowIndex: rowIndex, rowID: row.id)
      }
      bodySnapshot.appendItems(items, toSection: rowIndex)
    }

    bodyDataSource?.applySnapshotUsingReloadData(bodySnapshot)
  }

  /// Rebuilds layout with a full data source reload (no cell reuse).
  ///
  /// Use this when the column structure changes (e.g., selection column appears/disappears)
  /// to avoid cell reuse issues where the wrong cell type would be displayed.
  private func rebuildLayoutWithFullReload() {
    // Update selection column visibility first
    updateSelectionColumnVisibility()

    bodyCollectionView.setCollectionViewLayout(createBodyLayout(), animated: false)
    headerCollectionView.setCollectionViewLayout(createHeaderLayout(), animated: false)
    selectionColumnView.setCollectionViewLayout(createSelectionColumnLayout(), animated: false)

    let rowCount = coordinator?.displayRowCount ?? 0

    // Reload body (data columns only)
    var bodySnapshot = NSDiffableDataSourceSnapshot<Int, IronDatabaseCellItem>()
    let bodyColumnCount = configuration.database.columns.count + (configuration.showsAddColumnButton ? 1 : 0)

    for rowIndex in 0..<rowCount {
      bodySnapshot.appendSections([rowIndex])

      guard let row = coordinator?.row(at: rowIndex) else { continue }

      let items = (0..<bodyColumnCount).map { columnIndex in
        IronDatabaseCellItem(columnIndex: columnIndex, rowIndex: rowIndex, rowID: row.id)
      }
      bodySnapshot.appendItems(items, toSection: rowIndex)
    }

    // Use reloadData to force fresh cells
    bodyDataSource?.applySnapshotUsingReloadData(bodySnapshot)

    // Reload selection column (if visible)
    if configuration.showsSelectionColumn {
      var selectionSnapshot = NSDiffableDataSourceSnapshot<Int, IronDatabaseCellItem>()

      for rowIndex in 0..<rowCount {
        selectionSnapshot.appendSections([rowIndex])

        guard let row = coordinator?.row(at: rowIndex) else { continue }

        let item = IronDatabaseCellItem(columnIndex: 0, rowIndex: rowIndex, rowID: row.id)
        selectionSnapshot.appendItems([item], toSection: rowIndex)
      }

      selectionColumnDataSource?.applySnapshotUsingReloadData(selectionSnapshot)
    }

    headerCollectionView.reloadData()
    updateHeaderWidth()
  }

  /// Calculates the width for a `.fill` column based on available space.
  private func calculateFillWidth(for targetColumn: IronColumn) -> CGFloat {
    let availableWidth = bounds.width

    // Calculate total fixed/non-fill width
    var fixedWidth: CGFloat = 0
    var totalFillWeight: CGFloat = 0

    if configuration.showsSelectionColumn {
      fixedWidth += configuration.selectionColumnWidth
    }

    for column in configuration.database.columns {
      if case .fill(let weight) = column.widthMode, column.width == nil {
        totalFillWeight += weight
      } else {
        // Non-fill columns or columns with explicit width
        if let explicitWidth = column.width {
          fixedWidth += explicitWidth
        } else {
          switch column.widthMode {
          case .fixed(let width):
            fixedWidth += width
          case .flexible(let min, _):
            fixedWidth += min
          case .fitHeader:
            fixedWidth += coordinator?.calculateFitHeaderWidth(for: column) ?? column.resolvedWidth
          case .fitContent:
            fixedWidth += column.resolvedWidth
          case .fill:
            break // Handled above
          }
        }
      }
    }

    if configuration.showsAddColumnButton {
      fixedWidth += 44
    }

    // Distribute remaining space among fill columns
    let remainingWidth = max(0, availableWidth - fixedWidth)
    guard totalFillWeight > 0 else { return targetColumn.resolvedWidth }

    if case .fill(let weight) = targetColumn.widthMode {
      return max(40, (remainingWidth * weight) / totalFillWeight)
    }

    return targetColumn.resolvedWidth
  }

  private func updateHeaderWidth() {
    headerWidthConstraint?.constant = totalContentWidth
  }

  private func setupViews() {
    backgroundColor = .clear

    // Header
    addSubview(headerScrollView)
    headerScrollView.addSubview(headerCollectionView)

    // Selection column header (pinned, empty)
    addSubview(selectionColumnHeaderView)

    // Selection column body (pinned, scrolls only vertically)
    addSubview(selectionColumnView)

    // Body
    addSubview(bodyCollectionView)

    // Create dynamic constraints (will be updated based on edit mode)
    headerWidthConstraint = headerCollectionView.widthAnchor.constraint(equalToConstant: 1000)
    selectionColumnWidthConstraint = selectionColumnView.widthAnchor.constraint(
      equalToConstant: configuration.selectionColumnWidth
    )
    selectionColumnHeaderWidthConstraint = selectionColumnHeaderView.widthAnchor.constraint(
      equalToConstant: configuration.selectionColumnWidth
    )
    bodyLeadingConstraint = bodyCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor)
    headerLeadingConstraint = headerScrollView.leadingAnchor.constraint(equalTo: leadingAnchor)

    NSLayoutConstraint.activate([
      // Header scroll view - starts after selection column when visible (aligned with body)
      headerScrollView.topAnchor.constraint(equalTo: topAnchor),
      headerLeadingConstraint!,
      headerScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
      headerScrollView.heightAnchor.constraint(equalToConstant: configuration.headerHeight),

      // Header collection view (inside scroll view)
      headerCollectionView.topAnchor.constraint(equalTo: headerScrollView.topAnchor),
      headerCollectionView.leadingAnchor.constraint(equalTo: headerScrollView.leadingAnchor),
      headerCollectionView.bottomAnchor.constraint(equalTo: headerScrollView.bottomAnchor),
      headerCollectionView.heightAnchor.constraint(equalToConstant: configuration.headerHeight),
      headerWidthConstraint!,

      // Selection column header (pinned on left, empty cell)
      selectionColumnHeaderView.topAnchor.constraint(equalTo: topAnchor),
      selectionColumnHeaderView.leadingAnchor.constraint(equalTo: leadingAnchor),
      selectionColumnHeaderView.heightAnchor.constraint(equalToConstant: configuration.headerHeight),
      selectionColumnHeaderWidthConstraint!,

      // Selection column body (pinned on left, scrolls only vertically)
      selectionColumnView.topAnchor.constraint(equalTo: headerScrollView.bottomAnchor),
      selectionColumnView.leadingAnchor.constraint(equalTo: leadingAnchor),
      selectionColumnView.bottomAnchor.constraint(equalTo: bottomAnchor),
      selectionColumnWidthConstraint!,

      // Body collection view - positioned after selection column when visible
      bodyCollectionView.topAnchor.constraint(equalTo: headerScrollView.bottomAnchor),
      bodyLeadingConstraint!,
      bodyCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
      bodyCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    // Initially hide selection column (shown in edit mode)
    updateSelectionColumnVisibility()

    // Sync horizontal scroll
    bodyCollectionView.delegate = self
    selectionColumnView.delegate = self

    // Setup data sources
    setupHeaderDataSource()
    setupBodyDataSource()
    setupSelectionColumnDataSource()

    // Setup resize gesture recognizer
    setupResizeGesture()
  }

  /// Updates selection column visibility and body/header leading constraints.
  private func updateSelectionColumnVisibility() {
    let showSelection = configuration.showsSelectionColumn
    let columnWidth = showSelection ? configuration.selectionColumnWidth : 0

    selectionColumnView.isHidden = !showSelection
    selectionColumnHeaderView.isHidden = !showSelection
    selectionColumnWidthConstraint?.constant = columnWidth
    selectionColumnHeaderWidthConstraint?.constant = columnWidth
    bodyLeadingConstraint?.constant = columnWidth
    headerLeadingConstraint?.constant = columnWidth
  }

  private func setupResizeGesture() {
    guard let coordinator, resizeGesture == nil else { return }

    let gesture = UIPanGestureRecognizer(
      target: coordinator,
      action: #selector(IronDatabaseIOSCoordinator.handleResizeGesture(_:)),
    )
    gesture.delegate = coordinator
    headerScrollView.addGestureRecognizer(gesture)
    resizeGesture = gesture

    // Setup pointer interaction for iPadOS (resize cursor on hover)
    let pointerInteraction = UIPointerInteraction(delegate: self)
    headerScrollView.addInteraction(pointerInteraction)
  }

  private func setupHeaderDataSource() {
    // Create registrations upfront by accessing the lazy properties
    // This is required per Apple's documentation for iOS 15+
    _ = emptyHeaderCellRegistration
    _ = addColumnHeaderCellRegistration
    _ = dataHeaderCellRegistration

    headerCollectionView.dataSource = self
  }

  private func setupSelectionColumnDataSource() {
    // Create registration upfront
    _ = selectionCellRegistration

    selectionColumnDataSource = UICollectionViewDiffableDataSource<Int, IronDatabaseCellItem>(
      collectionView: selectionColumnView
    ) { [weak self] collectionView, indexPath, item in
      guard let self else { return UICollectionViewCell() }

      return collectionView.dequeueConfiguredReusableCell(
        using: selectionCellRegistration,
        for: indexPath,
        item: item,
      )
    }
  }

  private func setupBodyDataSource() {
    // Create registrations upfront by accessing the lazy properties
    // This is required per Apple's documentation for iOS 15+
    _ = dataCellRegistration
    _ = emptyBodyCellRegistration

    bodyDataSource = UICollectionViewDiffableDataSource<Int, IronDatabaseCellItem>(
      collectionView: bodyCollectionView
    ) { [weak self] collectionView, indexPath, item in
      guard let self else { return UICollectionViewCell() }

      // Calculate the add column index (last column when add button is shown)
      let addColumnIndex = configuration.database.columns.count

      // Add column placeholder - use empty cell registration
      if configuration.showsAddColumnButton, item.columnIndex == addColumnIndex {
        return collectionView.dequeueConfiguredReusableCell(
          using: emptyBodyCellRegistration,
          for: indexPath,
          item: item,
        )
      }

      // Data column - use data cell registration
      return collectionView.dequeueConfiguredReusableCell(
        using: dataCellRegistration,
        for: indexPath,
        item: item,
      )
    }
  }

  /// Creates layout for the pinned selection column (one checkbox per row).
  private func createSelectionColumnLayout() -> UICollectionViewLayout {
    let config = UICollectionViewCompositionalLayoutConfiguration()
    config.scrollDirection = .vertical

    return UICollectionViewCompositionalLayout(
      sectionProvider: { [weak self] _, _ in
        guard let self else { return nil }

        let itemSize = NSCollectionLayoutSize(
          widthDimension: .fractionalWidth(1.0),
          heightDimension: .absolute(configuration.rowHeight),
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
          widthDimension: .fractionalWidth(1.0),
          heightDimension: .absolute(configuration.rowHeight),
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        return NSCollectionLayoutSection(group: group)
      },
      configuration: config,
    )
  }

  private func createHeaderLayout() -> UICollectionViewLayout {
    let config = UICollectionViewCompositionalLayoutConfiguration()
    config.scrollDirection = .horizontal

    return UICollectionViewCompositionalLayout(
      sectionProvider: { [weak self] sectionIndex, _ in
        guard let self else { return nil }
        return createHeaderColumnSection(at: sectionIndex)
      },
      configuration: config,
    )
  }

  /// Creates a section layout for a single header column.
  private func createHeaderColumnSection(at sectionIndex: Int) -> NSCollectionLayoutSection {
    let columnWidth: CGFloat

    // Header no longer includes selection column (it's a separate fixed view)
    // So sectionIndex maps directly to data columns
    if sectionIndex < configuration.database.columns.count {
      let column = configuration.database.columns[sectionIndex]
      columnWidth = effectiveColumnWidth(for: column)
    } else {
      // Add column button
      columnWidth = 44
    }

    let itemSize = NSCollectionLayoutSize(
      widthDimension: .absolute(columnWidth),
      heightDimension: .absolute(configuration.headerHeight),
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .absolute(columnWidth),
      heightDimension: .absolute(configuration.headerHeight),
    )
    let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

    return NSCollectionLayoutSection(group: group)
  }

  private func createBodyLayout() -> UICollectionViewLayout {
    let config = UICollectionViewCompositionalLayoutConfiguration()
    config.scrollDirection = .vertical

    return UICollectionViewCompositionalLayout(
      sectionProvider: { [weak self] _, _ in
        guard let self else { return nil }
        return createRowSection()
      },
      configuration: config,
    )
  }

  /// Creates a section layout for a single row.
  ///
  /// Each row section contains items for data columns laid out horizontally.
  /// The selection column is in a separate pinned view.
  private func createRowSection() -> NSCollectionLayoutSection {
    // Build items for each column (selection column is separate)
    var items = [NSCollectionLayoutItem]()

    // Data columns
    for column in configuration.database.columns {
      let columnWidth = effectiveColumnWidth(for: column)
      let columnItem = NSCollectionLayoutItem(
        layoutSize: NSCollectionLayoutSize(
          widthDimension: .absolute(columnWidth),
          heightDimension: .absolute(configuration.rowHeight),
        )
      )
      items.append(columnItem)
    }

    // Add column button (if shown)
    if configuration.showsAddColumnButton {
      let addItem = NSCollectionLayoutItem(
        layoutSize: NSCollectionLayoutSize(
          widthDimension: .absolute(44),
          heightDimension: .absolute(configuration.rowHeight),
        )
      )
      items.append(addItem)
    }

    // Create horizontal group containing all column items
    let group = NSCollectionLayoutGroup.horizontal(
      layoutSize: NSCollectionLayoutSize(
        widthDimension: .absolute(bodyContentWidth),
        heightDimension: .absolute(configuration.rowHeight),
      ),
      subitems: items,
    )

    return NSCollectionLayoutSection(group: group)
  }

}

// MARK: - UIScrollViewDelegate & UICollectionViewDelegate

extension IronDatabaseTableContainerView: UICollectionViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView === bodyCollectionView {
      // Sync header horizontal scroll with body
      headerScrollView.contentOffset.x = scrollView.contentOffset.x

      // Sync selection column vertical scroll with body
      if configuration.showsSelectionColumn {
        selectionColumnView.contentOffset.y = scrollView.contentOffset.y
      }
    } else if scrollView === selectionColumnView {
      // Sync body vertical scroll with selection column
      bodyCollectionView.contentOffset.y = scrollView.contentOffset.y
    }
  }

}

// MARK: - UICollectionViewDataSource for Header

extension IronDatabaseTableContainerView: UICollectionViewDataSource {
  func numberOfSections(in _: UICollectionView) -> Int {
    // Header no longer includes selection column (it's a separate fixed view)
    configuration.database.columns.count + (configuration.showsAddColumnButton ? 1 : 0)
  }

  func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
    1 // Header has one item per section
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath,
  ) -> UICollectionViewCell {
    let sectionIndex = indexPath.section

    // Header no longer includes selection column (it's a separate fixed view)
    // So sectionIndex maps directly to data columns
    guard sectionIndex < configuration.database.columns.count else {
      // Add column button - use add column registration
      return collectionView.dequeueConfiguredReusableCell(
        using: addColumnHeaderCellRegistration,
        for: indexPath,
        item: sectionIndex,
      )
    }

    // Data column header - use data header registration
    return collectionView.dequeueConfiguredReusableCell(
      using: dataHeaderCellRegistration,
      for: indexPath,
      item: sectionIndex,
    )
  }
}

// MARK: - UIPointerInteractionDelegate

extension IronDatabaseTableContainerView: UIPointerInteractionDelegate {

  func pointerInteraction(
    _: UIPointerInteraction,
    regionFor request: UIPointerRegionRequest,
    defaultRegion: UIPointerRegion,
  ) -> UIPointerRegion? {
    let location = request.location

    // Check if we're on a resize boundary
    guard
      let coordinator,
      coordinator.columnAtResizeBoundary(location: location, in: headerScrollView) != nil
    else {
      return defaultRegion
    }

    // Return a narrow vertical strip at the boundary
    return UIPointerRegion(
      rect: CGRect(
        x: location.x - 4,
        y: 0,
        width: 8,
        height: configuration.headerHeight,
      )
    )
  }

  func pointerInteraction(
    _: UIPointerInteraction,
    styleFor region: UIPointerRegion,
  ) -> UIPointerStyle? {
    let centerX = region.rect.midX
    let testLocation = CGPoint(x: centerX, y: configuration.headerHeight / 2)

    // Check if we're on a resize boundary
    guard
      let coordinator,
      coordinator.columnAtResizeBoundary(location: testLocation, in: headerScrollView) != nil
    else {
      return nil
    }

    // Show vertical resize cursor
    return UIPointerStyle(
      shape: .verticalBeam(length: configuration.headerHeight),
      constrainedAxes: .vertical,
    )
  }
}

// MARK: - IronDatabaseHeaderCollectionCell

/// Collection view cell for header items using modern UIHostingConfiguration.
final class IronDatabaseHeaderCollectionCell: UICollectionViewCell {

  // MARK: Lifecycle

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .systemGray6
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  func configureEmpty() {
    contentConfiguration = UIHostingConfiguration {
      Color.clear
    }
    .background(.clear)
  }

  func configureAddButton(onTap: @escaping () -> Void) {
    contentConfiguration = UIHostingConfiguration {
      Button(action: onTap) {
        Image(systemName: "plus")
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .background(.clear)
  }

  func configure(
    column: IronColumn,
    isSorted: Bool,
    sortDirection: IronDatabaseSortState.SortDirection?,
    isFiltered: Bool,
    isLastColumn: Bool = false,
    onSort: @escaping () -> Void,
    onSortAscending: (() -> Void)? = nil,
    onSortDescending: (() -> Void)? = nil,
    onClearSort: (() -> Void)? = nil,
    currentFilter: IronDatabaseFilter? = nil,
    onApplyFilter: ((IronDatabaseFilter?) -> Void)? = nil,
    onClearFilter: (() -> Void)? = nil,
    onRename: (() -> Void)? = nil,
    onDelete: (() -> Void)? = nil,
    isResizable: Bool = false,
    onAdjustWidth: ((CGFloat) -> Void)? = nil,
    onResetWidth: (() -> Void)? = nil,
  ) {
    contentConfiguration = UIHostingConfiguration {
      IronDatabaseHeaderCellContent(
        column: column,
        isSorted: isSorted,
        sortDirection: sortDirection,
        isFiltered: isFiltered,
        isLastColumn: isLastColumn,
        onSort: onSort,
        onSortAscending: onSortAscending,
        onSortDescending: onSortDescending,
        onClearSort: onClearSort,
        currentFilter: currentFilter,
        onApplyFilter: onApplyFilter,
        onClearFilter: onClearFilter,
        onRename: onRename,
        onDelete: onDelete,
        isResizable: isResizable,
        onAdjustWidth: onAdjustWidth,
        onResetWidth: onResetWidth,
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .margins(.all, 0)
    .background(.clear)
  }
}

// MARK: - IronDatabaseDataCollectionCell

/// Collection view cell for data items using modern UIHostingConfiguration.
final class IronDatabaseDataCollectionCell: UICollectionViewCell {

  func configure(
    column: IronColumn,
    value: Binding<IronCellValue>,
    isEditing: Bool,
    isSelected: Bool,
    onTap: @escaping () -> Void,
    onSubmit: @escaping () -> Void,
    onEdit: (() -> Void)? = nil,
    onCancel: (() -> Void)? = nil,
    onClear: (() -> Void)? = nil,
    onRowAction: ((IronDatabaseRowAction) -> Void)? = nil,
  ) {
    // Build accessibility label: "Column Name: value" or "Column Name: empty"
    let accessibilityLabel = "\(column.name): \(value.wrappedValue.accessibilityLabel)"
    let accessibilityHint =
      column.type == .checkbox
        ? "Double tap to toggle"
        : "Double tap to edit, hold for options"

    contentConfiguration = UIHostingConfiguration {
      IronDatabaseDataCellContainer(
        column: column,
        value: value,
        isEditing: isEditing,
        isSelected: isSelected,
        onTap: onTap,
        onSubmit: onSubmit,
        onEdit: onEdit,
        onCancel: onCancel,
        onClear: onClear,
        onRowAction: onRowAction,
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(accessibilityLabel)
      .accessibilityHint(accessibilityHint)
      .accessibilityAddTraits(column.type == .checkbox ? .isButton : [])
    }
    .margins(.horizontal, 8)
    .background(.clear)
  }
}

// MARK: - IronDatabaseSelectionCollectionCell

/// Collection view cell for selection checkboxes using modern UIHostingConfiguration.
final class IronDatabaseSelectionCollectionCell: UICollectionViewCell {

  func configure(isSelected: Bool, rowNumber: Int, onToggle: @escaping () -> Void) {
    contentConfiguration = UIHostingConfiguration {
      IronSelectionCheckbox(isSelected: isSelected, rowNumber: rowNumber, onToggle: onToggle)
    }
    .background(.clear)
  }
}

/// Animated checkbox for row selection.
private struct IronSelectionCheckbox: View {

  // MARK: Internal

  let isSelected: Bool
  let rowNumber: Int
  let onToggle: () -> Void

  var body: some View {
    Button(action: onToggle) {
      Image(systemName: isSelected ? "checkmark.square.fill" : "square")
        .foregroundStyle(isSelected ? Color.blue : Color.secondary)
        .font(.title3)
        .contentTransition(.symbolEffect(.replace))
    }
    .buttonStyle(.plain)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityLabel("Select row \(rowNumber)")
    .accessibilityValue(isSelected ? "Selected" : "Not selected")
    .accessibilityAddTraits(.isButton)
    .accessibleAnimation(theme.animation.snappy, value: isSelected)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

}

// MARK: - IronDatabaseDataCellContainer

/// Container view that wraps data cells with visual feedback (focus ring, selection highlight).
private struct IronDatabaseDataCellContainer: View {

  // MARK: Internal

  let column: IronColumn
  @Binding var value: IronCellValue
  let isEditing: Bool
  let isSelected: Bool
  let onTap: () -> Void
  let onSubmit: () -> Void
  var onEdit: (() -> Void)?
  var onCancel: (() -> Void)?
  var onClear: (() -> Void)?
  var onRowAction: ((IronDatabaseRowAction) -> Void)?

  var body: some View {
    IronDatabaseCell(column: column, value: $value, isEditing: isEditing)
      .onSubmit {
        // Show brief success flash before submitting
        showSuccessFlash = true
        IronHaptics.success()
        onSubmit()

        // Reset flash after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          showSuccessFlash = false
        }
      }
      .onTapGesture { onTap() }
      .padding(.horizontal, theme.spacing.xs)
      .padding(.vertical, theme.spacing.xxs)
      .background(backgroundColor)
      .clipShape(RoundedRectangle(cornerRadius: theme.radii.sm))
      .overlay {
        // Success flash overlay
        if showSuccessFlash {
          RoundedRectangle(cornerRadius: theme.radii.sm)
            .fill(theme.colors.success.opacity(0.2))
            .transition(.opacity)
        }

        // Focus ring when editing
        if isEditing {
          RoundedRectangle(cornerRadius: theme.radii.sm)
            .strokeBorder(theme.colors.primary, lineWidth: 2)
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
      }
      // Escape key cancels editing (works on iPad with keyboard and macOS)
      .onKeyPress(.escape) {
        if isEditing, let onCancel {
          IronHaptics.impact(.light)
          onCancel()
          return .handled
        }
        return .ignored
      }
      .contextMenu {
        // Cell actions
        if onEdit != nil {
          Button {
            onEdit?()
          } label: {
            Label("Edit", systemImage: "pencil")
          }
        }

        Button {
          UIPasteboard.general.string = value.textValue
          IronHaptics.tap()
        } label: {
          Label("Copy", systemImage: "doc.on.doc")
        }

        if !value.isEmpty, onClear != nil {
          Divider()

          Button(role: .destructive) {
            IronHaptics.impact(.medium)
            onClear?()
          } label: {
            Label("Clear", systemImage: "xmark.circle")
          }
        }

        // Row actions section
        if onRowAction != nil {
          Divider()

          Section("Row") {
            Button {
              onRowAction?(.insertAbove)
            } label: {
              Label("Insert Row Above", systemImage: "arrow.up.to.line")
            }

            Button {
              onRowAction?(.insertBelow)
            } label: {
              Label("Insert Row Below", systemImage: "arrow.down.to.line")
            }

            Button {
              onRowAction?(.duplicate)
            } label: {
              Label("Duplicate Row", systemImage: "doc.on.doc")
            }

            Divider()

            Button(role: .destructive) {
              IronHaptics.impact(.medium)
              onRowAction?(.delete)
            } label: {
              Label("Delete Row", systemImage: "trash")
            }
          }
        }
      }
      .accessibleAnimation(theme.animation.snappy, value: isEditing)
      .accessibleAnimation(theme.animation.snappy, value: isSelected)
      .accessibleAnimation(theme.animation.snappy, value: showSuccessFlash)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @State private var showSuccessFlash = false

  private var backgroundColor: Color {
    if isEditing {
      return theme.colors.surfaceElevated
    } else if isSelected {
      return theme.colors.primary.opacity(0.08)
    }
    return .clear
  }
}

// MARK: - IronDatabaseHeaderCellContent

/// SwiftUI content for header cells.
private struct IronDatabaseHeaderCellContent: View {

  // MARK: Internal

  let column: IronColumn
  let isSorted: Bool
  let sortDirection: IronDatabaseSortState.SortDirection?
  let isFiltered: Bool
  var isLastColumn = false
  let onSort: () -> Void
  var onSortAscending: (() -> Void)?
  var onSortDescending: (() -> Void)?
  var onClearSort: (() -> Void)?
  var currentFilter: IronDatabaseFilter?
  var onApplyFilter: ((IronDatabaseFilter?) -> Void)?
  var onClearFilter: (() -> Void)?
  var onRename: (() -> Void)?
  var onDelete: (() -> Void)?
  var isResizable = false
  var onAdjustWidth: ((CGFloat) -> Void)?
  var onResetWidth: (() -> Void)?

  var body: some View {
    // Tap shows menu with column options (Notion-style)
    Menu {
      // Sort section (only if sortable)
      if column.isSortable {
        Section("Sort") {
          Button {
            IronHaptics.selection()
            onSortAscending?()
          } label: {
            Label("Sort Ascending", systemImage: "arrow.up")
          }

          Button {
            IronHaptics.selection()
            onSortDescending?()
          } label: {
            Label("Sort Descending", systemImage: "arrow.down")
          }

          if isSorted {
            Button {
              IronHaptics.selection()
              onClearSort?()
            } label: {
              Label("Clear Sort", systemImage: "xmark")
            }
          }
        }
      }

      // Filter section (only if filterable)
      if column.isFilterable {
        Section("Filter") {
          Button {
            IronHaptics.impact(.medium)
            localFilter = currentFilter
            showFilterPopover = true
          } label: {
            Label("Add Filter...", systemImage: "line.3.horizontal.decrease")
          }

          if isFiltered {
            Button {
              IronHaptics.impact(.light)
              onClearFilter?()
            } label: {
              Label("Clear Filter", systemImage: "xmark.circle")
            }
          }
        }
      }

      Divider()

      // Column management
      if onRename != nil {
        Button {
          onRename?()
        } label: {
          Label("Rename", systemImage: "pencil")
        }
      }

      // Type change submenu
      Menu("Change Type") {
        ForEach(IronColumnType.allCases, id: \.self) { type in
          Button {
            // Type change would need configuration callback
          } label: {
            Label(type.displayName, systemImage: type.iconName)
          }
          .disabled(type == column.type)
        }
      }

      // Resize actions (in menu for accessibility)
      if isResizable {
        Divider()

        Section("Resize") {
          Button {
            IronHaptics.selection()
            onAdjustWidth?(20)
          } label: {
            Label("Increase Width", systemImage: "arrow.left.and.right.square")
          }

          Button {
            IronHaptics.selection()
            onAdjustWidth?(-20)
          } label: {
            Label("Decrease Width", systemImage: "arrow.right.and.left.square")
          }

          Button {
            IronHaptics.selection()
            onResetWidth?()
          } label: {
            Label("Fit to Header", systemImage: "arrow.up.left.and.arrow.down.right")
          }
        }
      }

      Divider()

      if onDelete != nil {
        Button(role: .destructive) {
          IronHaptics.impact(.medium)
          onDelete?()
        } label: {
          Label("Delete Column", systemImage: "trash")
        }
      }
    } label: {
      headerLabelContent
    }
    .accessibilityLabel(accessibilityLabel)
    .accessibilityHint(accessibilityHint)
    // Column boundary separator (between all columns except after the last)
    .overlay(alignment: .trailing) {
      if !isLastColumn {
        Rectangle()
          .fill(theme.colors.border)
          .frame(width: 1)
      }
    }
    // Grip indicator for resizable columns (inside the cell, near the right edge)
    .overlay(alignment: .trailing) {
      if isResizable {
        resizeHandle
          .accessibilityHidden(true)
      }
    }
    .popover(isPresented: $showFilterPopover) {
      IronDatabaseFilterPopover(
        column: column,
        filter: $localFilter,
        selectOptions: column.options,
      )
      .presentationCompactAdaptation(.popover)
      .onChange(of: localFilter) { _, newValue in
        // Apply filter immediately as user makes changes
        onApplyFilter?(newValue)
      }
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @State private var showFilterPopover = false
  @State private var localFilter: IronDatabaseFilter?

  /// The header label content (inside the Menu).
  ///
  /// Layout specs:
  /// - Resizable, no sort:   `| -(12)- [Icon] -(4)- [Title] -(8)- [GrabBar] -(12)- |`
  /// - Resizable, with sort: `| -(12)- [Icon] -(4)- [Title] -(4)- [Chevron] -(8)- [GrabBar] -(12)- |`
  /// - Not resizable:        `| -(12)- [Icon] -(4)- [Title/Chevron] -(12)- |`
  private var headerLabelContent: some View {
    HStack(spacing: 4) {
      Image(systemName: column.type.iconName)
        .foregroundStyle(.secondary)
        .font(.caption)

      Text(column.name)
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .truncationMode(.tail)

      // Sort/filter indicators follow immediately after the column name
      if isSorted, let direction = sortDirection {
        Image(systemName: direction.iconName)
          .foregroundStyle(.blue)
          .font(.caption)
      }

      if isFiltered {
        Image(systemName: "line.3.horizontal.decrease.circle.fill")
          .foregroundStyle(.blue)
          .font(.caption)
      }

      Spacer(minLength: 0)
    }
    .padding(.leading, 12)
    // Trailing: 8pt gap to grabbar + ~9pt dots + 12pt to separator = 29pt for resizable
    // Non-resizable: just 12pt trailing
    .padding(.trailing, isResizable ? 29 : 12)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .contentShape(Rectangle())
  }

  /// Visual resize grip indicator (6-dot pattern like Notion).
  /// Positioned 12pt from the separator line per layout spec.
  /// The touch target extends to the column boundary for easy dragging.
  private var resizeHandle: some View {
    // 6-dot grip indicator: 2 columns × 3 rows
    HStack(spacing: 3) {
      VStack(spacing: 3) {
        ForEach(0..<3, id: \.self) { _ in
          Circle()
            .fill(theme.colors.textSecondary.opacity(0.5))
            .frame(width: 3, height: 3)
        }
      }
      VStack(spacing: 3) {
        ForEach(0..<3, id: \.self) { _ in
          Circle()
            .fill(theme.colors.textSecondary.opacity(0.5))
            .frame(width: 3, height: 3)
        }
      }
    }
    .padding(.trailing, 12) // 12pt from separator per layout spec
    .frame(width: 44, height: 44, alignment: .trailing) // 44pt touch target, dots aligned right
    .contentShape(Rectangle())
  }

  private var accessibilityLabel: String {
    var parts = ["\(column.name) column", "\(column.type.displayName) type"]

    if isSorted, let direction = sortDirection {
      parts.append(direction.accessibilityLabel)
    }

    if isFiltered {
      parts.append("Filtered")
    }

    if isResizable {
      parts.append("Resizable")
    }

    return parts.joined(separator: ", ")
  }

  private var accessibilityHint: String {
    var hints = [String]()

    if column.isSortable {
      hints.append("Tap to sort")
    }

    hints.append("Hold for more options")

    if isResizable {
      hints.append("Use actions to resize")
    }

    return hints.joined(separator: ", ")
  }

}

#endif
