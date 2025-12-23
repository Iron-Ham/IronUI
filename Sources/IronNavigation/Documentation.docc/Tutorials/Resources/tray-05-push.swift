import IronUI
import SwiftUI

struct ContentView: View {

  // MARK: Internal

  var body: some View {
    Button("Start Flow") {
      showTray = true
    }
    .ironTray(isPresented: $showTray) {
      IronTrayStack { navigator in
        // First step - shorter content
        VStack(spacing: 16) {
          IronTrayHeader("Step 1", onDismiss: { showTray = false })

          IronText("Welcome to the setup wizard.", style: .bodyMedium, color: .secondary)
            .padding(.horizontal)

          IronButton("Continue", variant: .filled) {
            navigator.push {
              // Second step - taller content
              VStack(spacing: 16) {
                IronTrayHeader("Step 2", showsBackButton: true, onDismiss: { navigator.pop() })

                IronText("Configure your preferences.", style: .bodyMedium, color: .secondary)
                  .padding(.horizontal)

                // More content here makes the tray taller
                ForEach(1...3, id: \.self) { i in
                  HStack {
                    IronText("Option \(i)", style: .bodyMedium, color: .primary)
                    Spacer()
                    IronToggle("", isOn: .constant(false))
                  }
                  .padding(.horizontal)
                }

                IronButton("Finish", variant: .filled) {
                  showTray = false
                }
                .padding(.bottom)
              }
            }
          }
          .padding(.bottom)
        }
      }
    }
  }

  // MARK: Private

  @State private var showTray = false

}
