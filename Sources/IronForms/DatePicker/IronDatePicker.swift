import IronCore
import IronPrimitives
import SwiftUI

// MARK: - IronDatePicker

/// A themed date picker with consistent styling.
///
/// `IronDatePicker` provides a date selection control that integrates
/// with the IronUI design system and supports various display styles.
///
/// ## Basic Usage
///
/// ```swift
/// @State private var date = Date()
///
/// IronDatePicker("Date of Birth", selection: $date)
/// ```
///
/// ## With Components
///
/// ```swift
/// IronDatePicker(
///   "Appointment",
///   selection: $date,
///   displayedComponents: [.date, .hourAndMinute]
/// )
/// ```
///
/// ## In a Form
///
/// ```swift
/// IronFormField("Start Date") {
///   IronDatePicker(selection: $startDate)
/// }
/// ```
public struct IronDatePicker: View {

  // MARK: Lifecycle

  /// Creates a date picker with a label.
  ///
  /// - Parameters:
  ///   - label: The label for the date picker.
  ///   - selection: Binding to the selected date.
  ///   - displayedComponents: Which date components to display.
  ///   - style: The visual style of the picker.
  public init(
    _ label: LocalizedStringKey,
    selection: Binding<Date>,
    displayedComponents: DatePicker.Components = .date,
    style: IronDatePickerStyle = .automatic,
  ) {
    self.label = label
    _selection = selection
    self.displayedComponents = displayedComponents
    self.style = style
  }

  /// Creates a date picker with a string label.
  ///
  /// - Parameters:
  ///   - label: The label for the date picker.
  ///   - selection: Binding to the selected date.
  ///   - displayedComponents: Which date components to display.
  ///   - style: The visual style of the picker.
  public init(
    _ label: String,
    selection: Binding<Date>,
    displayedComponents: DatePicker.Components = .date,
    style: IronDatePickerStyle = .automatic,
  ) {
    self.label = LocalizedStringKey(label)
    _selection = selection
    self.displayedComponents = displayedComponents
    self.style = style
  }

  /// Creates a date picker without a label.
  ///
  /// - Parameters:
  ///   - selection: Binding to the selected date.
  ///   - displayedComponents: Which date components to display.
  ///   - style: The visual style of the picker.
  public init(
    selection: Binding<Date>,
    displayedComponents: DatePicker.Components = .date,
    style: IronDatePickerStyle = .automatic,
  ) {
    label = nil
    _selection = selection
    self.displayedComponents = displayedComponents
    self.style = style
  }

  /// Creates a date picker with a date range.
  ///
  /// - Parameters:
  ///   - label: The label for the date picker.
  ///   - selection: Binding to the selected date.
  ///   - range: The allowed date range.
  ///   - displayedComponents: Which date components to display.
  ///   - style: The visual style of the picker.
  public init(
    _ label: LocalizedStringKey,
    selection: Binding<Date>,
    in range: ClosedRange<Date>,
    displayedComponents: DatePicker.Components = .date,
    style: IronDatePickerStyle = .automatic,
  ) {
    self.label = label
    _selection = selection
    self.range = range
    self.displayedComponents = displayedComponents
    self.style = style
  }

  // MARK: Public

  public var body: some View {
    Group {
      if let range {
        DatePicker(
          selection: $selection,
          in: range,
          displayedComponents: displayedComponents,
        ) {
          if let label {
            IronText(label, style: .bodyMedium, color: .primary)
          }
        }
      } else {
        DatePicker(
          selection: $selection,
          displayedComponents: displayedComponents,
        ) {
          if let label {
            IronText(label, style: .bodyMedium, color: .primary)
          }
        }
      }
    }
    .modifier(DatePickerStyleModifier(style: style))
    .tint(theme.colors.primary)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  @Binding private var selection: Date

  private let label: LocalizedStringKey?
  private let displayedComponents: DatePicker.Components
  private let style: IronDatePickerStyle
  private var range: ClosedRange<Date>?
}

// MARK: - DatePickerStyleModifier

/// Internal modifier to apply date picker style.
private struct DatePickerStyleModifier: ViewModifier {
  let style: IronDatePickerStyle

