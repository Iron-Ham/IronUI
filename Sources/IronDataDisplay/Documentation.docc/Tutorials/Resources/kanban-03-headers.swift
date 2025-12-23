import IronUI
import SwiftUI

struct ContentView: View {

  // MARK: Internal

  var body: some View {
    IronKanban(
      columns: TaskStatus.allCases,
      items: $tasks,
      columnKeyPath: \.status,
    ) { task in
      IronText(task.title, style: .bodyMedium, color: .primary)
        .padding()
    } header: { status, count in
      // Custom header with title and badge
      HStack {
        IronText(status.rawValue, style: .titleSmall, color: .primary)
        Spacer()
        IronBadge(count: count, color: .secondary, size: .small)
      }
    }
  }

  // MARK: Private

  @State private var tasks: [Task] = // ...

}
