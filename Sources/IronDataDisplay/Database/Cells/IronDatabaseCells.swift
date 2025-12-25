import IronCore
import IronPrimitives
import SwiftUI

// MARK: - IronDatabaseCell

/// A cell view that automatically renders the appropriate editor based on column type.
///
/// This is the main entry point for rendering database cells. It dispatches
/// to the appropriate cell editor based on the column type.
public struct IronDatabaseCell: View {

  // MARK: Lifecycle

  /// Creates a database cell.
  ///
  /// - Parameters:
  ///   - column: The column definition.
  ///   - value: Binding to the cell value.
  ///   - isEditing: Whether the cell is in edit mode.
  public init(
    column: IronColumn,
    value: Binding<IronCellValue>,
    isEditing: Bool = false,
  ) {
    self.column = column
    _value = value
    self.isEditing = isEditing
  }

  // MARK: Public

  public var body: some View {
    Group {
      switch column.type {
      case .text:
        IronTextCell(value: textBinding, isEditing: isEditing)

      case .number:
        IronNumberCell(value: numberBinding, isEditing: isEditing)

      case .date:
        IronDateCell(value: dateBinding, isEditing: isEditing)

      case .checkbox:
        IronCheckboxCell(value: checkboxBinding)

      case .select:
        IronSelectCell(
          value: selectBinding,
          options: column.options,
          isEditing: isEditing,
        )

      case .multiSelect:
        IronMultiSelectCell(
          value: multiSelectBinding,
          options: column.options,
          isEditing: isEditing,
        )

      case .person:
        IronPersonCell(value: personBinding, isEditing: isEditing)

      case .url:
        IronURLCell(value: urlBinding, isEditing: isEditing)

      case .email:
        IronEmailCell(value: emailBinding, isEditing: isEditing)

      case .phone:
        IronPhoneCell(value: phoneBinding, isEditing: isEditing)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: Private

  @Binding private var value: IronCellValue

  private let column: IronColumn
  private let isEditing: Bool

  private var textBinding: Binding<String> {
    Binding(
      get: {
        if case .text(let string) = value { return string }
        return ""
      },
      set: { value = .text($0) },
    )
  }

  private var numberBinding: Binding<Double?> {
    Binding(
      get: {
        if case .number(let num) = value { return num }
        return nil
      },
      set: { value = $0.map { .number($0) } ?? .empty },
    )
  }

  private var dateBinding: Binding<Date?> {
    Binding(
      get: {
        if case .date(let date) = value { return date }
        return nil
      },
      set: { value = $0.map { .date($0) } ?? .empty },
    )
  }

  private var checkboxBinding: Binding<Bool> {
    Binding(
      get: {
        if case .checkbox(let checked) = value { return checked }
        return false
      },
      set: { value = .checkbox($0) },
    )
  }

  private var selectBinding: Binding<UUID?> {
    Binding(
      get: {
        if case .select(let id) = value { return id }
        return nil
      },
      set: { value = .select($0) },
    )
  }

  private var multiSelectBinding: Binding<Set<UUID>> {
    Binding(
      get: {
        if case .multiSelect(let ids) = value { return ids }
        return []
      },
      set: { value = .multiSelect($0) },
    )
  }

  private var personBinding: Binding<IronPerson?> {
    Binding(
      get: {
        if case .person(let person) = value { return person }
        return nil
      },
      set: { value = .person($0) },
    )
  }

  private var urlBinding: Binding<URL?> {
    Binding(
      get: {
        if case .url(let url) = value { return url }
        return nil
      },
      set: { value = .url($0) },
    )
  }

  private var emailBinding: Binding<String> {
    Binding(
      get: {
        if case .email(let string) = value { return string }
        return ""
      },
      set: { value = .email($0) },
    )
  }

  private var phoneBinding: Binding<String> {
    Binding(
      get: {
        if case .phone(let string) = value { return string }
        return ""
      },
      set: { value = .phone($0) },
    )
  }
}

// MARK: - IronTextCell

/// A text cell with inline editing support.
struct IronTextCell: View {

  // MARK: Internal

  @Binding var value: String

  let isEditing: Bool

  var body: some View {
    if isEditing {
      TextField("", text: $value)
        .textFieldStyle(.plain)
        .font(theme.typography.bodyMedium)
    } else {
      if value.isEmpty {
        IronText("—", style: .bodyMedium, color: .placeholder)
      } else {
        IronText(value, style: .bodyMedium, color: .primary)
      }
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
}

// MARK: - IronNumberCell

/// A number cell with inline editing support.
struct IronNumberCell: View {

  // MARK: Internal

  @Binding var value: Double?

  let isEditing: Bool

  var body: some View {
    if isEditing {
      TextField("", value: $value, format: .number)
        .textFieldStyle(.plain)
        .font(theme.typography.bodyMedium)
      #if os(iOS)
        .keyboardType(.decimalPad)
      #endif
    } else {
      if let value {
        IronText(value.formatted(), style: .bodyMedium, color: .primary)
      } else {
        IronText("—", style: .bodyMedium, color: .placeholder)
      }
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
}

// MARK: - IronDateCell

/// A date cell with popover picker.
struct IronDateCell: View {

  // MARK: Internal

  @Binding var value: Date?

  let isEditing: Bool

  var body: some View {
    if isEditing {
      DatePicker(
        "",
        selection: dateBinding,
        displayedComponents: .date,
      )
      .datePickerStyle(.compact)
      .labelsHidden()
    } else {
      if let value {
        IronText(value.formatted(date: .abbreviated, time: .omitted), style: .bodyMedium, color: .primary)
      } else {
        IronText("—", style: .bodyMedium, color: .placeholder)
      }
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private var dateBinding: Binding<Date> {
    Binding(
      get: { value ?? Date() },
      set: { value = $0 },
    )
  }
}

// MARK: - IronCheckboxCell

/// A checkbox cell that toggles on tap.
struct IronCheckboxCell: View {

  // MARK: Internal

  @Binding var value: Bool

  var body: some View {
    Button {
      value.toggle()
    } label: {
      IronIcon(
        systemName: value ? "checkmark.square.fill" : "square",
        size: .medium,
        color: value ? .primary : .secondary,
      )
    }
    .buttonStyle(.plain)
    .accessibilityLabel(value ? "Checked" : "Unchecked")
    .accessibilityAddTraits(.isButton)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
}

// MARK: - IronSelectCell

/// A single-select cell with dropdown menu.
struct IronSelectCell: View {

  // MARK: Internal

  @Binding var value: UUID?

  let options: [IronSelectOption]
  let isEditing: Bool

  var body: some View {
    if isEditing {
      Menu {
        Button {
          value = nil
        } label: {
          IronText("Clear", style: .bodyMedium, color: .primary)
        }
        Divider()
        ForEach(options) { option in
          Button {
            value = option.id
          } label: {
            HStack {
              Circle()
                .fill(colorForOption(option))
                .frame(width: 8, height: 8)
              IronText(option.name, style: .bodyMedium, color: .primary)
              if value == option.id {
                IronIcon(systemName: "checkmark", size: .xSmall, color: .primary)
              }
            }
          }
        }
      } label: {
        selectLabel
      }
      .menuStyle(.button)
    } else {
      selectLabel
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private var selectedOption: IronSelectOption? {
    guard let value else { return nil }
    return options.first { $0.id == value }
  }

  @ViewBuilder
  private var selectLabel: some View {
    if let option = selectedOption {
      HStack(spacing: theme.spacing.xs) {
        Circle()
          .fill(colorForOption(option))
          .frame(width: 8, height: 8)
        IronText(option.name, style: .bodyMedium, color: .primary)
      }
      .padding(.horizontal, theme.spacing.sm)
      .padding(.vertical, theme.spacing.xs)
      .background(colorForOption(option).opacity(0.15))
      .clipShape(Capsule())
    } else {
      IronText("—", style: .bodyMedium, color: .placeholder)
    }
  }

  private func colorForOption(_ option: IronSelectOption) -> Color {
    switch option.color {
    case .primary: theme.colors.primary
    case .secondary: theme.colors.secondary
    case .success: theme.colors.success
    case .warning: theme.colors.warning
    case .error: theme.colors.error
    case .info: theme.colors.info
    case .accent: theme.colors.accent
    }
  }
}

// MARK: - IronMultiSelectCell

/// A multi-select cell with popover for selection.
struct IronMultiSelectCell: View {

  // MARK: Internal

  @Binding var value: Set<UUID>

  let options: [IronSelectOption]
  let isEditing: Bool

  var body: some View {
    if isEditing {
      Menu {
        ForEach(options) { option in
          Button {
            if value.contains(option.id) {
              value.remove(option.id)
            } else {
              value.insert(option.id)
            }
          } label: {
            HStack {
              Circle()
                .fill(colorForOption(option))
                .frame(width: 8, height: 8)
              IronText(option.name, style: .bodyMedium, color: .primary)
              if value.contains(option.id) {
                IronIcon(systemName: "checkmark", size: .xSmall, color: .primary)
              }
            }
          }
        }
      } label: {
        tagsView
      }
      .menuStyle(.button)
    } else {
      tagsView
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private var selectedOptions: [IronSelectOption] {
    options.filter { value.contains($0.id) }
  }

  @ViewBuilder
  private var tagsView: some View {
    if selectedOptions.isEmpty {
      IronText("—", style: .bodyMedium, color: .placeholder)
    } else {
      HStack(spacing: theme.spacing.xs) {
        ForEach(selectedOptions) { option in
          HStack(spacing: theme.spacing.xs) {
            Circle()
              .fill(colorForOption(option))
              .frame(width: 6, height: 6)
            IronText(option.name, style: .caption, color: .primary)
          }
          .padding(.horizontal, theme.spacing.sm)
          .padding(.vertical, 2)
          .background(colorForOption(option).opacity(0.15))
          .clipShape(Capsule())
        }
      }
    }
  }

  private func colorForOption(_ option: IronSelectOption) -> Color {
    switch option.color {
    case .primary: theme.colors.primary
    case .secondary: theme.colors.secondary
    case .success: theme.colors.success
    case .warning: theme.colors.warning
    case .error: theme.colors.error
    case .info: theme.colors.info
    case .accent: theme.colors.accent
    }
  }
}

// MARK: - IronPersonCell

/// A person cell with avatar display.
struct IronPersonCell: View {

  // MARK: Internal

  @Binding var value: IronPerson?

  let isEditing: Bool

  var body: some View {
    if let person = value {
      HStack(spacing: theme.spacing.sm) {
        // Avatar placeholder - could integrate with IronAvatar
        Circle()
          .fill(theme.colors.secondary.opacity(0.3))
          .frame(width: 24, height: 24)
          .overlay {
            IronText(String(person.name.prefix(1)).uppercased(), style: .caption, color: .primary)
          }
        IronText(person.name, style: .bodyMedium, color: .primary)
      }
    } else {
      IronText("—", style: .bodyMedium, color: .placeholder)
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
}

// MARK: - IronURLCell

/// A URL cell with link display and editing.
struct IronURLCell: View {

  // MARK: Internal

  @Binding var value: URL?

  let isEditing: Bool

  var body: some View {
    if isEditing {
      TextField("https://", text: urlStringBinding)
        .textFieldStyle(.plain)
        .font(theme.typography.bodyMedium)
      #if os(iOS)
        .keyboardType(.URL)
        .textContentType(.URL)
        .autocapitalization(.none)
      #endif
    } else {
      if let url = value {
        Link(destination: url) {
          HStack(spacing: theme.spacing.xs) {
            IronIcon(systemName: "link", size: .small, color: .info)
            IronText(url.host ?? url.absoluteString, style: .bodyMedium, color: .info)
          }
        }
      } else {
        IronText("—", style: .bodyMedium, color: .placeholder)
      }
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private var urlStringBinding: Binding<String> {
    Binding(
      get: { value?.absoluteString ?? "" },
      set: { value = URL(string: $0) },
    )
  }
}

// MARK: - IronEmailCell

/// An email cell with mailto link.
struct IronEmailCell: View {

  // MARK: Internal

  @Binding var value: String

  let isEditing: Bool

  var body: some View {
    if isEditing {
      TextField("email@example.com", text: $value)
        .textFieldStyle(.plain)
        .font(theme.typography.bodyMedium)
      #if os(iOS)
        .keyboardType(.emailAddress)
        .textContentType(.emailAddress)
        .autocapitalization(.none)
      #endif
    } else {
      if value.isEmpty {
        IronText("—", style: .bodyMedium, color: .placeholder)
      } else if let mailtoURL = URL(string: "mailto:\(value)") {
        Link(destination: mailtoURL) {
          HStack(spacing: theme.spacing.xs) {
            IronIcon(systemName: "envelope", size: .small, color: .info)
            IronText(value, style: .bodyMedium, color: .info)
          }
        }
      } else {
        IronText(value, style: .bodyMedium, color: .primary)
      }
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
}

// MARK: - IronPhoneCell

/// A phone cell with tel link.
struct IronPhoneCell: View {

  // MARK: Internal

  @Binding var value: String

  let isEditing: Bool

  var body: some View {
    if isEditing {
      TextField("+1 (555) 555-5555", text: $value)
        .textFieldStyle(.plain)
        .font(theme.typography.bodyMedium)
      #if os(iOS)
        .keyboardType(.phonePad)
        .textContentType(.telephoneNumber)
      #endif
    } else {
      if value.isEmpty {
        IronText("—", style: .bodyMedium, color: .placeholder)
      } else if let telURL = URL(string: "tel:\(value.filter { $0.isNumber || $0 == "+" })") {
        Link(destination: telURL) {
          HStack(spacing: theme.spacing.xs) {
            IronIcon(systemName: "phone", size: .small, color: .info)
            IronText(value, style: .bodyMedium, color: .info)
          }
        }
      } else {
        IronText(value, style: .bodyMedium, color: .primary)
      }
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
}

// MARK: - Previews

#Preview("Cell Types - Display") {
  let options = [
    IronSelectOption(name: "To Do", color: .secondary),
    IronSelectOption(name: "In Progress", color: .warning),
    IronSelectOption(name: "Done", color: .success),
  ]

  VStack(alignment: .leading, spacing: 16) {
    PreviewCellRow(label: "Text") {
      IronTextCell(value: .constant("Hello World"), isEditing: false)
    }
    PreviewCellRow(label: "Number") {
      IronNumberCell(value: .constant(42.5), isEditing: false)
    }
    PreviewCellRow(label: "Date") {
      IronDateCell(value: .constant(Date()), isEditing: false)
    }
    PreviewCellRow(label: "Checkbox") {
      IronCheckboxCell(value: .constant(true))
    }
    PreviewCellRow(label: "Select") {
      IronSelectCell(value: .constant(options[1].id), options: options, isEditing: false)
    }
    PreviewCellRow(label: "Multi-Select") {
      IronMultiSelectCell(
        value: .constant(Set([options[0].id, options[2].id])),
        options: options,
        isEditing: false,
      )
    }
    PreviewCellRow(label: "Person") {
      IronPersonCell(value: .constant(IronPerson(name: "John Doe")), isEditing: false)
    }
    PreviewCellRow(label: "URL") {
      IronURLCell(value: .constant(URL(string: "https://apple.com")), isEditing: false)
    }
    PreviewCellRow(label: "Email") {
      IronEmailCell(value: .constant("hello@example.com"), isEditing: false)
    }
    PreviewCellRow(label: "Phone") {
      IronPhoneCell(value: .constant("+1 (555) 123-4567"), isEditing: false)
    }
  }
  .padding()
}

#Preview("Cell Types - Empty") {
  VStack(alignment: .leading, spacing: 16) {
    PreviewCellRow(label: "Text") {
      IronTextCell(value: .constant(""), isEditing: false)
    }
    PreviewCellRow(label: "Number") {
      IronNumberCell(value: .constant(nil), isEditing: false)
    }
    PreviewCellRow(label: "Date") {
      IronDateCell(value: .constant(nil), isEditing: false)
    }
    PreviewCellRow(label: "Checkbox") {
      IronCheckboxCell(value: .constant(false))
    }
    PreviewCellRow(label: "Select") {
      IronSelectCell(value: .constant(nil), options: [], isEditing: false)
    }
    PreviewCellRow(label: "Multi-Select") {
      IronMultiSelectCell(value: .constant([]), options: [], isEditing: false)
    }
    PreviewCellRow(label: "Person") {
      IronPersonCell(value: .constant(nil), isEditing: false)
    }
    PreviewCellRow(label: "URL") {
      IronURLCell(value: .constant(nil), isEditing: false)
    }
    PreviewCellRow(label: "Email") {
      IronEmailCell(value: .constant(""), isEditing: false)
    }
    PreviewCellRow(label: "Phone") {
      IronPhoneCell(value: .constant(""), isEditing: false)
    }
  }
  .padding()
}

#Preview("Cell Types - Editing") {
  @Previewable @State var text = "Editable text"
  @Previewable @State var number: Double? = 123.45
  @Previewable @State var date: Date? = Date()
  @Previewable @State var url: URL? = URL(string: "https://apple.com")

  VStack(alignment: .leading, spacing: 16) {
    PreviewCellRow(label: "Text") {
      IronTextCell(value: $text, isEditing: true)
    }
    PreviewCellRow(label: "Number") {
      IronNumberCell(value: $number, isEditing: true)
    }
    PreviewCellRow(label: "Date") {
      IronDateCell(value: $date, isEditing: true)
    }
    PreviewCellRow(label: "URL") {
      IronURLCell(value: $url, isEditing: true)
    }
  }
  .padding()
}

// MARK: - PreviewCellRow

private struct PreviewCellRow<Content: View>: View {
  let label: String
  @ViewBuilder let content: () -> Content

  var body: some View {
    HStack {
      Text(label)
        .frame(width: 100, alignment: .trailing)
        .foregroundStyle(.secondary)
      content()
      Spacer()
    }
  }
}
