import IronUI
import SwiftUI

struct ContentView: View {
  let events: [Event] = // ...

    var body: some View
  {
    // Alternating layout: content switches sides
    IronTimeline(
      entries: events,
      layout: .alternating,
    ) { event in
      IronTimelineEntry(
        title: LocalizedStringKey(event.title),
        subtitle: event.subtitle.map { LocalizedStringKey($0) },
        timestamp: event.date,
      )
    }
    .padding()
  }
}
