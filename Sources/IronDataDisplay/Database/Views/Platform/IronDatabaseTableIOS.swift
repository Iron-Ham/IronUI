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

    // Update configuration
    coordinator.configuration = configuration
    containerView.configuration = configuration

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

  weak var containerView: IronDatabaseTableContainerView?

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
}

// MARK: - IronDatabaseTableContainerView

/// Container view that holds the header and body collection views.
final class IronDatabaseTableContainerView: UIView {

  // MARK: Lifecycle

  init(configuration: IronDatabaseTableConfiguration) {
    self.configuration = configuration
    super.init(frame: .zero)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  var configuration: IronDatabaseTableConfiguration
  weak var coordinator: IronDatabaseIOSCoordinator?

  override func layoutSubviews() {
    super.layoutSubviews()
    updateHeaderWidth()
  }

  func rebuildLayout() {
    bodyCollectionView.setCollectionViewLayout(createBodyLayout(), animated: false)
    headerCollectionView.setCollectionViewLayout(createHeaderLayout(), animated: false)
    reloadData()
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

  // MARK: Private

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
        guard let self else { return }
        IronHaptics.selection()
        // Update the configuration's sort state via binding
        configuration.toggleSort(for: column.id)
        // Sync coordinator's configuration with updated sort state
        coordinator?.configuration = configuration
        coordinator?.recomputeDisplayIndices()
        reloadData()
      },
      onSortAscending: { [weak self] in
        guard let self else { return }
        configuration.sortState = IronDatabaseSortState(columnID: column.id, direction: .ascending)
        coordinator?.configuration = configuration
        coordinator?.recomputeDisplayIndices()
        reloadData()
      },
      onSortDescending: { [weak self] in
        guard let self else { return }
        configuration.sortState = IronDatabaseSortState(columnID: column.id, direction: .descending)
        coordinator?.configuration = configuration
        coordinator?.recomputeDisplayIndices()
        reloadData()
      },
      onClearSort: { [weak self] in
        guard let self else { return }
        configuration.sortState = nil
        coordinator?.configuration = configuration
        coordinator?.recomputeDisplayIndices()
        reloadData()
      },
      currentFilter: currentFilter,
      onApplyFilter: { [weak self] newFilter in
        guard let self else { return }
        if let newFilter {
          configuration.filterState.filters[column.id] = newFilter
          IronHaptics.impact(.medium)
        } else {
          configuration.filterState.filters.removeValue(forKey: column.id)
          IronHaptics.impact(.light)
        }
        coordinator?.configuration = configuration
        coordinator?.recomputeDisplayIndices()
        reloadData()
      },
      onClearFilter: { [weak self] in
        guard let self else { return }
        configuration.filterState.filters.removeValue(forKey: column.id)
        coordinator?.configuration = configuration
        coordinator?.recomputeDisplayIndices()
        reloadData()
      },
    )
  }

  /// Calculates total content width based on all columns.
  private var totalContentWidth: CGFloat {
    var width: CGFloat = 0

    if configuration.showsSelectionColumn {
      width += configuration.selectionColumnWidth
    }

    for column in configuration.database.columns {
      width += column.width ?? column.resolvedWidth
    }

    if configuration.showsAddColumnButton {
      width += 44
    }

    return max(width, bounds.width)
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
        columnWidth = column.width ?? column.resolvedWidth
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
      let columnWidth = column.width ?? column.resolvedWidth
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
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
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

  var body: some View {
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
      headerLabel
    } primaryAction: {
      // Single tap triggers sort for quick access (only if sortable)
      if column.isSortable {
        onSort()
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityLabel)
    .accessibilityHint(column.isSortable ? "Tap to sort, hold for more options" : "Hold for options")
    .accessibilityAddTraits(.isButton)
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

  private var headerLabel: some View {
    HStack(spacing: 4) {
      Image(systemName: column.type.iconName)
        .foregroundStyle(.secondary)
        .font(.caption)

      Text(column.name)
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)
        .lineLimit(2)
        .minimumScaleFactor(0.8)

      Spacer()

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

  private var accessibilityLabel: String {
    var parts = ["\(column.name) column", "\(column.type.displayName) type"]

    if isSorted, let direction = sortDirection {
      parts.append(direction.accessibilityLabel)
    }

    if isFiltered {
      parts.append("Filtered")
    }

    return parts.joined(separator: ", ")
  }

}

#endif
