import IronUI
import SwiftUI

struct ContentView: View {
  var body: some View {
    Button("Show Tray") {
      showTray = true
    }
    .ironTray(isPresented: $showTray) {
      // Hide the drag indicator for a cleaner look
      IronTray(showsDragIndicator: false) {
        VStack(spacing: 16) {
          IronTrayHeader("Clean Tray", onDismiss: { showTray = false })
          IronText("No drag indicator shown.", style: .bodyMedium, color: .secondary)
            .padding()
        }
      }
    }
  }

  @State private var showTray = false

}
