import IronComponents
import IronCore
import IronPrimitives
import SwiftUI

/// Dashboard-specific chore card that wraps ChoreRow in a styled card container.
struct ChoreCardView: View {

  // MARK: Internal

  let chore: Chore
  let member: HouseholdMember?
  let onToggle: () -> Void

  var body: some View {
    IronCard(style: .outlined) {
      ChoreRow(
        chore: chore,
        member: member,
        showCheckbox: true,
        showEditButton: false,
        onToggle: onToggle,
      )
      .padding(theme.spacing.md)
    }
    .ironRipple()
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

}

#Preview {
  VStack {
    ChoreCardView(
      chore: Chore(
        title: "Do the dishes",
        notes: "Don't forget pots",
        category: .kitchen,
        dueDate: Date(),
      ),
      member: HouseholdMember(name: "Alex", avatarEmoji: "🧑‍💻"),
      onToggle: { },
    )

    ChoreCardView(
      chore: Chore(
        title: "Vacuum living room",
        category: .general,
        dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
        isCompleted: false,
      ),
      member: nil,
      onToggle: { },
    )
  }
  .padding()
  .ironTheme(IronDefaultTheme())
}