  func body(content: Content) -> some View {
    switch style {
    case .automatic:
      content.datePickerStyle(.automatic)
    case .compact:
      content.datePickerStyle(.compact)
    case .graphical:
      content.datePickerStyle(.graphical)
    case .wheel:
      content.datePickerStyle(.wheel)
    }
  }
}

// MARK: - IronDatePickerStyle

/// Visual styles for the date picker.
public enum IronDatePickerStyle: Sendable {
  /// System default style based on context.
  case automatic
  /// Compact inline style.
  case compact
  /// Full calendar view.
  case graphical
  /// Wheel picker style.
  case wheel
}

// MARK: - IronTimePicker

/// A themed time picker with consistent styling.
///
/// ```swift
/// @State private var time = Date()
///
/// IronTimePicker("Alarm", selection: $time)
/// ```
public struct IronTimePicker: View {

  // MARK: Lifecycle

  /// Creates a time picker with a label.
  ///
  /// - Parameters:
  ///   - label: The label for the time picker.
  ///   - selection: Binding to the selected time.
  ///   - style: The visual style of the picker.
  public init(
    _ label: LocalizedStringKey,
    selection: Binding<Date>,
    style: IronDatePickerStyle = .automatic,
  ) {
    self.label = label
    _selection = selection
    self.style = style
  }

  /// Creates a time picker with a string label.
  public init(
    _ label: String,
    selection: Binding<Date>,
    style: IronDatePickerStyle = .automatic,
  ) {
    self.label = LocalizedStringKey(label)
    _selection = selection
    self.style = style
  }

  /// Creates a time picker without a label.
  public init(
    selection: Binding<Date>,
    style: IronDatePickerStyle = .automatic,
  ) {
    label = nil
    _selection = selection
    self.style = style
  }

  // MARK: Public

  public var body: some View {
    IronDatePicker(
      label ?? "",
      selection: $selection,
      displayedComponents: .hourAndMinute,
      style: style,
    )
  }

  // MARK: Private

  @Binding private var selection: Date

  private let label: LocalizedStringKey?
  private let style: IronDatePickerStyle
}

// MARK: - Previews

#Preview("IronDatePicker - Styles") {
  @Previewable @State var date = Date()

  VStack(spacing: 32) {
    IronFormField("Compact Style") {
      IronDatePicker("Date", selection: $date, style: .compact)
    }

    IronFormField("Graphical Style") {
      IronDatePicker(selection: $date, style: .graphical)
    }
  }
  .padding()
}

#Preview("IronDatePicker - Components") {
  @Previewable @State var date = Date()
  @Previewable @State var time = Date()
  @Previewable @State var dateTime = Date()

  VStack(spacing: 24) {
    IronFormField("Date Only") {
      IronDatePicker("Select date", selection: $date, displayedComponents: .date)
    }

    IronFormField("Time Only") {
      IronTimePicker("Select time", selection: $time)
    }

    IronFormField("Date and Time") {
      IronDatePicker(
        "Select date and time",
        selection: $dateTime,
        displayedComponents: [.date, .hourAndMinute],
      )
    }
  }
  .padding()
}

#Preview("IronDatePicker - In Form") {
  @Previewable @State var startDate = Date()
  @Previewable @State var endDate = Date()
  @Previewable @State var reminderTime = Date()

  IronForm {
    IronFormSection("Event Details") {
      IronFormField("Start Date", isRequired: true) {
        IronDatePicker(selection: $startDate, displayedComponents: [.date, .hourAndMinute])
      }

      IronFormField("End Date") {
        IronDatePicker(selection: $endDate, displayedComponents: [.date, .hourAndMinute])
      }
    }

    IronFormSection("Reminders") {
      IronFormField("Reminder Time") {
        IronTimePicker(selection: $reminderTime)
      }
    }
  }
}

#Preview("IronDatePicker - With Range") {
  @Previewable @State var date = Date()

  let now = Date()
  let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: now)!

  VStack(spacing: 24) {
    IronFormField("Appointment (within next year)") {
      IronDatePicker(
        "Select date",
        selection: $date,
        in: now ... oneYearFromNow,
        style: .graphical,
      )
    }
  }
  .padding()
}
