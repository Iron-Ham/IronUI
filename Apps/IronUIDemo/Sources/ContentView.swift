import IronUI
import SwiftUI

struct ContentView: View {
  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        IronText("IronUI Demo", style: .headline)
        IronText("Component showcase coming soon", style: .body)
      }
      .navigationTitle("IronUI Demo")
    }
  }
}
