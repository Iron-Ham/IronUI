import IronUI
import SwiftUI

struct ContentView: View {

  // MARK: Internal

  var body: some View {
    Button("Show Tray") {
      showTray = true
    }
    .ironTray(isPresented: $showTray) {
      VStack(spacing: 16) {
        IronTrayHeader("Welcome", onDismiss: { showTray = false })

        IronText("This tray sizes to fit its content.", style: .bodyMedium, color: .secondary)
          .padding(.horizontal)

        IronButton("Got it", variant: .filled) {
          showTray = false
        }
        .padding(.bottom)
      }
    }
  }

  // MARK: Private

  @State private var showTray = false

}
