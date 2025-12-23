import IronUI
import SwiftUI

struct ContentView: View {
  let events = [
    Event(title: "Project Started", subtitle: nil, date: Date()),
    Event(title: "First Milestone", subtitle: nil, date: Date().addingTimeInterval(-86400)),
    Event(title: "Beta Release", subtitle: nil, date: Date().addingTimeInterval(-172800)),
  ]

  var body: some View {
    IronTimeline(entries: events) { event in
      IronTimelineEntry(title: LocalizedStringKey(event.title))
    }
    .padding()
  }
}
