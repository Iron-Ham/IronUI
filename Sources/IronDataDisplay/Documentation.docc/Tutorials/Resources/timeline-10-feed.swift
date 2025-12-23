import IronUI
import SwiftUI

// MARK: - ActivityFeed

struct ActivityFeed: View {
  let activities: [Activity] = [
    Activity(
      title: "John commented on your post",
      description: "Great work on this feature!",
      date: Date(),
      node: .icon(systemName: "bubble.left.fill", color: .info),
    ),
    Activity(
      title: "Pull request merged",
      description: "feat: Add timeline component",
      date: Date().addingTimeInterval(-3600),
      node: .icon(systemName: "arrow.triangle.merge", color: .success),
    ),
    Activity(
      title: "Build completed",
      description: nil,
      date: Date().addingTimeInterval(-7200),
      node: .icon(systemName: "checkmark.circle.fill", color: .success),
    ),
    Activity(
      title: "New issue opened",
      description: "Bug: Timeline alignment issue",
      date: Date().addingTimeInterval(-14400),
      node: .icon(systemName: "exclamationmark.circle.fill", color: .warning),
    ),
    Activity(
      title: "Release published",
      description: "v1.0.0 - Initial Release",
      date: Date().addingTimeInterval(-86400),
      node: .icon(systemName: "tag.fill", color: .primary),
    ),
  ]

  var body: some View {
    ScrollView {
      IronTimeline(
        entries: activities,
        layout: .leading,
        connectorStyle: .solid,
      ) { activity in
        IronTimelineEntry(
          title: LocalizedStringKey(activity.title),
          subtitle: activity.description.map { LocalizedStringKey($0) },
          timestamp: activity.date,
          node: activity.node,
        )
      }
      .padding()
    }
  }

}

// MARK: - Activity

struct Activity: Identifiable {
  let id = UUID()
  let title: String
  let description: String?
  let date: Date
  let node: IronTimelineNode
}
