import IronUI
import SwiftUI

struct ContentView: View {

  // MARK: Internal

  var body: some View {
    Button("Start Flow") {
      showTray = true
    }
    .ironTray(isPresented: $showTray) {
      IronTrayStack { _ in
        // First step
        VStack(spacing: 16) {
          IronTrayHeader("Step 1", onDismiss: { showTray = false })

          IronText("Welcome to the setup wizard.", style: .bodyMedium, color: .secondary)
            .padding(.horizontal)

          IronButton("Continue", variant: .filled) {
            // Navigate to next step
          }
          .padding(.bottom)
        }
      }
    }
  }

  // MARK: Private

  @State private var showTray = false

}
