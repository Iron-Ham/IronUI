import IronCore
import IronPrimitives
import SQLiteData
import SwiftUI

struct ContentView: View {

  // MARK: Internal

  @FetchAll var members: [HouseholdMember]

  @FetchAll var activities: [ChoreActivity]

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab("Dashboard", systemImage: "house.fill", value: 0) {
        DashboardView()
      }

      Tab("Chores", systemImage: "checklist", value: 1) {
        ChoreListView()
      }

      Tab("Activity", systemImage: "clock.arrow.circlepath", value: 2) {
        ActivityTimelineView(activities: activities, members: members)
      }

      Tab("Members", systemImage: "person.2.fill", value: 3) {
        MembersView()
      }

      Tab("Settings", systemImage: "gearshape.fill", value: 4) {
        SettingsView()
      }
    }
  }

  // MARK: Private

  @State private var selectedTab = 0

}

#Preview {
  ContentView()
    .ironTheme(IronDefaultTheme())
}
