import IronCore
import IronPrimitives
import SwiftUI

struct ContentView: View {

  // MARK: Internal

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab("Dashboard", systemImage: "house.fill", value: 0) {
        DashboardView()
      }

      Tab("Chores", systemImage: "checklist", value: 1) {
        ChoreListView()
      }

      Tab("Members", systemImage: "person.2.fill", value: 2) {
        MembersView()
      }

      Tab("Settings", systemImage: "gearshape.fill", value: 3) {
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
