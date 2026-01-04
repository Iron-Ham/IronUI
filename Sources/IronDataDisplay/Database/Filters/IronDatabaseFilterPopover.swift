import IronCore
import SwiftUI

// MARK: - IronDatabaseFilterPopover

/// Popover for configuring column filters.
///
/// This view provides a unified interface for setting up filters
/// based on the column's data type. It presents type-specific
/// controls and allows clearing the active filter.
///
/// ## Usage
///
/// ```swift
/// @State private var showFilter = false
/// @State private var filter: IronDatabaseFilter?
///
/// Button("Filter") { showFilter = true }
///   .popover(isPresented: $showFilter) {
///     IronDatabaseFilterPopover(
///       column: column,
///       filter: $filter
///     )
///   }
/// ```
public struct IronDatabaseFilterPopover: View {

  // MARK: Lifecycle

  /// Creates a filter popover for a column.
  ///
  /// - Parameters:
  ///   - column: The column to filter.
  ///   - filter: Binding to the current filter.
  ///   - selectOptions: Available options for select columns.
  ///   - filterMode: Optional binding to the global filter mode (AND/OR).
  ///   - activeFilterCount: The number of active filters across all columns.
  public init(
    column: IronColumn,
    filter: Binding<IronDatabaseFilter?>,
    selectOptions: [IronSelectOption] = [],
    filterMode: Binding<IronDatabaseFilterState.FilterMode>? = nil,
    activeFilterCount: Int = 0,
  ) {
    self.column = column
    _filter = filter
    self.selectOptions = selectOptions
    _filterMode = filterMode ?? .constant(.and)
    self.activeFilterCount = activeFilterCount
    hasFilterModeBinding = filterMode != nil
  }

  // MARK: Public

  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header
      HStack {
        Label(column.name, systemImage: column.type.iconName)
          .font(.headline)
          .accessibilityLabel("Filter for \(column.name) column")

        Spacer()

        if filter != nil {
          Button("Clear", role: .destructive) {
            filter = nil
          }
          .font(.subheadline)
          .accessibilityLabel("Clear filter")
          .accessibilityHint("Removes the filter from this column")
        }
      }

      // Filter mode toggle (AND/OR) when multiple filters are active
      if showsFilterModeToggle {
        HStack(spacing: theme.spacing.sm) {
          IronText("Match:", style: .labelSmall, color: .secondary)
            .accessibilityHidden(true)

          Picker("Filter mode", selection: $filterMode) {
            Text("All").tag(IronDatabaseFilterState.FilterMode.and)
            Text("Any").tag(IronDatabaseFilterState.FilterMode.or)
          }
          .pickerStyle(.segmented)
          .accessibilityLabel("Filter combination mode")
          .accessibilityValue(filterMode.accessibilityLabel)
          .accessibilityHint("Choose how multiple filters combine")

          Spacer()

          // Active filter count badge
          IronText("\(activeFilterCount) active", style: .caption, color: .secondary)
            .accessibilityLabel("\(activeFilterCount) filters active")
        }
        .padding(.vertical, theme.spacing.xs)
        .padding(.horizontal, theme.spacing.sm)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.sm))
      }

      Divider()

      // Type-specific controls
      filterControls
    }
    .padding()
    .frame(minWidth: 280, maxWidth: 320)
  }

  // MARK: Private

  @Binding private var filter: IronDatabaseFilter?
  @Binding private var filterMode: IronDatabaseFilterState.FilterMode
  @Environment(\.ironTheme) private var theme

  private let column: IronColumn
  private let selectOptions: [IronSelectOption]
  private let activeFilterCount: Int
  private let hasFilterModeBinding: Bool

  /// Whether to show the filter mode toggle.
  /// Shows when there are multiple active filters OR when this filter is being added
  /// (and there's already at least one other filter).
  private var showsFilterModeToggle: Bool {
    hasFilterModeBinding && (activeFilterCount > 1 || (activeFilterCount == 1 && filter == nil))
  }

  @ViewBuilder
  private var filterControls: some View {
    switch column.type {
    case .text, .email, .phone, .url, .person:
      TextFilterControls(filter: textFilterBinding)

    case .number:
      NumberFilterControls(filter: numberFilterBinding)

    case .date:
      DateFilterControls(filter: dateFilterBinding)

    case .checkbox:
      CheckboxFilterControls(filter: checkboxFilterBinding)

    case .select, .multiSelect:
      SelectFilterControls(
        filter: selectFilterBinding,
        options: selectOptions,
      )
    }
  }

  private var textFilterBinding: Binding<IronDatabaseFilter.TextFilter?> {
    Binding(
      get: {
        if case .text(let filter) = filter {
          return filter
        }
        return nil
      },
      set: { newValue in
        if let newValue {
          filter = .text(newValue)
        } else {
          filter = nil
        }
      },
    )
  }

  private var numberFilterBinding: Binding<IronDatabaseFilter.NumberFilter?> {
    Binding(
      get: {
        if case .number(let filter) = filter {
          return filter
        }
        return nil
      },
      set: { newValue in
        if let newValue {
          filter = .number(newValue)
        } else {
          filter = nil
        }
      },
    )
  }

  private var dateFilterBinding: Binding<IronDatabaseFilter.DateFilter?> {
    Binding(
      get: {
        if case .date(let filter) = filter {
          return filter
        }
        return nil
      },
      set: { newValue in
        if let newValue {
          filter = .date(newValue)
        } else {
          filter = nil
        }
      },
    )
  }

  private var checkboxFilterBinding: Binding<IronDatabaseFilter.CheckboxFilter?> {
    Binding(
      get: {
        if case .checkbox(let filter) = filter {
          return filter
        }
        return nil
      },
      set: { newValue in
        if let newValue {
          filter = .checkbox(newValue)
        } else {
          filter = nil
        }
      },
    )
  }

  private var selectFilterBinding: Binding<IronDatabaseFilter.SelectFilter?> {
    Binding(
      get: {
        if case .select(let filter) = filter {
          return filter
        }
        return nil
      },
      set: { newValue in
        if let newValue {
          filter = .select(newValue)
        } else {
          filter = nil
        }
      },
    )
  }
}

