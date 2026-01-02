import IronComponents
import IronCore
import IronPrimitives
import SwiftUI

/// A reusable chore row component that can be styled for different contexts.
struct ChoreRow: View {

  // MARK: Internal

  let chore: Chore
  var member: HouseholdMember?
  var showCheckbox = true
  var showEditButton = false
  var onToggle: (() -> Void)?
  var onEdit: (() -> Void)?

  var body: some View {
    HStack(alignment: .top, spacing: theme.spacing.md) {
      if showCheckbox {
        IronCheckbox(
          isChecked: Binding(
            get: { chore.isCompleted },
            set: { _ in onToggle?() },
          )
        )
      } else {
        IronIcon(systemName: chore.category.icon, size: .medium)
          .foregroundStyle(chore.category.color)
      }

      VStack(alignment: .leading, spacing: theme.spacing.xs) {
        // Title row
        HStack(alignment: .top) {
          IronText(chore.title, style: .bodyLarge)
            .strikethrough(chore.isCompleted)
            .foregroundStyle(chore.isCompleted ? theme.colors.textDisabled : theme.colors.textPrimary)

          Spacer()

          if chore.isOverdue, !chore.isCompleted {
            IronBadge("Overdue", style: .soft, color: .error, size: .small)
          }
        }

        // Secondary info row - category and due date
        HStack(spacing: theme.spacing.xs) {
          IronIcon(systemName: chore.category.icon, size: .small)
            .foregroundStyle(chore.category.color)

          IronText(chore.category.displayName, style: .bodySmall)
            .foregroundStyle(theme.colors.textSecondary)

          if let dueDate = chore.dueDate {
            Text("•")
              .foregroundStyle(theme.colors.textDisabled)

            IronText(formatDueDate(dueDate), style: .bodySmall)
              .foregroundStyle(chore.isOverdue ? theme.colors.error : theme.colors.textSecondary)
          }
        }

        // Member row - separate line for better layout
        if let member {
          HStack(spacing: theme.spacing.xs) {
            ZStack {
              Circle()
                .fill(member.color.opacity(0.2))
                .frame(width: 20, height: 20)

              Text(member.avatarEmoji)
                .font(.system(size: 10))
            }

            IronText(member.name, style: .bodySmall)
              .foregroundStyle(theme.colors.textSecondary)
          }
        }
      }

      if showEditButton {
        Button {
          onEdit?()
        } label: {
          IronIcon(systemName: "ellipsis", size: .small)
            .foregroundStyle(theme.colors.textSecondary)
        }
        .buttonStyle(.plain)
      }
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private func formatDueDate(_ date: Date) -> String {
    if Calendar.current.isDateInToday(date) {
      return "Today"
    } else if Calendar.current.isDateInTomorrow(date) {
      return "Tomorrow"
    } else if Calendar.current.isDateInYesterday(date) {
      return "Yesterday"
    } else {
      let formatter = DateFormatter()
      formatter.dateStyle = .short
      return formatter.string(from: date)
    }
  }
}

#Preview("With Checkbox") {
  VStack(spacing: 16) {
    ChoreRow(
      chore: Chore(
        title: "Do the dishes",
        category: .kitchen,
        dueDate: Date(),
      ),
      member: HouseholdMember(name: "Alex", avatarEmoji: "🧑‍💻"),
      showCheckbox: true,
      showEditButton: true,
    )

    ChoreRow(
      chore: Chore(
        title: "Vacuum living room",
        category: .general,
        dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
        isCompleted: false,
      ),
      member: HouseholdMember(name: "Jordan", avatarEmoji: "🎨"),
      showCheckbox: true,
    )

    ChoreRow(
      chore: Chore(
        title: "Completed task",
        category: .laundry,
        isCompleted: true,
      ),
      showCheckbox: true,
    )
  }
  .padding()
  .ironTheme(IronDefaultTheme())
}

#Preview("Without Checkbox") {
  VStack(spacing: 16) {
    ChoreRow(
      chore: Chore(
        title: "Pending chore",
        category: .outdoor,
        dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
      ),
      showCheckbox: false,
    )
  }
  .padding()
  .ironTheme(IronDefaultTheme())
}
