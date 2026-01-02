import IronComponents
import IronCore
import IronPrimitives
import SQLiteData
import SwiftUI

// MARK: - FilterOption

enum FilterOption: Int, CaseIterable {
  case today = 0
  case thisWeek = 1
  case all = 2

  var title: String {
    switch self {
    case .today: "Today"
    case .thisWeek: "This Week"
    case .all: "All"
    }
  }
}

// MARK: - DashboardView

struct DashboardView: View {

  // MARK: Internal

  @FetchAll(Chore.order(by: \.dueDate)) var chores: [Chore]
  @FetchAll var members: [HouseholdMember]

  @Dependency(\.defaultDatabase) var database

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: theme.spacing.lg) {
          ProgressSummaryView(
            completed: completedToday.count,
            total: chores.count(where: { $0.isDueToday }),
          )

          IronSegmentedControl(
            selection: $selectedFilter,
            options: FilterOption.allCases,
          ) { option in
            Text(option.title)
          }
          .padding(.horizontal, theme.spacing.md)

          LazyVStack(spacing: theme.spacing.sm) {
            ForEach(filteredChores) { chore in
              ChoreCardView(
                chore: chore,
                member: members.first { $0.id == chore.assigneeId },
                onToggle: { toggleChore(chore) },
              )
              .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .scale(scale: 0.8).combined(with: .opacity),
              ))
            }
          }
          .padding(.horizontal, theme.spacing.md)
          .animation(.smooth, value: filteredChores.map(\.id))

          if filteredChores.isEmpty {
            emptyState
              .transition(.opacity.combined(with: .scale(scale: 0.95)))
          }
        }
        .padding(.vertical, theme.spacing.md)
      }
      .navigationTitle("Dashboard")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button("Add") {
            showAddChore = true
          }
        }
      }
      .sheet(isPresented: $showAddChore) {
        AddChoreSheet(isPresented: $showAddChore, members: members)
      }
      .ironConfetti(isActive: $showConfetti)
    }
    .onChange(of: allTodayDone) { _, newValue in
      if newValue {
        showConfetti = true
      }
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  @State private var selectedFilter = FilterOption.today
  @State private var showAddChore = false
  @State private var showConfetti = false

  private var filteredChores: [Chore] {
    switch selectedFilter {
    case .today:
      chores.filter { $0.isDueToday && !$0.isCompleted }
    case .thisWeek:
      chores.filter { $0.isDueThisWeek && !$0.isCompleted }
    case .all:
      chores.filter { !$0.isCompleted }
    }
  }

  private var completedToday: [Chore] {
    chores.filter { $0.isCompleted && $0.completedAt.map { Calendar.current.isDateInToday($0) } ?? false }
  }

  private var allTodayDone: Bool {
    let todayChores = chores.filter { $0.isDueToday }
    return !todayChores.isEmpty && todayChores.allSatisfy(\.isCompleted)
  }

  private var emptyState: some View {
    VStack(spacing: theme.spacing.md) {
      IronIcon(systemName: "checkmark.circle.fill", size: .xLarge)
        .foregroundStyle(theme.colors.success)

      IronText("All caught up!", style: .headlineMedium)

      IronText("No chores for this period", style: .bodyMedium)
        .foregroundStyle(theme.colors.textSecondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, theme.spacing.xxl)
  }

  private func toggleChore(_ chore: Chore) {
    withAnimation(.smooth) {
      try? database.write { db in
        try Chore
          .find(chore.id)
          .update {
            $0.isCompleted.toggle()
            $0.completedAt = !chore.isCompleted ? Date() : nil
          }
          .execute(db)
      }
    }
  }
}

#Preview {
  DashboardView()
    .ironTheme(IronDefaultTheme())
}