// MARK: - TextFilterControls

/// Controls for text-based filters.
struct TextFilterControls: View {

  // MARK: Internal

  enum TextOperation: String, CaseIterable {
    case contains
    case equals
    case startsWith
    case endsWith
    case isEmpty
    case isNotEmpty

    // MARK: Internal

    var displayName: String {
      switch self {
      case .contains: "Contains"
      case .equals: "Equals"
      case .startsWith: "Starts with"
      case .endsWith: "Ends with"
      case .isEmpty: "Is empty"
      case .isNotEmpty: "Is not empty"
      }
    }

    var requiresInput: Bool {
      switch self {
      case .contains, .equals, .startsWith, .endsWith:
        true
      case .isEmpty, .isNotEmpty:
        false
      }
    }
  }

  @Binding var filter: IronDatabaseFilter.TextFilter?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Picker("Condition", selection: $operation) {
        ForEach(TextOperation.allCases, id: \.self) { op in
          Text(op.displayName).tag(op)
        }
      }
      .pickerStyle(.menu)
      .labelsHidden()
      .accessibilityLabel("Filter condition")
      .accessibilityValue(operation.displayName)

      if operation.requiresInput {
        TextField("Value", text: $query)
          .textFieldStyle(.roundedBorder)
          .onSubmit { applyFilter() }
          .accessibilityLabel("Filter value")
          .accessibilityHint("Enter text to filter by")
      }

      Button("Apply") { applyFilter() }
        .buttonStyle(.borderedProminent)
        .disabled(operation.requiresInput && query.isEmpty)
        .accessibilityLabel("Apply filter")
        .accessibilityHint("Applies the \(operation.displayName) filter")
    }
    .onAppear { loadCurrentFilter() }
  }

  // MARK: Private

  @State private var operation = TextOperation.contains
  @State private var query = ""

  private func loadCurrentFilter() {
    guard let filter else { return }
    switch filter {
    case .contains(let s):
      operation = .contains
      query = s

    case .equals(let s):
      operation = .equals
      query = s

    case .startsWith(let s):
      operation = .startsWith
      query = s

    case .endsWith(let s):
      operation = .endsWith
      query = s

    case .isEmpty:
      operation = .isEmpty

    case .isNotEmpty:
      operation = .isNotEmpty
    }
  }

  private func applyFilter() {
    switch operation {
    case .contains:
      filter = .contains(query)
    case .equals:
      filter = .equals(query)
    case .startsWith:
      filter = .startsWith(query)
    case .endsWith:
      filter = .endsWith(query)
    case .isEmpty:
      filter = .isEmpty
    case .isNotEmpty:
      filter = .isNotEmpty
    }
  }

}

// MARK: - NumberFilterControls

/// Controls for number-based filters.
struct NumberFilterControls: View {

