import IronUI
import SwiftUI

struct ContentView: View {
  let events: [Event] = // ...

    var body: some View
  {
    // Trailing layout: content on left, timeline on right
    IronTimeline(
      entries: events,
      layout: .trailing,
    ) { event in
      IronTimelineEntry(
        title: LocalizedStringKey(event.title),
        timestamp: event.date,
      )
    }
    .padding()
  }
}
