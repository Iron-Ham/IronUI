import IronUI
import SwiftUI

struct ContentView: View {
  let events: [Event] = // ...

    var body: some View
  {
    // Leading layout: timeline on left, content on right
    IronTimeline(
      entries: events,
      layout: .leading,
    ) { event in
      IronTimelineEntry(
        title: LocalizedStringKey(event.title),
        timestamp: event.date,
      )
    }
    .padding()
  }
}