  // MARK: Internal

  enum NumberOperation: String, CaseIterable {
    case equals
    case greaterThan
    case lessThan
    case greaterThanOrEqual
    case lessThanOrEqual
    case between
    case isEmpty
    case isNotEmpty

    // MARK: Internal

    var displayName: String {
      switch self {
      case .equals: "="
      case .greaterThan: ">"
      case .lessThan: "<"
      case .greaterThanOrEqual: "≥"
      case .lessThanOrEqual: "≤"
      case .between: "Between"
      case .isEmpty: "Is empty"
      case .isNotEmpty: "Is not empty"
      }
    }

    var requiresInput: Bool {
      switch self {
      case .equals, .greaterThan, .lessThan, .greaterThanOrEqual, .lessThanOrEqual, .between:
        true
      case .isEmpty, .isNotEmpty:
        false
      }
    }
  }

  @Binding var filter: IronDatabaseFilter.NumberFilter?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Picker("Condition", selection: $operation) {
        ForEach(NumberOperation.allCases, id: \.self) { op in
          Text(op.displayName).tag(op)
        }
      }
      .pickerStyle(.menu)
      .labelsHidden()
      .accessibilityLabel("Filter condition")
      .accessibilityValue(operation.displayName)

      if operation == .between {
        HStack {
          TextField("Min", value: $minValue, format: .number)
            .textFieldStyle(.roundedBorder)
            .accessibilityLabel("Minimum value")
          Text("to")
            .accessibilityHidden(true)
          TextField("Max", value: $maxValue, format: .number)
            .textFieldStyle(.roundedBorder)
            .accessibilityLabel("Maximum value")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Range filter")
      } else if operation.requiresInput {
        TextField("Value", value: $value, format: .number)
          .textFieldStyle(.roundedBorder)
          .accessibilityLabel("Filter value")
          .accessibilityHint("Enter a number to filter by")
      }

      Button("Apply") { applyFilter() }
        .buttonStyle(.borderedProminent)
        .accessibilityLabel("Apply filter")
        .accessibilityHint("Applies the \(operation.displayName) filter")
    }
    .onAppear { loadCurrentFilter() }
  }

  // MARK: Private

  @State private var operation = NumberOperation.equals
  @State private var value: Double = 0
  @State private var minValue: Double = 0
  @State private var maxValue: Double = 100

  private func loadCurrentFilter() {
    guard let filter else { return }
    switch filter {
    case .equals(let v):
      operation = .equals
      value = v

    case .greaterThan(let v):
      operation = .greaterThan
      value = v

    case .lessThan(let v):
      operation = .lessThan
      value = v

    case .greaterThanOrEqual(let v):
      operation = .greaterThanOrEqual
      value = v

    case .lessThanOrEqual(let v):
      operation = .lessThanOrEqual
      value = v

    case .between(let min, let max):
      operation = .between
      minValue = min
      maxValue = max

    case .isEmpty:
      operation = .isEmpty

    case .isNotEmpty:
      operation = .isNotEmpty
    }
  }

  private func applyFilter() {
    switch operation {
    case .equals:
      filter = .equals(value)
    case .greaterThan:
      filter = .greaterThan(value)
    case .lessThan:
      filter = .lessThan(value)
    case .greaterThanOrEqual:
      filter = .greaterThanOrEqual(value)
    case .lessThanOrEqual:
      filter = .lessThanOrEqual(value)
    case .between:
      filter = .between(min: minValue, max: maxValue)
    case .isEmpty:
      filter = .isEmpty
    case .isNotEmpty:
      filter = .isNotEmpty
    }
  }

}

// MARK: - DateFilterControls

/// Controls for date-based filters.
struct DateFilterControls: View {

  // MARK: Internal

  enum DateOperation: String, CaseIterable {
    case isToday
    case isThisWeek
    case isThisMonth
    case equals
    case before
    case after
    case between
    case pastDays
    case nextDays
    case isEmpty
    case isNotEmpty

    // MARK: Internal

    var displayName: String {
      switch self {
      case .isToday: "Today"
      case .isThisWeek: "This week"
      case .isThisMonth: "This month"
      case .equals: "Is"
      case .before: "Before"
      case .after: "After"
      case .between: "Between"
      case .pastDays: "Past N days"
      case .nextDays: "Next N days"
      case .isEmpty: "Is empty"
      case .isNotEmpty: "Is not empty"
      }
    }
  }

