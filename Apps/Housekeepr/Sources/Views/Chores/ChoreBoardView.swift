import IronComponents
import IronCore
import IronDataDisplay
import IronPrimitives
import SQLiteData
import SwiftUI

/// Kanban-style board view for managing chores by status
struct ChoreBoardView: View {

  // MARK: Internal

  @Binding var chores: [Chore]

  let members: [HouseholdMember]

  var body: some View {
    IronKanban(
      columns: ChoreStatus.allCases,
      items: $chores,
      columnKeyPath: \.status,
      spacing: .standard,
    ) { chore in
      choreCard(for: chore)
    } header: { status, count in
      columnHeader(status: status, count: count)
    } emptyState: { status in
      emptyColumn(for: status)
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private func choreCard(for chore: Chore) -> some View {
    IronKanbanCard(priority: priority(for: chore)) {
      VStack(alignment: .leading, spacing: theme.spacing.xs) {
        IronText(LocalizedStringKey(chore.title), style: .bodyMedium, color: .primary)

        HStack(spacing: theme.spacing.xs) {
          IronChip(
            LocalizedStringKey(chore.category.displayName),
            icon: chore.category.icon,
            variant: .outlined,
            size: .small,
          )

          Spacer()

          if let assignee = members.first(where: { $0.id == chore.assigneeId }) {
            IronAvatar(
              name: assignee.avatarEmoji,
              size: .small,
              backgroundColor: Color(hex: assignee.colorHex),
            )
          }
        }

        if let dueDate = chore.dueDate {
          HStack(spacing: theme.spacing.xxs) {
            IronIcon(systemName: "calendar", size: .xSmall, color: dueDateColor(for: chore))
            IronText(
              LocalizedStringKey(formattedDueDate(dueDate)),
              style: .caption,
              color: dueDateTextColor(for: chore),
            )
          }
        }
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(chore.title)
    .accessibilityHint("Drag to move between columns")
  }

  private func columnHeader(status: ChoreStatus, count: Int) -> some View {
    HStack(spacing: theme.spacing.sm) {
      IronIcon(systemName: statusIcon(for: status), size: .small, color: statusColor(for: status))
      IronText(LocalizedStringKey(status.rawValue), style: .titleSmall, color: .primary)
      Spacer()
      IronBadge(count: count, color: .secondary, size: .small)
    }
  }

  private func emptyColumn(for status: ChoreStatus) -> some View {
    VStack(spacing: theme.spacing.sm) {
      IronIcon(systemName: emptyIcon(for: status), size: .large, color: .secondary)
      IronText(emptyMessage(for: status), style: .bodyMedium, color: .secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(theme.spacing.lg)
    .background(
      RoundedRectangle(cornerRadius: theme.radii.sm)
        .strokeBorder(theme.colors.border, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
    )
  }

  private func priority(for chore: Chore) -> IronKanbanPriority {
    if chore.isOverdue {
      return .urgent
    }
    if chore.isDueToday {
      return .high
    }
    if chore.isDueThisWeek {
      return .medium
    }
    return .none
  }

  private func statusIcon(for status: ChoreStatus) -> String {
    switch status {
    case .todo: "circle"
    case .inProgress: "circle.dotted"
    case .done: "checkmark.circle.fill"
    }
  }

  private func statusColor(for status: ChoreStatus) -> IronIconColor {
    switch status {
    case .todo: .secondary
    case .inProgress: .warning
    case .done: .success
    }
  }

  private func emptyIcon(for status: ChoreStatus) -> String {
    switch status {
    case .todo: "sparkles"
    case .inProgress: "figure.walk"
    case .done: "party.popper"
    }
  }

  private func emptyMessage(for status: ChoreStatus) -> LocalizedStringKey {
    switch status {
    case .todo: "No chores waiting"
    case .inProgress: "Nothing in progress"
    case .done: "Complete some chores!"
    }
  }

  private func dueDateColor(for chore: Chore) -> IronIconColor {
    if chore.isOverdue { return .error }
    if chore.isDueToday { return .warning }
    return .secondary
  }

  private func dueDateTextColor(for chore: Chore) -> IronTextColor {
    if chore.isOverdue { return .error }
    if chore.isDueToday { return .warning }
    return .secondary
  }

  private func formattedDueDate(_ date: Date) -> String {
    if Calendar.current.isDateInToday(date) {
      return "Today"
    }
    if Calendar.current.isDateInTomorrow(date) {
      return "Tomorrow"
    }
    return date.formatted(date: .abbreviated, time: .omitted)
  }
}

#Preview("ChoreBoardView") {
  @Previewable @State var chores = SampleData.chores

  ChoreBoardView(chores: $chores, members: SampleData.members)
    .ironTheme(IronDefaultTheme())
}
