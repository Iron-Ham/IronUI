#if os(iOS)
import IronCore
import IronPrimitives
import SwiftUI
import UIKit

// MARK: - IronDatabaseHeaderCollectionCell

/// Collection view cell for header items using modern UIHostingConfiguration.
final class IronDatabaseHeaderCollectionCell: UICollectionViewCell {

  // MARK: Lifecycle

  override init(frame: CGRect) {
    super.init(frame: frame)
    // Background color is applied via SwiftUI hosting configuration for theming support
    contentView.backgroundColor = .clear
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  func configureEmpty() {
    contentConfiguration = UIHostingConfiguration {
      Color.clear
        .modifier(IronThemedHeaderBackgroundModifier())
    }
    .margins(.all, 0)
  }

  func configureAddButton(onTap: @escaping () -> Void) {
    contentConfiguration = UIHostingConfiguration {
      IronThemedHeaderButton(systemImage: "plus", action: onTap)
    }
    .margins(.all, 0)
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
      .modifier(IronThemedHeaderBackgroundModifier())
    }
    .margins(.all, 0)
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
    isInTableEditMode: Bool,
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
        isInTableEditMode: isInTableEditMode,
        onTap: onTap,
        onSubmit: onSubmit,
        onEdit: onEdit,
        onCancel: onCancel,
        onClear: onClear,
        onRowAction: onRowAction,
      )
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(accessibilityLabel)
      .accessibilityHint(accessibilityHint)
      .accessibilityAddTraits(column.type == .checkbox ? .isButton : [])
    }
    // No margins - the container fills the full cell for tap hit testing
    .margins(.all, 0)
    // Selection highlight spans the full cell (row highlight effect)
    .background { IronRowSelectionBackground(isSelected: isSelected) }
  }
}

// MARK: - IronDatabaseSelectionCollectionCell

/// Collection view cell for selection checkboxes using modern UIHostingConfiguration.
final class IronDatabaseSelectionCollectionCell: UICollectionViewCell {

  func configure(isSelected: Bool, rowNumber: Int, onToggle: @escaping () -> Void) {
    contentConfiguration = UIHostingConfiguration {
      IronSelectionCheckbox(isSelected: isSelected, rowNumber: rowNumber, onToggle: onToggle)
    }
    .margins(.all, 0)
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
        .foregroundStyle(isSelected ? theme.colors.primary : theme.colors.textSecondary)
        .font(.title3)
        .contentTransition(.symbolEffect(.replace))
    }
    .buttonStyle(.plain)
    .padding(.horizontal, theme.spacing.sm)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    // Show selection highlight for row continuity, or divider color when not selected
    .background(isSelected ? theme.colors.primary.opacity(0.08) : theme.colors.divider)
    .accessibilityLabel(String(localized: "Select row \(rowNumber)"))
    .accessibilityValue(isSelected ? String(localized: "Selected") : String(localized: "Not selected"))
    .accessibilityAddTraits(.isButton)
    .accessibleAnimation(theme.animation.snappy, value: isSelected)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

}

/// Selection background that spans the full cell for row highlight effect.
private struct IronRowSelectionBackground: View {
  let isSelected: Bool

  var body: some View {
    if isSelected {
      theme.colors.primary.opacity(0.08)
    } else {
      Color.clear
    }
  }

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
  /// Whether the table is in edit mode (selection mode). When true, cell content
  /// is non-interactive and taps anywhere toggle row selection.
  let isInTableEditMode: Bool
  let onTap: () -> Void
  let onSubmit: () -> Void
  var onEdit: (() -> Void)?
  var onCancel: (() -> Void)?
  var onClear: (() -> Void)?
  var onRowAction: ((IronDatabaseRowAction) -> Void)?

  var body: some View {
    // Cell content with focus ring and visual feedback
    IronDatabaseCell(column: column, value: $value, isEditing: isEditing)
      // Disable cell content interactivity in table edit mode so taps toggle selection
      .allowsHitTesting(!isInTableEditMode)
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
      // Context menu disabled in table edit mode
      .contextMenu(isInTableEditMode
        ? nil
        : ContextMenu {
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
        })
      .accessibleAnimation(theme.animation.snappy, value: isEditing)
      .accessibleAnimation(theme.animation.snappy, value: isSelected)
      .accessibleAnimation(theme.animation.snappy, value: showSuccessFlash)
      // Fill remaining space and make entire cell tappable (including dead space)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .contentShape(Rectangle())
      .onTapGesture { onTap() }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @State private var showSuccessFlash = false

  /// Background for the content area (editing state only).
  /// Row selection highlight is applied at the cell level via `IronRowSelectionBackground`.
  private var backgroundColor: Color {
    if isEditing {
      return theme.colors.surfaceElevated
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
          .foregroundStyle(theme.colors.primary)
          .font(.caption)
      }

      if isFiltered {
        Image(systemName: "line.3.horizontal.decrease.circle.fill")
          .foregroundStyle(theme.colors.primary)
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

// MARK: - Themed Header Views

/// View modifier that applies themed header background.
private struct IronThemedHeaderBackgroundModifier: ViewModifier {
  func body(content: Content) -> some View {
    content.background(theme.colors.surfaceElevated)
  }

  @Environment(\.ironTheme) private var theme

}

/// Themed button for header actions (e.g., add column).
private struct IronThemedHeaderButton: View {
  let systemImage: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: systemImage)
        .foregroundStyle(theme.colors.textSecondary)
    }
    .buttonStyle(.plain)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(theme.colors.surfaceElevated)
  }

  @Environment(\.ironTheme) private var theme

}

#endif
