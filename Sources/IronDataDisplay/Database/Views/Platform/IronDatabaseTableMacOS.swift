#if os(macOS)
import AppKit
import IronCore
import IronPrimitives
import SwiftUI

// MARK: - IronDatabaseTableMacOS

/// macOS implementation of `IronDatabaseTable` using `NSTableView`.
///
/// This view wraps an `NSTableView` for optimal performance with large
/// datasets while maintaining full integration with SwiftUI and IronUI theming.
struct IronDatabaseTableMacOS: NSViewRepresentable {

  // MARK: Lifecycle

  init(configuration: IronDatabaseTableConfiguration) {
    self.configuration = configuration
  }

  // MARK: Internal

  let configuration: IronDatabaseTableConfiguration

  func makeNSView(context: Context) -> NSScrollView {
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = true
    scrollView.autohidesScrollers = true
    scrollView.borderType = .noBorder
    scrollView.drawsBackground = false

    let tableView = IronDatabaseNSTableView()
    tableView.style = .plain
    tableView.allowsMultipleSelection = configuration.allowsMultipleSelection
    tableView.allowsColumnReordering = configuration.allowsColumnReordering
    tableView.allowsColumnResizing = configuration.allowsColumnResizing
    tableView.allowsColumnSelection = false
    tableView.rowHeight = configuration.rowHeight
    tableView.intercellSpacing = NSSize(width: 0, height: 1)
    tableView.gridStyleMask = []
    tableView.headerView = IronDatabaseNSHeaderView()
    tableView.backgroundColor = .clear

    // Selection column
    if configuration.showsSelectionColumn {
      let selectionColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("selection"))
      selectionColumn.title = ""
      selectionColumn.width = configuration.selectionColumnWidth
      selectionColumn.minWidth = configuration.selectionColumnWidth
      selectionColumn.maxWidth = configuration.selectionColumnWidth
      selectionColumn.isEditable = false
      selectionColumn.resizingMask = []
      tableView.addTableColumn(selectionColumn)
    }

    // Data columns
    for column in configuration.database.columns {
      let tableColumn = createTableColumn(for: column)
      tableView.addTableColumn(tableColumn)
    }

    // Add column button column (if applicable)
    if configuration.showsAddColumnButton {
      let addColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("addColumn"))
      addColumn.title = ""
      addColumn.width = 44
      addColumn.minWidth = 44
      addColumn.maxWidth = 44
      addColumn.isEditable = false
      addColumn.resizingMask = []
      tableView.addTableColumn(addColumn)
    }

    tableView.delegate = context.coordinator
    tableView.dataSource = context.coordinator

    scrollView.documentView = tableView

    context.coordinator.tableView = tableView
    context.coordinator.scrollView = scrollView

    return scrollView
  }

  func updateNSView(_ scrollView: NSScrollView, context: Context) {
    guard let tableView = scrollView.documentView as? IronDatabaseNSTableView else {
      return
    }

    let coordinator = context.coordinator
    let previousDatabase = coordinator.configuration.database
    let previousSort = coordinator.configuration.sortState
    let previousFilter = coordinator.configuration.filterState

    // Update configuration
    coordinator.configuration = configuration

    // Detect changes
    let columnsChanged = previousDatabase.columns != configuration.database.columns
    let rowsChanged = previousDatabase.rows != configuration.database.rows
    let sortChanged = previousSort != configuration.sortState
    let filterChanged = previousFilter != configuration.filterState

    if columnsChanged {
      syncColumns(tableView: tableView, coordinator: coordinator)
    }

    if rowsChanged || sortChanged || filterChanged {
      coordinator.recomputeDisplayIndices()
      tableView.reloadData()
    }

    // Sync selection
    syncSelection(tableView: tableView, coordinator: coordinator)
  }

  func makeCoordinator() -> IronDatabaseMacOSCoordinator {
    IronDatabaseMacOSCoordinator(configuration: configuration)
  }

  // MARK: Private

  private func createTableColumn(for column: IronColumn) -> NSTableColumn {
    let tableColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(column.id.uuidString))
    tableColumn.title = column.name
    tableColumn.width = column.width ?? column.resolvedWidth
    tableColumn.minWidth = column.widthMode.minimumWidth
    if let maxWidth = column.widthMode.maximumWidth {
      tableColumn.maxWidth = maxWidth
    }
    tableColumn.isEditable = false

    if column.isResizable {
      tableColumn.resizingMask = [.autoresizingMask, .userResizingMask]
    } else {
      tableColumn.resizingMask = []
    }

    // Sort indicator
    if column.isSortable {
      tableColumn.sortDescriptorPrototype = NSSortDescriptor(
        key: column.id.uuidString,
        ascending: true,
      )
    }

    return tableColumn
  }

  private func syncColumns(tableView: NSTableView, coordinator _: IronDatabaseMacOSCoordinator) {
    // Remove all columns except selection and add button
    let columnsToRemove = tableView.tableColumns.filter { column in
      column.identifier.rawValue != "selection" && column.identifier.rawValue != "addColumn"
    }
    for column in columnsToRemove {
      tableView.removeTableColumn(column)
    }

    // Find insertion index (after selection column if present)
    var insertIndex = configuration.showsSelectionColumn ? 1 : 0

    // Add data columns
    for column in configuration.database.columns {
      let tableColumn = createTableColumn(for: column)
      tableView.addTableColumn(tableColumn)
      // Move to correct position
      if let currentIndex = tableView.tableColumns.firstIndex(of: tableColumn) {
        tableView.moveColumn(currentIndex, toColumn: insertIndex)
      }
      insertIndex += 1
    }
  }

  private func syncSelection(tableView: NSTableView, coordinator: IronDatabaseMacOSCoordinator) {
    let currentSelection = tableView.selectedRowIndexes

    // Build expected selection
    var expectedSelection = IndexSet()
    for rowID in configuration.selection {
      if let displayIndex = coordinator.displayIndex(for: rowID) {
        expectedSelection.insert(displayIndex)
      }
    }

    if currentSelection != expectedSelection {
      tableView.selectRowIndexes(expectedSelection, byExtendingSelection: false)
    }
  }
}

