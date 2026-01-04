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
    let previousDatabase = coordinator.configuration.database
    let previousSort = coordinator.configuration.sortState
    let previousFilter = coordinator.configuration.filterState

    // Update coordinator's configuration (single source of truth)
    coordinator.configuration = configuration

    // Detect changes
    let columnsChanged = previousDatabase.columns != configuration.database.columns
    let rowsChanged = previousDatabase.rows != configuration.database.rows
    let sortChanged = previousSort != configuration.sortState
    let filterChanged = previousFilter != configuration.filterState

    if columnsChanged {
      containerView.rebuildLayout()
    }

    if rowsChanged || sortChanged || filterChanged {
      coordinator.recomputeDisplayIndices()
      containerView.reloadData()
    }
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
  /// - Parameter column: The column to calculate width for.
  /// - Returns: The calculated width based on header text.
  func calculateFitHeaderWidth(for column: IronColumn) -> CGFloat {
    let font = UIFont.preferredFont(forTextStyle: .headline)
    let attributes: [NSAttributedString.Key: Any] = [.font: font]
    let size = (column.name as NSString).size(withAttributes: attributes)

    // Get padding from the width mode, or use default
    let padding: CGFloat =
      if case .fitHeader(let customPadding) = column.widthMode {
        customPadding
      } else {
        24
      }

    return ceil(size.width) + padding
  }

  /// Finds the column at a resize boundary for the given location.
  ///
  /// - Parameters:
  ///   - location: The point in the header scroll view's visible coordinate space.
  ///   - scrollView: The scroll view to get content offset from.
  /// - Returns: The column ID and current width if the location is on a resize boundary, nil otherwise.
  func columnAtResizeBoundary(location: CGPoint, in scrollView: UIScrollView?) -> (columnID: UUID, width: CGFloat)? {
    // Only detect boundaries in the header area (y within header height)
    guard location.y >= 0, location.y <= configuration.headerHeight else { return nil }

    // Convert from visible coordinates to content coordinates by adding scroll offset
    let scrollOffset = scrollView?.contentOffset.x ?? 0
    let contentX = location.x + scrollOffset

    // Use containerView's width calculation for consistency with layout
    guard let containerView else { return nil }

    var accumulatedX: CGFloat = 0

    // Account for selection column
    if configuration.showsSelectionColumn {
      accumulatedX += configuration.selectionColumnWidth
    }

    // Read columns fresh from the container's configuration (source of truth for layout)
    for column in containerView.configuration.database.columns {
      let columnWidth = containerView.effectiveColumnWidth(for: column)
      accumulatedX += columnWidth

      // Skip non-resizable columns for boundary detection
      guard column.isResizable else {
        continue
      }

      // Check if location is within resize handle zone
      if abs(contentX - accumulatedX) <= resizeHandleHalfWidth {
        return (column.id, columnWidth)
      }
    }

    return nil
  }

  func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    // In the row-based layout:
    // - indexPath.section = row index
    // - indexPath.item = column index within the row
    let rowIndex = indexPath.section
    let columnIndex = indexPath.item

    guard let row = row(at: rowIndex) else { return }

    let item = IronDatabaseCellItem(
      columnIndex: columnIndex,
      rowIndex: rowIndex,
      rowID: row.id,
    )

    // Handle cell tap based on column type
    let dataColumnIndex = columnIndex - (configuration.showsSelectionColumn ? 1 : 0)

    // Selection column tapped
    if configuration.showsSelectionColumn, columnIndex == 0 {
      toggleSelection(for: row.id)
      containerView?.reconfigureItem(item)
      return
    }

    guard dataColumnIndex >= 0, dataColumnIndex < configuration.database.columns.count else {
      return
    }

    let column = configuration.database.columns[dataColumnIndex]
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
      let translation = location.x - resizeState.dragStartX
      let constraints = (min: column.widthMode.minimumWidth, max: column.widthMode.maximumWidth)
      let newWidth = resizeState.newWidth(for: translation, constraints: constraints)

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

  /// Half-width of the resize hit zone on each side of column boundaries.
  /// This should match the visual resize handle width (44pt total = 22pt on each side).
  private let resizeHandleHalfWidth: CGFloat = 22

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

  /// Invalidates layout during live resize for smooth real-time feedback.
  /// This is lighter-weight than `rebuildLayout()` and avoids data source reloads.
  func invalidateLayoutForResize() {
    // Rebuild layouts with new column widths
    bodyCollectionView.setCollectionViewLayout(createBodyLayout(), animated: false)
    headerCollectionView.setCollectionViewLayout(createHeaderLayout(), animated: false)

    // Update header scroll view content width
    updateHeaderWidth()
  }

  func reloadData() {
    var snapshot = NSDiffableDataSourceSnapshot<Int, IronDatabaseCellItem>()

    // Calculate number of columns
    let columnCount =
      configuration.database.columns.count + (configuration.showsSelectionColumn ? 1 : 0)
        + (configuration.showsAddColumnButton ? 1 : 0)

    // Add sections for each ROW (not column)
    let rowCount = coordinator?.displayRowCount ?? 0

    for rowIndex in 0..<rowCount {
      snapshot.appendSections([rowIndex])

      guard let row = coordinator?.row(at: rowIndex) else { continue }

      // Add items for each column in this row
      let items = (0..<columnCount).map { columnIndex in
        IronDatabaseCellItem(columnIndex: columnIndex, rowIndex: rowIndex, rowID: row.id)
      }
      snapshot.appendItems(items, toSection: rowIndex)
    }

    bodyDataSource?.apply(snapshot, animatingDifferences: true)

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
    if
      let oldCell = coordinator.editingCell,
      let displayIndex = coordinator.displayIndex(for: oldCell.rowID),
      let dataColumnIndex = configuration.database.columns.firstIndex(where: { $0.id == oldCell.columnID })
    {
      let columnIndex = dataColumnIndex + (configuration.showsSelectionColumn ? 1 : 0)
      itemsToReconfigure.append(IronDatabaseCellItem(
        columnIndex: columnIndex,
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
      let columnIndex = dataColumnIndex + (configuration.showsSelectionColumn ? 1 : 0)
      let newItem = IronDatabaseCellItem(
        columnIndex: columnIndex,
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

  private lazy var bodyCollectionView: UICollectionView = {
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createBodyLayout())
    collectionView.backgroundColor = .clear
    collectionView.showsHorizontalScrollIndicator = true
    collectionView.showsVerticalScrollIndicator = true
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    // Note: No register() calls needed - using modern CellRegistration API
    return collectionView
  }()

  private var bodyDataSource: UICollectionViewDiffableDataSource<Int, IronDatabaseCellItem>?
  private var headerWidthConstraint: NSLayoutConstraint?

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

    let dataColumnIndex = item.columnIndex - (configuration.showsSelectionColumn ? 1 : 0)
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

        // In fullRowTap or both mode, single tap toggles selection
        if
          configuration.rowSelectionMode == .fullRowTap
          || configuration.rowSelectionMode == .both
        {
          IronHaptics.selection()
          coordinator?.toggleSelection(for: row.id)
          reconfigureItem(item)
          return
        }

        // In checkboxOnly mode, tap starts editing (except for checkboxes)
        if column.type != .checkbox {
          IronHaptics.tap()
          // Use setEditingCell to reconfigure both old and new cells
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

    let columnIndex = sectionIndex - (configuration.showsSelectionColumn ? 1 : 0)
    guard columnIndex >= 0, columnIndex < configuration.database.columns.count else { return }

    let column = configuration.database.columns[columnIndex]
    let isSorted = configuration.sortState?.columnID == column.id
    let sortDirection = isSorted ? configuration.sortState?.direction : nil
    let isFiltered = configuration.filterState.filters[column.id] != nil

    let currentFilter = configuration.filterState.filters[column.id]

    cell.configure(
      column: column,
      isSorted: isSorted,
      sortDirection: sortDirection,
      isFiltered: isFiltered,
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
      isResizable: column.isResizable,
      onAdjustWidth: column.isResizable
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
      onResetWidth: column.isResizable
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

  /// Calculates total content width based on all columns.
  private var totalContentWidth: CGFloat {
    var width: CGFloat = 0

    if configuration.showsSelectionColumn {
      width += configuration.selectionColumnWidth
    }

    for column in configuration.database.columns {
      width += effectiveColumnWidth(for: column)
    }

    if configuration.showsAddColumnButton {
      width += 44
    }

    return max(width, bounds.width)
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

    // Body
    addSubview(bodyCollectionView)

    // Create header width constraint (will be updated in layoutSubviews)
    headerWidthConstraint = headerCollectionView.widthAnchor.constraint(equalToConstant: 1000)

    NSLayoutConstraint.activate([
      // Header scroll view
      headerScrollView.topAnchor.constraint(equalTo: topAnchor),
      headerScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
      headerScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
      headerScrollView.heightAnchor.constraint(equalToConstant: configuration.headerHeight),

      // Header collection view (inside scroll view)
      headerCollectionView.topAnchor.constraint(equalTo: headerScrollView.topAnchor),
      headerCollectionView.leadingAnchor.constraint(equalTo: headerScrollView.leadingAnchor),
      headerCollectionView.bottomAnchor.constraint(equalTo: headerScrollView.bottomAnchor),
      headerCollectionView.heightAnchor.constraint(equalToConstant: configuration.headerHeight),
      headerWidthConstraint!,

      // Body collection view
      bodyCollectionView.topAnchor.constraint(equalTo: headerScrollView.bottomAnchor),
      bodyCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
      bodyCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
      bodyCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    // Sync horizontal scroll
    bodyCollectionView.delegate = self

    // Setup data sources
    setupHeaderDataSource()
    setupBodyDataSource()

    // Setup resize gesture recognizer
    setupResizeGesture()
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

  private func setupBodyDataSource() {
    // Create registrations upfront by accessing the lazy properties
    // This is required per Apple's documentation for iOS 15+
    _ = selectionCellRegistration
    _ = dataCellRegistration
    _ = emptyBodyCellRegistration

    bodyDataSource = UICollectionViewDiffableDataSource<Int, IronDatabaseCellItem>(
      collectionView: bodyCollectionView
    ) { [weak self] collectionView, indexPath, item in
      guard let self else { return UICollectionViewCell() }

      // Selection column - use selection cell registration
      if configuration.showsSelectionColumn, item.columnIndex == 0 {
        return collectionView.dequeueConfiguredReusableCell(
          using: selectionCellRegistration,
          for: indexPath,
          item: item,
        )
      }

      // Calculate the add column index (last column when add button is shown)
      let addColumnIndex = configuration.database.columns.count + (configuration.showsSelectionColumn ? 1 : 0)

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

    // Selection column
    if configuration.showsSelectionColumn, sectionIndex == 0 {
      columnWidth = configuration.selectionColumnWidth
    } else {
      let dataColumnIndex = sectionIndex - (configuration.showsSelectionColumn ? 1 : 0)
      if dataColumnIndex >= 0, dataColumnIndex < configuration.database.columns.count {
        let column = configuration.database.columns[dataColumnIndex]
        columnWidth = effectiveColumnWidth(for: column)
      } else {
        // Add column button
        columnWidth = 44
      }
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
  /// Each row section contains items for all columns laid out horizontally.
  /// The section's width exceeds the viewport to enable horizontal scrolling.
  private func createRowSection() -> NSCollectionLayoutSection {
    // Build items for each column
    var items = [NSCollectionLayoutItem]()

    // Selection column (if shown)
    if configuration.showsSelectionColumn {
      let selectionItem = NSCollectionLayoutItem(
        layoutSize: NSCollectionLayoutSize(
          widthDimension: .absolute(configuration.selectionColumnWidth),
          heightDimension: .absolute(configuration.rowHeight),
        )
      )
      items.append(selectionItem)
    }

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
        widthDimension: .absolute(totalContentWidth),
        heightDimension: .absolute(configuration.rowHeight),
      ),
      subitems: items,
    )

    return NSCollectionLayoutSection(group: group)
  }
}

// MARK: - UIScrollViewDelegate

extension IronDatabaseTableContainerView: UICollectionViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView === bodyCollectionView {
      // Sync header horizontal scroll with body
      headerScrollView.contentOffset.x = scrollView.contentOffset.x
    }
  }
}

// MARK: - UICollectionViewDataSource for Header

extension IronDatabaseTableContainerView: UICollectionViewDataSource {
  func numberOfSections(in _: UICollectionView) -> Int {
    configuration.database.columns.count + (configuration.showsSelectionColumn ? 1 : 0)
      + (configuration.showsAddColumnButton ? 1 : 0)
  }

  func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
    1 // Header has one item per section
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath,
  ) -> UICollectionViewCell {
    let sectionIndex = indexPath.section

    // Selection column header (empty) - use empty registration
    if configuration.showsSelectionColumn, sectionIndex == 0 {
      return collectionView.dequeueConfiguredReusableCell(
        using: emptyHeaderCellRegistration,
        for: indexPath,
        item: sectionIndex,
      )
    }

    // Check if this is the add column button section
    let columnIndex = sectionIndex - (configuration.showsSelectionColumn ? 1 : 0)
    guard columnIndex >= 0, columnIndex < configuration.database.columns.count else {
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
      Button(action: onToggle) {
        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
          .foregroundStyle(isSelected ? .blue : .secondary)
      }
      .buttonStyle(.plain)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .accessibilityLabel("Select row \(rowNumber)")
      .accessibilityValue(isSelected ? "Selected" : "Not selected")
      .accessibilityAddTraits(.isButton)
    }
    .background(.clear)
  }
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
    // Main header content with Menu
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
    } primaryAction: {
      // Single tap triggers sort for quick access (only if sortable)
      if column.isSortable {
        onSort()
      }
    }
    .accessibilityLabel(accessibilityLabel)
    .accessibilityHint(accessibilityHint)
    // Resize handle overlays the trailing edge, centered on column boundary
    .overlay(alignment: .trailing) {
      if isResizable {
        resizeHandle
          .offset(x: 22) // Center the 44pt handle on the column boundary
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

      Spacer(minLength: 4)

      if isFiltered {
        Image(systemName: "line.3.horizontal.decrease.circle.fill")
          .foregroundStyle(.blue)
          .font(.caption)
      }

      if isSorted, let direction = sortDirection {
        Image(systemName: direction.iconName)
          .foregroundStyle(.blue)
          .font(.caption)
      }
    }
    .padding(.horizontal, 8)
    .frame(maxHeight: .infinity)
    .contentShape(Rectangle())
  }

  /// Visual resize handle shown at the right edge of resizable columns.
  /// Placed OUTSIDE the Menu to receive pan gesture events.
  /// Uses 44pt minimum touch target for accessibility compliance.
  private var resizeHandle: some View {
    Rectangle()
      .fill(theme.colors.border)
      .frame(width: 1)
      .padding(.vertical, 6)
      .frame(width: 44) // 44pt minimum touch target
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