  @Binding var filter: IronDatabaseFilter.DateFilter?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Picker("Condition", selection: $operation) {
        ForEach(DateOperation.allCases, id: \.self) { op in
          Text(op.displayName).tag(op)
        }
      }
      .pickerStyle(.menu)
      .labelsHidden()
      .accessibilityLabel("Filter condition")
      .accessibilityValue(operation.displayName)

      switch operation {
      case .equals, .before, .after:
        DatePicker("Date", selection: $date, displayedComponents: .date)
          .labelsHidden()
          .accessibilityLabel("Filter date")
          .accessibilityHint("Select the date to filter by")

      case .between:
        DatePicker("From", selection: $startDate, displayedComponents: .date)
          .accessibilityLabel("Start date")
          .accessibilityHint("Select the start of the date range")
        DatePicker("To", selection: $endDate, displayedComponents: .date)
          .accessibilityLabel("End date")
          .accessibilityHint("Select the end of the date range")

      case .pastDays, .nextDays:
        Stepper("\(days) days", value: $days, in: 1 ... 365)
          .accessibilityLabel("Number of days")
          .accessibilityValue("\(days) days")
          .accessibilityHint("Adjust the number of days to filter")

      default:
        EmptyView()
      }

      Button("Apply") { applyFilter() }
        .buttonStyle(.borderedProminent)
        .accessibilityLabel("Apply filter")
        .accessibilityHint("Applies the \(operation.displayName) filter")
    }
    .onAppear { loadCurrentFilter() }
  }

  // MARK: Private

  @State private var operation = DateOperation.isToday
  @State private var date = Date()
  @State private var startDate = Date()
  @State private var endDate = Date()
  @State private var days = 7

  private func loadCurrentFilter() {
    guard let filter else { return }
    switch filter {
    case .equals(let d):
      operation = .equals
      date = d

    case .before(let d):
      operation = .before
      date = d

    case .after(let d):
      operation = .after
      date = d

    case .between(let start, let end):
      operation = .between
      startDate = start
      endDate = end

    case .isToday:
      operation = .isToday

    case .isThisWeek:
      operation = .isThisWeek

    case .isThisMonth:
      operation = .isThisMonth

    case .pastDays(let d):
      operation = .pastDays
      days = d

    case .nextDays(let d):
      operation = .nextDays
      days = d

    case .isEmpty:
      operation = .isEmpty

    case .isNotEmpty:
      operation = .isNotEmpty
    }
  }

  private func applyFilter() {
    switch operation {
    case .equals:
      filter = .equals(date)
    case .before:
      filter = .before(date)
    case .after:
      filter = .after(date)
    case .between:
      filter = .between(start: startDate, end: endDate)
    case .isToday:
      filter = .isToday
    case .isThisWeek:
      filter = .isThisWeek
    case .isThisMonth:
      filter = .isThisMonth
    case .pastDays:
      filter = .pastDays(days)
    case .nextDays:
      filter = .nextDays(days)
    case .isEmpty:
      filter = .isEmpty
    case .isNotEmpty:
      filter = .isNotEmpty
    }
  }

}

// MARK: - CheckboxFilterControls

/// Controls for checkbox-based filters.
struct CheckboxFilterControls: View {

  @Binding var filter: IronDatabaseFilter.CheckboxFilter?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      let isCheckedSelected = filter == .checked
      let isUncheckedSelected = filter == .unchecked

      Button {
        filter = .checked
      } label: {
        HStack {
          Image(systemName: "checkmark.square.fill")
          Text("Checked")
          Spacer()
          if isCheckedSelected {
            Image(systemName: "checkmark")
              .foregroundStyle(.blue)
          }
        }
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Show checked items")
      .accessibilityAddTraits(isCheckedSelected ? .isSelected : [])
      .accessibilityHint(isCheckedSelected ? "Currently selected" : "Tap to filter by checked items")

      Button {
        filter = .unchecked
      } label: {
        HStack {
          Image(systemName: "square")
          Text("Unchecked")
          Spacer()
          if isUncheckedSelected {
            Image(systemName: "checkmark")
              .foregroundStyle(.blue)
          }
        }
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Show unchecked items")
      .accessibilityAddTraits(isUncheckedSelected ? .isSelected : [])
      .accessibilityHint(isUncheckedSelected ? "Currently selected" : "Tap to filter by unchecked items")
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Checkbox filter options")
  }
}

// MARK: - SelectFilterControls

/// Controls for select-based filters.
struct SelectFilterControls: View {

  // MARK: Internal

