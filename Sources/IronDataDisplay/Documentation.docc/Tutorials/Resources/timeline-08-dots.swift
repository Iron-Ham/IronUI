import IronUI
import SwiftUI

// MARK: - ContentView

struct ContentView: View {
  let events = [
    (title: "Completed", date: Date(), node: IronTimelineNode.dot(color: .success)),
    (title: "In Progress", date: Date().addingTimeInterval(-86400), node: .dot(color: .warning)),
    (title: "Pending", date: Date().addingTimeInterval(-172800), node: .dot(color: .secondary)),
  ].map { Event(title: $0.title, date: $0.date, node: $0.node) }

  var body: some View {
    IronTimeline(entries: events) { event in
      IronTimelineEntry(
        title: LocalizedStringKey(event.title),
        timestamp: event.date,
        node: event.node, // Use colored dots
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