// MARK: - IronDatabaseMacOSCoordinator

/// Coordinator for the macOS table view.
@MainActor
final class IronDatabaseMacOSCoordinator: IronDatabaseTableCoordinatorBase, NSTableViewDelegate, NSTableViewDataSource {

  // MARK: Internal

  weak var tableView: IronDatabaseNSTableView?
  weak var scrollView: NSScrollView?

  func numberOfRows(in _: NSTableView) -> Int {
    displayRowCount
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let tableColumn else { return nil }
    guard let ironRow = self.row(at: row) else { return nil }

    let identifier = tableColumn.identifier

    // Selection column
    if identifier.rawValue == "selection" {
      return makeSelectionCell(for: ironRow, in: tableView)
    }

    // Add column button (in header only, cells are empty)
    if identifier.rawValue == "addColumn" {
      return nil
    }

    // Data column
    guard
      let columnID = UUID(uuidString: identifier.rawValue),
      let column = configuration.database.column(columnID)
    else {
      return nil
    }

    return makeDataCell(for: ironRow, column: column, in: tableView)
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    guard let tableView = notification.object as? NSTableView else { return }

    // Update selection binding
    var newSelection = Set<IronRow.ID>()
    for displayIndex in tableView.selectedRowIndexes {
      if let row = row(at: displayIndex) {
        newSelection.insert(row.id)
      }
    }

    configuration.selection = newSelection
  }

  func tableView(_: NSTableView, shouldSelectRow _: Int) -> Bool {
    true
  }

  func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
    // Handle sort click
    guard
      let columnID = UUID(uuidString: tableColumn.identifier.rawValue),
      let column = configuration.database.column(columnID),
      column.isSortable
    else {
      return
    }

    configuration.toggleSort(for: columnID)
    recomputeDisplayIndices()
    tableView.reloadData()

