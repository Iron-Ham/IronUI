import IronUI
import SwiftUI

// MARK: - ContentView

struct ContentView: View {
  let events = [
    (title: "Build Succeeded", date: Date(), node: IronTimelineNode.icon(systemName: "checkmark.circle.fill", color: .success)),
    (title: "Tests Running", date: Date().addingTimeInterval(-86400), node: .icon(systemName: "clock.fill", color: .warning)),
    (
      title: "Build Failed",
      date: Date().addingTimeInterval(-172800),
      node: .icon(systemName: "xmark.circle.fill", color: .error),
    ),
    (title: "Deployed", date: Date().addingTimeInterval(-259200), node: .icon(systemName: "rocket.fill", color: .info)),
  ].map { Event(title: $0.title, date: $0.date, node: $0.node) }

  var body: some View {
    IronTimeline(entries: events) { event in
      IronTimelineEntry(
        title: LocalizedStringKey(event.title),
        timestamp: event.date,
        node: event.node, // Use SF Symbol icons
      )
    }
    .padding()
  }

}

// MARK: - Event

struct Event: Identifiable {
  let id = UUID()
  let title: String
  let date: Date
  let node: IronTimelineNode
}
