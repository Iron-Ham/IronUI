import IronCore
import IronPrimitives
import SwiftUI

// MARK: - IronDatabaseHeaderCell

/// A header cell for an `IronDatabaseTable` column.
///
/// Displays the column icon, name, sort indicator, and filter indicator.
/// Supports tap-to-sort and context menu for column actions.
///
/// ## Usage
///
/// ```swift
/// IronDatabaseHeaderCell(
///   column: column,
///   isSorted: true,
///   sortDirection: .ascending,
///   isFiltered: false,
///   onSort: { toggleSort(column.id) },
///   onFilter: { showFilter(column.id) },
///   onRename: { showRename(column.id) },
///   onDelete: { deleteColumn(column.id) }
/// )
/// ```
public struct IronDatabaseHeaderCell: View {

  // MARK: Lifecycle

  /// Creates a header cell.
  ///
  /// - Parameters:
  ///   - column: The column definition.
  ///   - isSorted: Whether this column is currently sorted.
  ///   - sortDirection: The current sort direction, if sorted.
  ///   - isFiltered: Whether this column has an active filter.
  ///   - onSort: Callback when the header is tapped to sort.
  ///   - onFilter: Callback when filter button is tapped.
  ///   - onRename: Callback when rename is selected from context menu.
  ///   - onChangeType: Callback when column type change is requested.
  ///   - onDelete: Callback when delete is selected from context menu.
  public init(
    column: IronColumn,
    isSorted: Bool = false,
    sortDirection: IronDatabaseSortState.SortDirection? = nil,
    isFiltered: Bool = false,
    onSort: (() -> Void)? = nil,
    onFilter: (() -> Void)? = nil,
    onRename: (() -> Void)? = nil,
    onChangeType: ((IronColumnType) -> Void)? = nil,
    onDelete: (() -> Void)? = nil,
  ) {
    self.column = column
    self.isSorted = isSorted
    self.sortDirection = sortDirection
    self.isFiltered = isFiltered
    self.onSort = onSort
    self.onFilter = onFilter
    self.onRename = onRename
    self.onChangeType = onChangeType
    self.onDelete = onDelete
  }

  // MARK: Public

  public var body: some View {
    Button {
      if column.isSortable {
        onSort?()
      }
    } label: {
      HStack(spacing: theme.spacing.xs) {
        // Column type icon
        IronIcon(systemName: column.type.iconName, size: .small, color: .secondary)

        // Column name
        IronText(column.name, style: .labelMedium, color: .secondary)
          .lineLimit(1)

        Spacer(minLength: theme.spacing.xs)

        // Filter indicator
        if isFiltered {
          IronIcon(
            systemName: "line.3.horizontal.decrease.circle.fill",
            size: .xSmall,
            color: .primary,
          )
          .transition(.scale.combined(with: .opacity))
        }

        // Sort indicator
        if isSorted, let direction = sortDirection {
          IronIcon(
            systemName: direction.iconName,
            size: .xSmall,
            color: .primary,
          )
          .transition(.scale.combined(with: .opacity))
          .accessibilityLabel(direction.accessibilityLabel)
        }
      }
      .padding(.horizontal, theme.spacing.sm)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .background(theme.colors.surfaceElevated)
    .contextMenu {
      contextMenuContent
    }
    .accessibilityLabel(accessibilityLabel)
    .accessibilityHint(column.isSortable ? "Tap to sort by this column" : "")
    .accessibilityAddTraits(column.isSortable ? .isButton : [])
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private let column: IronColumn
  private let isSorted: Bool
  private let sortDirection: IronDatabaseSortState.SortDirection?
  private let isFiltered: Bool
  private let onSort: (() -> Void)?
  private let onFilter: (() -> Void)?
  private let onRename: (() -> Void)?
  private let onChangeType: ((IronColumnType) -> Void)?
  private let onDelete: (() -> Void)?

  private var accessibilityLabel: String {
    var parts = [column.name, column.type.displayName]

    if isSorted, let direction = sortDirection {
      parts.append(direction.accessibilityLabel)
    }

    if isFiltered {
      parts.append("Filtered")
    }

    return parts.joined(separator: ", ")
  }

  @ViewBuilder
  private var contextMenuContent: some View {
    if let onRename {
      Button {
        onRename()
      } label: {
        Label("Rename", systemImage: "pencil")
      }
    }

    if let onFilter {
      Button {
        onFilter()
      } label: {
        Label(isFiltered ? "Edit Filter" : "Add Filter", systemImage: "line.3.horizontal.decrease")
      }
    }

    if let onChangeType {
      Menu("Change Type") {
        ForEach(IronColumnType.allCases, id: \.self) { type in
          Button {
            onChangeType(type)
          } label: {
            Label(type.displayName, systemImage: type.iconName)
          }
          .disabled(type == column.type)
        }
      }
    }

    if onRename != nil || onFilter != nil || onChangeType != nil {
      Divider()
    }

    if let onDelete {
      Button(role: .destructive) {
        onDelete()
      } label: {
        Label("Delete Column", systemImage: "trash")
      }
    }
  }
}

// MARK: - IronDatabaseAddColumnButton

/// Button for adding a new column to the table.
public struct IronDatabaseAddColumnButton: View {

  // MARK: Lifecycle

  /// Creates an add column button.
  ///
  /// - Parameter action: Callback when the button is tapped.
  public init(action: @escaping () -> Void) {
    self.action = action
  }

  // MARK: Public

  public var body: some View {
    Button(action: action) {
      IronIcon(systemName: "plus", size: .small, color: .secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .buttonStyle(.plain)
    .background(theme.colors.surfaceElevated)
    .accessibilityLabel("Add column")
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private let action: () -> Void
}

// MARK: - Preview

#Preview("IronDatabaseHeaderCell - Default") {
  VStack(spacing: 0) {
    IronDatabaseHeaderCell(
      column: IronColumn(name: "Title", type: .text),
      onSort: { },
      onDelete: { },
    )
    .frame(height: 44)

    IronDatabaseHeaderCell(
      column: IronColumn(name: "Status", type: .select),
      isSorted: true,
      sortDirection: .ascending,
      onSort: { },
      onDelete: { },
    )
    .frame(height: 44)

    IronDatabaseHeaderCell(
      column: IronColumn(name: "Due Date", type: .date),
      isFiltered: true,
      onSort: { },
      onFilter: { },
      onDelete: { },
    )
    .frame(height: 44)

    IronDatabaseHeaderCell(
      column: IronColumn(name: "Priority", type: .number),
      isSorted: true,
      sortDirection: .descending,
      isFiltered: true,
      onSort: { },
      onFilter: { },
      onDelete: { },
    )
    .frame(height: 44)
  }
  .frame(width: 200)
  .padding()
}
