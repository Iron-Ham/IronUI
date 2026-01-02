import IronCore
import IronPrimitives
import SwiftUI

struct ProgressSummaryView: View {

  // MARK: Internal

  let completed: Int
  let total: Int

  var body: some View {
    VStack(spacing: theme.spacing.sm) {
      HStack {
        IronText("Today's Progress", style: .headlineSmall)
        Spacer()
        IronText(progressText, style: .bodyMedium)
          .foregroundStyle(theme.colors.textSecondary)
      }

      IronProgress(value: progress, color: completed == total ? .success : .primary)
    }
    .padding(theme.spacing.md)
    .background(theme.colors.surfaceElevated)
    .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
    .padding(.horizontal, theme.spacing.md)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private var progress: Double {
    guard total > 0 else { return 0 }
    return Double(completed) / Double(total)
  }

  private var progressText: String {
    if total == 0 {
      "No chores today"
    } else if completed == total {
      "All done!"
    } else {
      "\(completed) of \(total) completed"
    }
  }

}

#Preview {
  VStack(spacing: 20) {
    ProgressSummaryView(completed: 0, total: 5)
    ProgressSummaryView(completed: 3, total: 5)
    ProgressSummaryView(completed: 5, total: 5)
    ProgressSummaryView(completed: 0, total: 0)
  }
  .padding()
  .ironTheme(IronDefaultTheme())
}
