import IronUI
import SwiftUI

struct ContentView: View {
  let events: [Event] = // ...

    var body: some View
  {
    VStack(spacing: 32) {
      // Solid connector (default)
      IronTimeline(entries: events, connectorStyle: .solid) { event in
        IronTimelineEntry(title: LocalizedStringKey(event.title))
      }

      // Dashed connector
      IronTimeline(entries: events, connectorStyle: .dashed) { event in
        IronTimelineEntry(title: LocalizedStringKey(event.title))
      }

      // Dotted connector
      IronTimeline(entries: events, connectorStyle: .dotted) { event in
        IronTimelineEntry(title: LocalizedStringKey(event.title))
      }
    }
    .padding()
  }
}