  enum SelectMode: String, CaseIterable {
    case includes
    case excludes
    case isEmpty
    case isNotEmpty

    // MARK: Internal

    var displayName: String {
      switch self {
      case .includes: "Includes"
      case .excludes: "Excludes"
      case .isEmpty: "Empty"
      case .isNotEmpty: "Not empty"
      }
    }

    var requiresSelection: Bool {
      switch self {
      case .includes, .excludes:
        true
      case .isEmpty, .isNotEmpty:
        false
      }
    }
  }

  @Binding var filter: IronDatabaseFilter.SelectFilter?

  let options: [IronSelectOption]

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Picker("Mode", selection: $mode) {
        ForEach(SelectMode.allCases, id: \.self) { mode in
          Text(mode.displayName).tag(mode)
        }
      }
      .pickerStyle(.segmented)
      .accessibilityLabel("Filter mode")
      .accessibilityValue(mode.displayName)
      .accessibilityHint("Choose how to filter options")

      if mode == .includes || mode == .excludes {
        ScrollView {
          VStack(alignment: .leading, spacing: 4) {
            ForEach(options) { option in
              let isSelected = selectedIDs.contains(option.id)
              Button {
                toggleOption(option.id)
              } label: {
                HStack {
                  Circle()
                    .fill(option.color.swiftUIColor)
                    .frame(width: 12, height: 12)
                    .accessibilityHidden(true)
                  Text(option.name)
                  Spacer()
                  if isSelected {
                    Image(systemName: "checkmark")
                      .foregroundStyle(.blue)
                  }
                }
              }
              .buttonStyle(.plain)
              .accessibilityLabel(option.name)
              .accessibilityAddTraits(isSelected ? .isSelected : [])
              .accessibilityHint(isSelected ? "Tap to deselect" : "Tap to select")
            }
          }
        }
        .frame(maxHeight: 200)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Filter options. \(selectedIDs.count) of \(options.count) selected")
      }

      Button("Apply") { applyFilter() }
        .buttonStyle(.borderedProminent)
        .disabled(mode.requiresSelection && selectedIDs.isEmpty)
        .accessibilityLabel("Apply filter")
        .accessibilityHint("Applies the \(mode.displayName) filter with \(selectedIDs.count) options")
    }
    .onAppear { loadCurrentFilter() }
  }

  // MARK: Private

  @State private var selectedIDs = Set<UUID>()
  @State private var mode = SelectMode.includes

  private func toggleOption(_ id: UUID) {
    if selectedIDs.contains(id) {
      selectedIDs.remove(id)
    } else {
      selectedIDs.insert(id)
    }
  }

  private func loadCurrentFilter() {
    guard let filter else { return }
    switch filter {
    case .includes(let ids):
      mode = .includes
      selectedIDs = ids

    case .excludes(let ids):
      mode = .excludes
      selectedIDs = ids

    case .isEmpty:
      mode = .isEmpty

    case .isNotEmpty:
      mode = .isNotEmpty
    }
  }

  private func applyFilter() {
    switch mode {
    case .includes:
      filter = .includes(selectedIDs)
    case .excludes:
      filter = .excludes(selectedIDs)
    case .isEmpty:
      filter = .isEmpty
    case .isNotEmpty:
      filter = .isNotEmpty
    }
  }

}

// MARK: - Previews

#if DEBUG
#Preview("Text Filter") {
  @Previewable @State var filter: IronDatabaseFilter? = .text(.contains("hello"))

  IronDatabaseFilterPopover(
    column: IronColumn(name: "Name", type: .text),
    filter: $filter,
  )
}

#Preview("Number Filter") {
  @Previewable @State var filter: IronDatabaseFilter? = .number(.greaterThan(10))

  IronDatabaseFilterPopover(
    column: IronColumn(name: "Age", type: .number),
    filter: $filter,
  )
}

#Preview("Date Filter") {
  @Previewable @State var filter: IronDatabaseFilter? = .date(.isThisWeek)

  IronDatabaseFilterPopover(
    column: IronColumn(name: "Created", type: .date),
    filter: $filter,
  )
}

#Preview("Select Filter") {
  @Previewable @State var filter: IronDatabaseFilter?

  let options = [
    IronSelectOption(name: "High", color: .error),
    IronSelectOption(name: "Medium", color: .warning),
    IronSelectOption(name: "Low", color: .success),
  ]

  IronDatabaseFilterPopover(
    column: IronColumn(name: "Priority", type: .select, options: options),
    filter: $filter,
    selectOptions: options,
  )
}
#endif
