import IronUI
import SwiftUI

struct SecondStepView: View {
  let navigator: IronTrayNavigator
  @Binding var showTray: Bool

  var body: some View {
    VStack(spacing: 16) {
      // Use showsBackButton: true to show a back chevron
      IronTrayHeader("Step 2", showsBackButton: true, onDismiss: {
        // Call pop() to return to the previous step
        navigator.pop()
      })

      IronText("Configure your preferences.", style: .bodyMedium, color: .secondary)
        .padding(.horizontal)

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
