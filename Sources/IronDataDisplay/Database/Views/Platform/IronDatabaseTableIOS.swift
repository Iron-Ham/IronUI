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
/// The `rowID` is included to ensure diffable data source detects changes
/// when row order changes due to sorting - items with the same display index
/// but different row IDs will be treated as different items.
struct IronDatabaseCellItem: Hashable {
  let sectionIndex: Int
  let rowIndex: Int
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
    guard let row = row(at: indexPath.item) else { return }

    let item = IronDatabaseCellItem(
      sectionIndex: indexPath.section,
      rowIndex: indexPath.item,
      rowID: row.id,
    )

    // Handle cell tap for editing
    let columnIndex = indexPath.section - (configuration.showsSelectionColumn ? 1 : 0)
    guard columnIndex >= 0, columnIndex < configuration.database.columns.count else {
      // Selection column tapped
      if configuration.showsSelectionColumn, indexPath.section == 0 {
        toggleSelection(for: row.id)
        containerView?.reconfigureItem(item)
      }
      return
    }

    let column = configuration.database.columns[columnIndex]
    if column.type != .checkbox {
      editingCell = CellIdentifier(rowID: row.id, columnID: column.id)
      containerView?.reconfigureItem(item)
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

    // Add sections for each column
    let sectionCount =
      configuration.database.columns.count + (configuration.showsSelectionColumn ? 1 : 0)
        + (configuration.showsAddColumnButton ? 1 : 0)

    for section in 0..<sectionCount {
      snapshot.appendSections([section])

      // Add items for each row, including rowID so diffable data source
      // detects changes when sort order changes
      let itemCount = coordinator?.displayRowCount ?? 0
      let items = (0..<itemCount).compactMap { displayIndex -> IronDatabaseCellItem? in
        guard let row = coordinator?.row(at: displayIndex) else { return nil }
        return IronDatabaseCellItem(sectionIndex: section, rowIndex: displayIndex, rowID: row.id)
      }
      snapshot.appendItems(items, toSection: section)
    }

    bodyDataSource?.apply(snapshot, animatingDifferences: false)

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
    bodyDataSource?.apply(snapshot, animatingDifferences: false)
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
    cell.configure(isSelected: isSelected) { [weak self, weak coordinator] in
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

    let columnIndex = item.sectionIndex - (configuration.showsSelectionColumn ? 1 : 0)
    guard columnIndex >= 0, columnIndex < configuration.database.columns.count else { return }

    let column = configuration.database.columns[columnIndex]
    let isEditing =
      coordinator.editingCell?.rowID == row.id && coordinator.editingCell?.columnID == column.id
    let valueBinding = coordinator.cellValueBinding(row: row.id, column: column.id)

    cell.configure(
      column: column,
      value: valueBinding,
      isEditing: isEditing,
      onTap: { [weak self, weak coordinator] in
        if column.type != .checkbox {
          coordinator?.editingCell = CellIdentifier(rowID: row.id, columnID: column.id)
          self?.reconfigureItem(item)
        }
      },
      onSubmit: { [weak self, weak coordinator] in
        coordinator?.editingCell = nil
        self?.reconfigureItem(item)
      },
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

    cell.configure(
      column: column,
      isSorted: isSorted,
      sortDirection: sortDirection,
      isFiltered: isFiltered,
      onSort: { [weak self] in
        guard let self else { return }
        // Update the configuration's sort state via binding
        configuration.toggleSort(for: column.id)
        // Sync coordinator's configuration with updated sort state
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
      if configuration.showsSelectionColumn, item.sectionIndex == 0 {
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
        return createColumnSection(at: sectionIndex, isHeader: true)
      },
      configuration: config,
    )
  }

  private func createBodyLayout() -> UICollectionViewLayout {
    let config = UICollectionViewCompositionalLayoutConfiguration()
    config.scrollDirection = .horizontal

    return UICollectionViewCompositionalLayout(
      sectionProvider: { [weak self] sectionIndex, _ in
        guard let self else { return nil }
        return createColumnSection(at: sectionIndex, isHeader: false)
      },
      configuration: config,
    )
  }

  private func createColumnSection(at sectionIndex: Int, isHeader: Bool) -> NSCollectionLayoutSection {
    // Selection column
    if configuration.showsSelectionColumn, sectionIndex == 0 {
      let itemSize = NSCollectionLayoutSize(
        widthDimension: .absolute(configuration.selectionColumnWidth),
        heightDimension: .absolute(isHeader ? configuration.headerHeight : configuration.rowHeight),
      )
      let item = NSCollectionLayoutItem(layoutSize: itemSize)

      let groupSize = NSCollectionLayoutSize(
        widthDimension: .absolute(configuration.selectionColumnWidth),
        heightDimension: isHeader ? .absolute(configuration.headerHeight) : .estimated(1000),
      )
      let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

      let section = NSCollectionLayoutSection(group: group)
      section.orthogonalScrollingBehavior = isHeader ? .none : .continuous
      return section
    }

    // Data column
    let columnIndex = sectionIndex - (configuration.showsSelectionColumn ? 1 : 0)
    guard columnIndex >= 0, columnIndex < configuration.database.columns.count else {
      // Add column button section
      let itemSize = NSCollectionLayoutSize(
        widthDimension: .absolute(44),
        heightDimension: .absolute(isHeader ? configuration.headerHeight : configuration.rowHeight),
      )
      let item = NSCollectionLayoutItem(layoutSize: itemSize)
      let group = NSCollectionLayoutGroup.vertical(
        layoutSize: NSCollectionLayoutSize(
          widthDimension: .absolute(44),
          heightDimension: .estimated(1000),
        ),
        subitems: [item],
      )
      return NSCollectionLayoutSection(group: group)
    }

    let column = configuration.database.columns[columnIndex]
    let columnWidth = column.width ?? column.resolvedWidth

    let itemSize = NSCollectionLayoutSize(
      widthDimension: .absolute(columnWidth),
      heightDimension: .absolute(isHeader ? configuration.headerHeight : configuration.rowHeight),
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .absolute(columnWidth),
      heightDimension: isHeader ? .absolute(configuration.headerHeight) : .estimated(1000),
    )
    let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

    let section = NSCollectionLayoutSection(group: group)
    section.orthogonalScrollingBehavior = isHeader ? .none : .continuous
    return section
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

/// Collection view cell for header items.
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
    hostingController?.view.removeFromSuperview()
    hostingController = nil
  }

  func configureAddButton(onTap: @escaping () -> Void) {
    hostingController?.view.removeFromSuperview()

    let view = AnyView(
      Button(action: onTap) {
        Image(systemName: "plus")
          .foregroundStyle(.secondary)
      }
      .buttonStyle(.plain)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    )

    let controller = UIHostingController(rootView: view)
    controller.view.backgroundColor = .clear
    controller.view.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(controller.view)

    NSLayoutConstraint.activate([
      controller.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      controller.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      controller.view.topAnchor.constraint(equalTo: contentView.topAnchor),
      controller.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    hostingController = controller
  }

  func configure(
    column: IronColumn,
    isSorted: Bool,
    sortDirection: IronDatabaseSortState.SortDirection?,
    isFiltered: Bool,
    onSort: @escaping () -> Void,
  ) {
    hostingController?.view.removeFromSuperview()

    let headerView = AnyView(
      IronDatabaseHeaderCellContent(
        column: column,
        isSorted: isSorted,
        sortDirection: sortDirection,
        isFiltered: isFiltered,
        onSort: onSort,
      )
    )

    let controller = UIHostingController(rootView: headerView)
    controller.view.backgroundColor = .clear
    controller.view.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(controller.view)

    NSLayoutConstraint.activate([
      controller.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      controller.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      controller.view.topAnchor.constraint(equalTo: contentView.topAnchor),
      controller.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    hostingController = controller
  }

  // MARK: Private

  private var hostingController: UIHostingController<AnyView>?
}

// MARK: - IronDatabaseDataCollectionCell

/// Collection view cell for data items.
final class IronDatabaseDataCollectionCell: UICollectionViewCell {

  // MARK: Lifecycle

  override init(frame: CGRect) {
    super.init(frame: frame)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  func configure(
    column: IronColumn,
    value: Binding<IronCellValue>,
    isEditing: Bool,
    onTap: @escaping () -> Void,
    onSubmit: @escaping () -> Void,
  ) {
    hostingController?.view.removeFromSuperview()

    let cellView = AnyView(
      IronDatabaseCell(column: column, value: value, isEditing: isEditing)
        .onSubmit { onSubmit() }
        .onTapGesture { onTap() }
    )

    let controller = UIHostingController(rootView: cellView)
    controller.view.backgroundColor = .clear
    controller.view.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(controller.view)

    NSLayoutConstraint.activate([
      controller.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
      controller.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
      controller.view.topAnchor.constraint(equalTo: contentView.topAnchor),
      controller.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    hostingController = controller
  }

  // MARK: Private

  private var hostingController: UIHostingController<AnyView>?
}

// MARK: - IronDatabaseSelectionCollectionCell

/// Collection view cell for selection checkboxes.
final class IronDatabaseSelectionCollectionCell: UICollectionViewCell {

  // MARK: Lifecycle

  override init(frame: CGRect) {
    super.init(frame: frame)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  func configure(isSelected: Bool, onToggle: @escaping () -> Void) {
    hostingController?.view.removeFromSuperview()

    let view = Button(action: onToggle) {
      Image(systemName: isSelected ? "checkmark.square.fill" : "square")
        .foregroundStyle(isSelected ? .blue : .secondary)
    }
    .buttonStyle(.plain)
    .frame(maxWidth: .infinity, maxHeight: .infinity)

    let controller = UIHostingController(rootView: AnyView(view))
    controller.view.backgroundColor = .clear
    controller.view.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(controller.view)

    NSLayoutConstraint.activate([
      controller.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      controller.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      controller.view.topAnchor.constraint(equalTo: contentView.topAnchor),
      controller.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    hostingController = controller
  }

  // MARK: Private

  private var hostingController: UIHostingController<AnyView>?
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

  var body: some View {
    Button(action: onSort) {
      HStack(spacing: 4) {
        Image(systemName: column.type.iconName)
          .foregroundStyle(.secondary)
          .font(.caption)

        Text(column.name)
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)
          .lineLimit(1)

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
    }
    .buttonStyle(.plain)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

}

#endif