    // Update sort indicators
    updateSortIndicators(in: tableView)
  }

  func tableViewColumnDidResize(_ notification: Notification) {
    guard
      let tableColumn = notification.userInfo?["NSTableColumn"] as? NSTableColumn,
      let columnID = UUID(uuidString: tableColumn.identifier.rawValue),
      let columnIndex = configuration.database.columns.firstIndex(where: { $0.id == columnID })
    else {
      return
    }

    // Update column width in database
    configuration.database.columns[columnIndex].width = tableColumn.width
  }

  // MARK: Private

  private func makeSelectionCell(for row: IronRow, in tableView: NSTableView) -> NSView {
    let identifier = NSUserInterfaceItemIdentifier("SelectionCell")
    let cell =
      tableView.makeView(withIdentifier: identifier, owner: nil) as? IronDatabaseNSSelectionCell
        ?? IronDatabaseNSSelectionCell()
    cell.identifier = identifier

    let isSelected = configuration.selection.contains(row.id)
    cell.configure(isSelected: isSelected) { [weak self] in
      self?.toggleSelection(for: row.id)
      tableView.reloadData(forRowIndexes: IndexSet(integer: tableView.row(for: cell)), columnIndexes: IndexSet(integer: 0))
    }

    return cell
  }

  private func makeDataCell(for row: IronRow, column: IronColumn, in tableView: NSTableView) -> NSView {
    let identifier = NSUserInterfaceItemIdentifier("DataCell-\(column.id.uuidString)")
    let cell =
      tableView.makeView(withIdentifier: identifier, owner: nil) as? IronDatabaseNSDataCell
        ?? IronDatabaseNSDataCell()
    cell.identifier = identifier

    let isEditing = editingCell?.rowID == row.id && editingCell?.columnID == column.id
    let valueBinding = cellValueBinding(row: row.id, column: column.id)

    cell.configure(
      column: column,
      value: valueBinding,
      isEditing: isEditing,
      onTap: { [weak self] in
        if column.type != .checkbox {
          self?.editingCell = CellIdentifier(rowID: row.id, columnID: column.id)
          tableView.reloadData()
        }
      },
      onSubmit: { [weak self] in
        self?.editingCell = nil
        tableView.reloadData()
      },
    )

    return cell
  }

  private func updateSortIndicators(in tableView: NSTableView) {
    for tableColumn in tableView.tableColumns {
      guard let columnID = UUID(uuidString: tableColumn.identifier.rawValue) else {
        tableView.setIndicatorImage(nil, in: tableColumn)
        continue
      }

      if configuration.sortState?.columnID == columnID {
        let imageName =
          configuration.sortState?.direction == .ascending
            ? "NSAscendingSortIndicator"
            : "NSDescendingSortIndicator"
        tableView.setIndicatorImage(NSImage(named: NSImage.Name(imageName)), in: tableColumn)
      } else {
        tableView.setIndicatorImage(nil, in: tableColumn)
      }
    }
  }
}

// MARK: - IronDatabaseNSTableView

/// Custom NSTableView subclass for IronDatabaseTable.
final class IronDatabaseNSTableView: NSTableView {
  // Add any custom table view behavior here
}

// MARK: - IronDatabaseNSHeaderView

/// Custom header view for the table.
final class IronDatabaseNSHeaderView: NSTableHeaderView {
  // Add any custom header behavior here
}

// MARK: - IronDatabaseNSSelectionCell

/// Cell view for the selection checkbox.
final class IronDatabaseNSSelectionCell: NSTableCellView {

  // MARK: Lifecycle

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  func configure(isSelected: Bool, onToggle: @escaping () -> Void) {
    self.isSelected = isSelected
    self.onToggle = onToggle
    updateAppearance()
  }

  // MARK: Private

  private var isSelected = false
  private var onToggle: (() -> Void)?
  private lazy var checkbox: NSButton = {
    let button = NSButton(checkboxWithTitle: "", target: self, action: #selector(checkboxClicked))
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()

  private func setupViews() {
    addSubview(checkbox)
    NSLayoutConstraint.activate([
      checkbox.centerXAnchor.constraint(equalTo: centerXAnchor),
      checkbox.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  private func updateAppearance() {
    checkbox.state = isSelected ? .on : .off
  }

  @objc
  private func checkboxClicked() {
    onToggle?()
  }
}

// MARK: - IronDatabaseNSDataCell

/// Cell view for data cells, hosting SwiftUI content.
final class IronDatabaseNSDataCell: NSTableCellView {

  // MARK: Lifecycle

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
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
    let cellView = AnyView(
      IronDatabaseCell(column: column, value: value, isEditing: isEditing)
        .onSubmit { onSubmit() }
    )

    // Reuse existing hosting view for better performance
    if let existingHosting = hostingView {
      existingHosting.rootView = cellView
    } else {
      let hosting = NSHostingView(rootView: cellView)
      hosting.translatesAutoresizingMaskIntoConstraints = false
      addSubview(hosting)

      NSLayoutConstraint.activate([
        hosting.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
        hosting.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        hosting.topAnchor.constraint(equalTo: topAnchor),
        hosting.bottomAnchor.constraint(equalTo: bottomAnchor),
      ])

      // Add click gesture only once
      let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick))
      hosting.addGestureRecognizer(clickGesture)

      hostingView = hosting
    }

    self.onTap = onTap
  }

  // MARK: Private

  private var hostingView: NSHostingView<AnyView>?
  private var onTap: (() -> Void)?

  @objc
  private func handleClick() {
    onTap?()
  }
}

#endif
