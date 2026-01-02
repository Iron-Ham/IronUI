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

  var body: some View {
    NavigationStack {
      ScrollView {
        if activities.isEmpty {
          emptyState
        } else {
          IronTimeline(
            entries: activities.sorted { $0.timestamp > $1.timestamp },
            layout: .leading,
            connectorStyle: .solid,
          ) { activity in
            activityEntry(for: activity)
          }
          .padding()
        }
      }
      .navigationTitle("Activity")
    }
  }

  // MARK: Private

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

  private func activityEntry(for activity: ChoreActivity) -> some View {
    IronTimelineEntry(
      node: nodeStyle(for: activity.activityType),
      timestamp: activity.timestamp,
      timestampFormat: .relative,
    ) {
      VStack(alignment: .leading, spacing: theme.spacing.xs) {
        HStack(spacing: theme.spacing.sm) {
          if let member = members.first(where: { $0.id == activity.performedById }) {
            IronAvatar(
              name: member.avatarEmoji,
              size: .small,
              backgroundColor: Color(hex: member.colorHex),
            )
            IronText(LocalizedStringKey(member.name), style: .labelMedium, color: .primary)
          }
          IronText(LocalizedStringKey(activity.activityType.displayName), style: .bodyMedium, color: .secondary)
        }

        IronText(LocalizedStringKey(activity.choreTitle), style: .bodyLarge, color: .primary)

        if let details = activity.details {
          IronText(LocalizedStringKey(details), style: .caption, color: .disabled)
        }
      }
      .padding(theme.spacing.sm)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(theme.colors.surfaceElevated)
      .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
    }
  }

  private func nodeStyle(for type: ChoreActivityType) -> IronTimelineNode {
    switch type {
    case .created:
      .icon(systemName: type.icon, color: .info)
    case .completed:
      .icon(systemName: type.icon, color: .success)
    case .uncompleted:
      .icon(systemName: type.icon, color: .warning)
    case .assigned:
      .icon(systemName: type.icon, color: .primary)
    case .statusChanged:
      .icon(systemName: type.icon, color: .secondary)
    case .edited:
      .icon(systemName: type.icon, color: .secondary)
    }
  }
}

#Preview("ActivityTimelineView") {
  ActivityTimelineView(
    activities: SampleData.activities,
    members: SampleData.members,
  )
  .ironTheme(IronDefaultTheme())
}

#Preview("ActivityTimelineView - Empty") {
  ActivityTimelineView(
    activities: [],
    members: SampleData.members,
  )
  .ironTheme(IronDefaultTheme())
}
