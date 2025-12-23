import IronUI
import SwiftUI

struct ContentView: View {
  let events = [
    Event(title: "Project Started", subtitle: "Initial commit and project setup", date: Date()),
    Event(title: "First Milestone", subtitle: "Core features complete", date: Date().addingTimeInterval(-86400)),
    Event(title: "Beta Release", subtitle: "Public beta launched", date: Date().addingTimeInterval(-172800)),
  ]

  var body: some View {
    IronTimeline(entries: events) { event in
      IronTimelineEntry(
        title: LocalizedStringKey(event.title),
        subtitle: event.subtitle.map { LocalizedStringKey($0) },
        timestamp: event.date,
      )
    }
    .padding()
  }
}
