#if os(iOS)
import IronCore
import IronPrimitives
import ListKit // @MainActor-safe async diffable data source wrappers
import SwiftUI
import UIKit

// MARK: - IronDatabaseTableContainerView

/// Container view that holds the header and body collection views.
final class IronDatabaseTableContainerView: UIView {

  // MARK: Lifecycle

  init(configuration: IronDatabaseTableConfiguration, selectionColumnBackgroundColor: UIColor) {
    initialConfiguration = configuration
    self.selectionColumnBackgroundColor = selectionColumnBackgroundColor
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
    var bodySnapshot = DiffableDataSourceSnapshot<Int, IronDatabaseCellItem>()
    let bodyColumnCount = configuration.database.columns.count + (configuration.showsAddColumnButton ? 1 : 0)

    for rowIndex in 0..<rowCount {
      bodySnapshot.appendSections([rowIndex])

      guard let row = coordinator?.row(at: rowIndex) else {
        IronLogger.ui.debug("Reload data: row not found, skipping", metadata: ["rowIndex": .int(rowIndex)])
        continue
      }

      let items = (0..<bodyColumnCount).map { columnIndex in
        IronDatabaseCellItem(columnIndex: columnIndex, rowIndex: rowIndex, rowID: row.id)
      }
      bodySnapshot.appendItems(items, toSection: rowIndex)
    }

    // Build selection snapshot (if visible)
    var selectionSnapshot: DiffableDataSourceSnapshot<Int, IronDatabaseCellItem>?
    if configuration.showsSelectionColumn {
      var snapshot = DiffableDataSourceSnapshot<Int, IronDatabaseCellItem>()

      for rowIndex in 0..<rowCount {
        snapshot.appendSections([rowIndex])

        guard let row = coordinator?.row(at: rowIndex) else {
          IronLogger.ui.debug("Reload data: row not found, skipping", metadata: ["rowIndex": .int(rowIndex)])
          continue
        }

        // Selection column has one item per row (columnIndex 0)
        let item = IronDatabaseCellItem(columnIndex: 0, rowIndex: rowIndex, rowID: row.id)
        snapshot.appendItems([item], toSection: rowIndex)
      }

      selectionSnapshot = snapshot
    }

    // Apply both snapshots in a single Task to preserve ordering
    Task {
      await bodyDataSource?.apply(bodySnapshot, animatingDifferences: true)
      if let selectionSnapshot {
        await selectionColumnDataSource?.apply(selectionSnapshot, animatingDifferences: true)
      }
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
    Task { await bodyDataSource?.apply(snapshot, animatingDifferences: true) }
  }

  /// Reconfigures multiple items at once.
  func reconfigureItems(_ items: [IronDatabaseCellItem]) {
    guard !items.isEmpty, var snapshot = bodyDataSource?.snapshot() else { return }
    snapshot.reconfigureItems(items)
    Task { await bodyDataSource?.apply(snapshot, animatingDifferences: true) }
  }

  /// Reconfigures all cells in a row (both body and selection column).
  ///
  /// Use this when row selection state changes to update visual feedback
  /// including the checkbox state and row highlight.
  func reconfigureRow(at rowIndex: Int) {
    guard let row = coordinator?.row(at: rowIndex) else {
      IronLogger.ui.debug("reconfigureRow: row not found", metadata: ["rowIndex": .int(rowIndex)])
      return
    }

    // Prepare selection column snapshot (if visible)
    var selectionSnapshot: DiffableDataSourceSnapshot<Int, IronDatabaseCellItem>?
    if configuration.showsSelectionColumn {
      let selectionItem = IronDatabaseCellItem(columnIndex: 0, rowIndex: rowIndex, rowID: row.id)
      if var snapshot = selectionColumnDataSource?.snapshot() {
        snapshot.reconfigureItems([selectionItem])
        selectionSnapshot = snapshot
      }
    }

    // Prepare body snapshot (for selection highlight background)
    var bodySnapshotToApply: DiffableDataSourceSnapshot<Int, IronDatabaseCellItem>?
    let bodyColumnCount = configuration.database.columns.count
    if bodyColumnCount > 0 {
      let bodyItems = (0..<bodyColumnCount).map { columnIndex in
        IronDatabaseCellItem(columnIndex: columnIndex, rowIndex: rowIndex, rowID: row.id)
      }
      if var snapshot = bodyDataSource?.snapshot() {
        // Only reconfigure items that exist in the snapshot
        let existingItems = bodyItems.filter { snapshot.itemIdentifiers.contains($0) }
        if !existingItems.isEmpty {
          snapshot.reconfigureItems(existingItems)
          bodySnapshotToApply = snapshot
        }
      }
    }

    // Apply both snapshots in a single Task to preserve ordering
    Task {
      if let selectionSnapshot {
        await selectionColumnDataSource?.apply(selectionSnapshot, animatingDifferences: true)
      }
      if let bodySnapshotToApply {
        await bodyDataSource?.apply(bodySnapshotToApply, animatingDifferences: true)
      }
    }
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

  /// Background color for selection column, passed from the theme at initialization.
  private let selectionColumnBackgroundColor: UIColor

  /// Pinned selection column header (empty cell matching header height).
  private lazy var selectionColumnHeaderView: UIView = {
    let view = UIView()
    view.backgroundColor = selectionColumnBackgroundColor
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  /// Pinned selection column that scrolls only vertically (like a frozen spreadsheet column).
  private lazy var selectionColumnView: UICollectionView = {
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createSelectionColumnLayout())
    // Use selection column background color for any gaps between cells
    collectionView.backgroundColor = selectionColumnBackgroundColor
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

  private var bodyDataSource: CollectionViewDiffableDataSource<Int, IronDatabaseCellItem>?
  private var selectionColumnDataSource: CollectionViewDiffableDataSource<Int, IronDatabaseCellItem>?
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
    guard let self, let coordinator else {
      IronLogger.ui.warning(
        "Selection cell registration: container view deallocated",
        metadata: ["rowIndex": .int(item.rowIndex)],
      )
      return
    }
    guard let row = coordinator.row(at: item.rowIndex) else {
      IronLogger.ui.warning(
        "Selection cell registration: row not found at index",
        metadata: ["rowIndex": .int(item.rowIndex)],
      )
      return
    }

    let isSelected = configuration.selection.contains(row.id)
    // Row number is 1-indexed for accessibility (human-readable)
    cell.configure(isSelected: isSelected, rowNumber: item.rowIndex + 1) { [weak self, weak coordinator] in
      IronHaptics.selection()
      coordinator?.toggleSelection(for: row.id)
      // Look up current display index to handle row reordering after sort
      guard let displayIndex = coordinator?.displayIndex(for: row.id) else { return }
      self?.reconfigureRow(at: displayIndex)
    }
  }

  /// Registration for data cells (text, number, date, etc.).
  private lazy var dataCellRegistration = UICollectionView.CellRegistration<
    IronDatabaseDataCollectionCell,
    IronDatabaseCellItem,
  > { [weak self] cell, _, item in
    guard let self, let coordinator else {
      IronLogger.ui.warning(
        "Data cell registration: container view deallocated",
        metadata: ["rowIndex": .int(item.rowIndex), "columnIndex": .int(item.columnIndex)],
      )
      return
    }
    guard let row = coordinator.row(at: item.rowIndex) else {
      IronLogger.ui.warning(
        "Data cell registration: row not found at index",
        metadata: ["rowIndex": .int(item.rowIndex)],
      )
      return
    }

    // Body no longer contains selection column, so columnIndex maps directly to data columns
    let dataColumnIndex = item.columnIndex
    guard dataColumnIndex >= 0, dataColumnIndex < configuration.database.columns.count else {
      IronLogger.ui.warning(
        "Data cell registration: column index out of bounds",
        metadata: [
          "columnIndex": .int(dataColumnIndex),
          "columnCount": .int(configuration.database.columns.count),
        ],
      )
      return
    }

    let column = configuration.database.columns[dataColumnIndex]
    let isEditing =
      coordinator.editingCell?.rowID == row.id && coordinator.editingCell?.columnID == column.id
    let isSelected = configuration.selection.contains(row.id)
    let valueBinding = coordinator.cellValueBinding(row: row.id, column: column.id)

    // Capture whether we're in table edit mode (selection mode)
    let isInEditMode = configuration.isEditing

    cell.configure(
      column: column,
      value: valueBinding,
      isEditing: isEditing,
      isSelected: isSelected,
      isInTableEditMode: isInEditMode,
      onTap: { [weak self, weak coordinator] in
        guard let self, let coordinator else { return }

        // In edit mode, tap toggles row selection (Apple Mail style)
        if isInEditMode {
          IronHaptics.selection()
          coordinator.toggleSelection(for: row.id)
          // Look up current display index to handle row reordering after sort
          guard let displayIndex = coordinator.displayIndex(for: row.id) else { return }
          reconfigureRow(at: displayIndex)
          return
        }

        // Normal mode: tap starts editing (except for checkbox columns which toggle directly)
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
    guard let self else {
      IronLogger.ui.warning(
        "Header cell registration: container view deallocated",
        metadata: ["sectionIndex": .int(sectionIndex)],
      )
      return
    }

    // Header no longer includes selection column, so sectionIndex = columnIndex
    let columnIndex = sectionIndex
    guard columnIndex >= 0, columnIndex < configuration.database.columns.count else {
      IronLogger.ui.warning(
        "Header cell registration: column index out of bounds",
        metadata: ["columnIndex": .int(columnIndex), "columnCount": .int(configuration.database.columns.count)],
      )
      return
    }

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
            argument: String(
              localized: "\(column.name) column width \(delta > 0 ? "increased" : "decreased") to \(Int(newWidth)) points"
            ),
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
            argument: String(localized: "\(column.name) column width reset to \(Int(calculatedWidth)) points"),
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
    var selectionSnapshot = DiffableDataSourceSnapshot<Int, IronDatabaseCellItem>()

    for rowIndex in 0..<rowCount {
      selectionSnapshot.appendSections([rowIndex])

      guard let row = coordinator?.row(at: rowIndex) else {
        IronLogger.ui.debug("Reload data: row not found, skipping", metadata: ["rowIndex": .int(rowIndex)])
        continue
      }

      let item = IronDatabaseCellItem(columnIndex: 0, rowIndex: rowIndex, rowID: row.id)
      selectionSnapshot.appendItems([item], toSection: rowIndex)
    }

    let layout = createSelectionColumnLayout()
    Task {
      await selectionColumnDataSource?.applySnapshotUsingReloadData(selectionSnapshot)
      selectionColumnView.setCollectionViewLayout(layout, animated: false)
    }
  }

  /// Reloads only the body data (excludes selection column).
  private func reloadBodyData() {
    let rowCount = coordinator?.displayRowCount ?? 0
    var bodySnapshot = DiffableDataSourceSnapshot<Int, IronDatabaseCellItem>()
    let bodyColumnCount = configuration.database.columns.count + (configuration.showsAddColumnButton ? 1 : 0)

    for rowIndex in 0..<rowCount {
      bodySnapshot.appendSections([rowIndex])

      guard let row = coordinator?.row(at: rowIndex) else {
        IronLogger.ui.debug("Reload data: row not found, skipping", metadata: ["rowIndex": .int(rowIndex)])
        continue
      }

      let items = (0..<bodyColumnCount).map { columnIndex in
        IronDatabaseCellItem(columnIndex: columnIndex, rowIndex: rowIndex, rowID: row.id)
      }
      bodySnapshot.appendItems(items, toSection: rowIndex)
    }

    Task { await bodyDataSource?.applySnapshotUsingReloadData(bodySnapshot) }
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
    var bodySnapshot = DiffableDataSourceSnapshot<Int, IronDatabaseCellItem>()
    let bodyColumnCount = configuration.database.columns.count + (configuration.showsAddColumnButton ? 1 : 0)

    for rowIndex in 0..<rowCount {
      bodySnapshot.appendSections([rowIndex])

      guard let row = coordinator?.row(at: rowIndex) else {
        IronLogger.ui.debug("Reload data: row not found, skipping", metadata: ["rowIndex": .int(rowIndex)])
        continue
      }

      let items = (0..<bodyColumnCount).map { columnIndex in
        IronDatabaseCellItem(columnIndex: columnIndex, rowIndex: rowIndex, rowID: row.id)
      }
      bodySnapshot.appendItems(items, toSection: rowIndex)
    }

    // Build selection snapshot (if visible)
    var selectionSnapshot: DiffableDataSourceSnapshot<Int, IronDatabaseCellItem>?
    if configuration.showsSelectionColumn {
      var snapshot = DiffableDataSourceSnapshot<Int, IronDatabaseCellItem>()

      for rowIndex in 0..<rowCount {
        snapshot.appendSections([rowIndex])

        guard let row = coordinator?.row(at: rowIndex) else {
          IronLogger.ui.debug("Reload data: row not found, skipping", metadata: ["rowIndex": .int(rowIndex)])
          continue
        }

        let item = IronDatabaseCellItem(columnIndex: 0, rowIndex: rowIndex, rowID: row.id)
        snapshot.appendItems([item], toSection: rowIndex)
      }

      selectionSnapshot = snapshot
    }

    // Apply both snapshots in a single Task to preserve ordering
    Task {
      await bodyDataSource?.applySnapshotUsingReloadData(bodySnapshot)
      if let selectionSnapshot {
        await selectionColumnDataSource?.applySnapshotUsingReloadData(selectionSnapshot)
      }
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

    selectionColumnDataSource = CollectionViewDiffableDataSource<Int, IronDatabaseCellItem>(
      collectionView: selectionColumnView
    ) { [weak self] collectionView, indexPath, item in
      guard let self else {
        IronLogger.ui.warning(
          "Selection column data source: container view deallocated during cell dequeue",
          metadata: ["section": .int(indexPath.section), "item": .int(indexPath.item)],
        )
        return UICollectionViewCell()
      }

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

    bodyDataSource = CollectionViewDiffableDataSource<Int, IronDatabaseCellItem>(
      collectionView: bodyCollectionView
    ) { [weak self] collectionView, indexPath, item in
      guard let self else {
        IronLogger.ui.warning(
          "Body data source: container view deallocated during cell dequeue",
          metadata: ["section": .int(indexPath.section), "item": .int(indexPath.item)],
        )
        return UICollectionViewCell()
      }

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

#endif
