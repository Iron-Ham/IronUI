import IronUI
import SwiftUI

struct ContentView: View {

  // MARK: Internal

  var body: some View {
    Button("Edit Settings") {
      showTray = true
    }
    .ironTray(isPresented: $showTray) {
      IronTray(onDismiss: {
        // Handle dismissal - save changes, cleanup, etc.
        if hasUnsavedChanges {
          saveChanges()
        }
      }) {
        VStack(spacing: 16) {
          IronTrayHeader("Settings", onDismiss: { showTray = false })

          IronToggle("Enable Feature", isOn: $hasUnsavedChanges)
            .padding(.horizontal)

          IronButton("Save", variant: .filled) {
            saveChanges()
            showTray = false
          }
          .padding(.bottom)
        }
      }
    }
  }

  // MARK: Private

  @State private var showTray = false
  @State private var hasUnsavedChanges = false

  private func saveChanges() {
    // Persist changes
  }
}
