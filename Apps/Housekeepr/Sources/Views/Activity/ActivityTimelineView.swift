import IronComponents
import IronCore
import IronDataDisplay
import IronPrimitives
import SQLiteData
import SwiftUI

/// A chronological timeline of chore activities
struct ActivityTimelineView: View {

  // MARK: Internal

  let activities: [ChoreActivity]
  let members: [HouseholdMember]
  let chores: [Chore]

  var body: some View {
    NavigationStack {
      ScrollView {
        if activities.isEmpty {
          emptyState
        } else {
          LazyVStack(spacing: 0) {
            ForEach(activities.sorted { $0.timestamp > $1.timestamp }) { activity in
              activityRow(for: activity)
              IronDivider()
            }
          }
        }
      }
      .navigationTitle("Activity")
    }
  }

  // MARK: Private

  /// Static formatter for relative timestamps (avoids SwiftUI Text(date, style: .relative) bug)
  private static let relativeFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter
  }()

  @Environment(\.ironTheme) private var theme

  private var emptyState: some View {
    VStack(spacing: theme.spacing.lg) {
      IronIcon(systemName: "clock.arrow.circlepath", size: .xLarge, color: .secondary)
      IronText("No activity yet", style: .titleMedium, color: .secondary)
      IronText("Chore completions and updates will appear here", style: .bodyMedium, color: .disabled)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(theme.spacing.xxl)
  }

  private func activityRow(for activity: ChoreActivity) -> some View {
    let performer = members.first { $0.id == activity.performedById }
    let chore = chores.first { $0.id == activity.choreId }

    return HStack(alignment: .top, spacing: theme.spacing.md) {
      // Avatar with action badge
      if let member = performer {
        IronAvatar(
          name: member.avatarEmoji,
          size: .medium,
          backgroundColor: Color(hex: member.colorHex)?.opacity(0.2),
        ) {
          IronAvatarBadge(backgroundColor: badgeColor(for: activity.activityType)) {
            Image(systemName: activity.activityType.icon)
              .resizable()
              .scaledToFit()
              .foregroundStyle(.white)
              .padding(3)
          }
        }
      }

      // Activity content
      VStack(alignment: .leading, spacing: theme.spacing.sm) {
        // Activity text + timestamp
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
          activityText(for: activity, performer: performer)
            .fixedSize(horizontal: false, vertical: true)

          Text(Self.relativeFormatter.localizedString(for: activity.timestamp, relativeTo: Date()))
            .font(theme.typography.caption)
            .foregroundStyle(theme.colors.textDisabled)
        }

        // Chore preview card (like GitHub's PR/issue preview)
        if let chore {
          chorePreviewCard(chore: chore, activity: activity)
        }
      }

      Spacer(minLength: 0)
    }
    .padding(.horizontal, theme.spacing.md)
    .padding(.vertical, theme.spacing.sm)
  }

  private func chorePreviewCard(chore: Chore, activity _: ChoreActivity) -> some View {
    VStack(alignment: .leading, spacing: theme.spacing.xs) {
      // Title row with status icon
      HStack(spacing: theme.spacing.xs) {
        Image(systemName: statusIcon(for: chore))
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(statusColor(for: chore))

        Text(chore.title)
          .font(theme.typography.labelMedium)
          .foregroundStyle(theme.colors.textPrimary)
          .lineLimit(1)
      }

      // Category + Assignee row
      HStack(spacing: theme.spacing.sm) {
        // Category chip
        HStack(spacing: theme.spacing.xxs) {
          Image(systemName: chore.category.icon)
            .font(.system(size: 10))
          Text(chore.category.displayName)
            .font(theme.typography.caption)
        }
        .foregroundStyle(chore.category.color)
        .padding(.horizontal, theme.spacing.xs)
        .padding(.vertical, 2)
        .background(chore.category.color.opacity(0.15))
        .clipShape(Capsule())

        // Assignee if present
        if
          let assigneeId = chore.assigneeId,
          let assignee = members.first(where: { $0.id == assigneeId })
        {
          HStack(spacing: theme.spacing.xxs) {
            Text(assignee.avatarEmoji)
              .font(.system(size: 10))
            Text(assignee.name)
              .font(theme.typography.caption)
              .foregroundStyle(theme.colors.textSecondary)
          }
        }

        Spacer()

        // Due date if present
        if let dueDate = chore.dueDate {
          HStack(spacing: theme.spacing.xxs) {
            Image(systemName: "calendar")
              .font(.system(size: 10))
            Text(dueDate, style: .date)
              .font(theme.typography.caption)
          }
          .foregroundStyle(chore.isOverdue ? theme.colors.error : theme.colors.textSecondary)
        }
      }
    }
    .padding(theme.spacing.sm)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(theme.colors.surface)
    .clipShape(RoundedRectangle(cornerRadius: theme.radii.sm))
    .overlay(
      RoundedRectangle(cornerRadius: theme.radii.sm)
        .strokeBorder(theme.colors.border, lineWidth: 1)
    )
  }

  private func statusIcon(for chore: Chore) -> String {
    if chore.isCompleted {
      return "checkmark.circle.fill"
    }
    switch chore.status {
    case .todo: return "circle"
    case .inProgress: return "circle.dotted"
    case .done: return "checkmark.circle.fill"
    }
  }

  private func statusColor(for chore: Chore) -> Color {
    if chore.isCompleted {
      return theme.colors.success
    }
    switch chore.status {
    case .todo: return theme.colors.textSecondary
    case .inProgress: return theme.colors.warning
    case .done: return theme.colors.success
    }
  }

  @ViewBuilder
  private func activityText(for activity: ChoreActivity, performer: HouseholdMember?) -> some View {
    let performerName = performer?.name ?? "Someone"

    // Build inline attributed text based on activity type
    switch activity.activityType {
    case .created:
      Text("\(Text(performerName).bold()) created a chore")
        .font(theme.typography.bodyMedium)
        .foregroundStyle(theme.colors.textPrimary)

    case .completed:
      Text("\(Text(performerName).bold()) completed a chore")
        .font(theme.typography.bodyMedium)
        .foregroundStyle(theme.colors.textPrimary)

    case .uncompleted:
      Text("\(Text(performerName).bold()) reopened a chore")
        .font(theme.typography.bodyMedium)
        .foregroundStyle(theme.colors.textPrimary)

    case .assigned:
      if let details = activity.details, let assignee = members.first(where: { details.contains($0.name) }) {
        Text("\(Text(performerName).bold()) assigned a chore to \(Text(assignee.name).bold())")
          .font(theme.typography.bodyMedium)
          .foregroundStyle(theme.colors.textPrimary)
      } else {
        Text("\(Text(performerName).bold()) assigned a chore")
          .font(theme.typography.bodyMedium)
          .foregroundStyle(theme.colors.textPrimary)
      }

    case .statusChanged:
      if let details = activity.details {
        Text("\(Text(performerName).bold()) moved a chore to \(Text(details).bold())")
          .font(theme.typography.bodyMedium)
          .foregroundStyle(theme.colors.textPrimary)
      } else {
        Text("\(Text(performerName).bold()) updated chore status")
          .font(theme.typography.bodyMedium)
          .foregroundStyle(theme.colors.textPrimary)
      }

    case .edited:
      Text("\(Text(performerName).bold()) edited a chore")
        .font(theme.typography.bodyMedium)
        .foregroundStyle(theme.colors.textPrimary)
    }
  }

  private func badgeColor(for type: ChoreActivityType) -> Color {
    switch type {
    case .created: theme.colors.info
    case .completed: theme.colors.success
    case .uncompleted: theme.colors.warning
    case .assigned: theme.colors.primary
    case .statusChanged: theme.colors.secondary
    case .edited: theme.colors.secondary
    }
  }
}

#Preview("ActivityTimelineView") {
  ActivityTimelineView(
    activities: SampleData.activities,
    members: SampleData.members,
    chores: SampleData.chores,
  )
  .ironTheme(IronDefaultTheme())
}

#Preview("ActivityTimelineView - Empty") {
  ActivityTimelineView(
    activities: [],
    members: SampleData.members,
    chores: SampleData.chores,
  )
  .ironTheme(IronDefaultTheme())
}
