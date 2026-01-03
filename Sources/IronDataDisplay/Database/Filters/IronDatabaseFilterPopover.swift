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
  public init(
    column: IronColumn,
    filter: Binding<IronDatabaseFilter?>,
    selectOptions: [IronSelectOption] = [],
  ) {
    self.column = column
    _filter = filter
    self.selectOptions = selectOptions
  }

  // MARK: Public

  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header
      HStack {
        Label(column.name, systemImage: column.type.iconName)
          .font(.headline)

        Spacer()

        if filter != nil {
          Button("Clear", role: .destructive) {
            filter = nil
          }
          .font(.subheadline)
        }
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
  @Environment(\.ironTheme) private var theme

  private let column: IronColumn
  private let selectOptions: [IronSelectOption]

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

      if operation.requiresInput {
        TextField("Value", text: $query)
          .textFieldStyle(.roundedBorder)
          .onSubmit { applyFilter() }
      }

      Button("Apply") { applyFilter() }
        .buttonStyle(.borderedProminent)
        .disabled(operation.requiresInput && query.isEmpty)
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

      if operation == .between {
        HStack {
          TextField("Min", value: $minValue, format: .number)
            .textFieldStyle(.roundedBorder)
          Text("to")
          TextField("Max", value: $maxValue, format: .number)
            .textFieldStyle(.roundedBorder)
        }
      } else if operation.requiresInput {
        TextField("Value", value: $value, format: .number)
          .textFieldStyle(.roundedBorder)
      }

      Button("Apply") { applyFilter() }
        .buttonStyle(.borderedProminent)
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

      switch operation {
      case .equals, .before, .after:
        DatePicker("Date", selection: $date, displayedComponents: .date)
          .labelsHidden()

      case .between:
        DatePicker("From", selection: $startDate, displayedComponents: .date)
        DatePicker("To", selection: $endDate, displayedComponents: .date)

      case .pastDays, .nextDays:
        Stepper("\(days) days", value: $days, in: 1 ... 365)

      default:
        EmptyView()
      }

      Button("Apply") { applyFilter() }
        .buttonStyle(.borderedProminent)
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
      Button {
        filter = .checked
      } label: {
        HStack {
          Image(systemName: "checkmark.square.fill")
          Text("Checked")
          Spacer()
          if case .checked = filter {
            Image(systemName: "checkmark")
              .foregroundStyle(.blue)
          }
        }
      }
      .buttonStyle(.plain)

      Button {
        filter = .unchecked
      } label: {
        HStack {
          Image(systemName: "square")
          Text("Unchecked")
          Spacer()
          if case .unchecked = filter {
            Image(systemName: "checkmark")
              .foregroundStyle(.blue)
          }
        }
      }
      .buttonStyle(.plain)
    }
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

      if mode == .includes || mode == .excludes {
        ScrollView {
          VStack(alignment: .leading, spacing: 4) {
            ForEach(options) { option in
              Button {
                toggleOption(option.id)
              } label: {
                HStack {
                  Circle()
                    .fill(option.color.swiftUIColor)
                    .frame(width: 12, height: 12)
                  Text(option.name)
                  Spacer()
                  if selectedIDs.contains(option.id) {
                    Image(systemName: "checkmark")
                      .foregroundStyle(.blue)
                  }
                }
              }
              .buttonStyle(.plain)
            }
          }
        }
        .frame(maxHeight: 200)
      }

      Button("Apply") { applyFilter() }
        .buttonStyle(.borderedProminent)
        .disabled(mode.requiresSelection && selectedIDs.isEmpty)
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
