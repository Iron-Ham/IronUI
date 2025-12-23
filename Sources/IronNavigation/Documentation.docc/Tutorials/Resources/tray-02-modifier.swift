import IronUI
import SwiftUI

struct ContentView: View {
  var body: some View {
    Button("Show Tray") {
      showTray = true
    }
    .ironTray(isPresented: $showTray) {
      Text("Tray Content")
    }
  }

  @State private var showTray = false

}
