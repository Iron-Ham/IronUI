import IronComponents
import IronCore
import IronDataDisplay
import IronNavigation
import IronPrimitives
import SQLiteData
import SwiftUI

// MARK: - ChoreViewMode

enum ChoreViewMode: String, CaseIterable {
  case list = "List"
  case board = "Board"

  // MARK: Internal

  var icon: String {
    switch self {
    case .list: "list.bullet"
    case .board: "rectangle.split.3x1"
    }
  }
}

// MARK: - ChoreListView

struct ChoreListView: View {

  // MARK: Internal

  @FetchAll(Chore.order(by: \.dueDate)) var chores: [Chore]

  @FetchAll var members: [HouseholdMember]

  @Dependency(\.defaultDatabase) var database

  var body: some View {
    NavigationStack {
      choreContent
        .navigationTitle("Chores")
        .toolbar { addChoreToolbar }
        .sheet(isPresented: $showAddChore) {
          AddChoreSheet(isPresented: $showAddChore, members: members)
        }
        .sheet(item: $choreToEdit) { chore in
          editChoreSheet(for: chore)
        }
        .onChange(of: chores) { _, newChores in
          boardChores = newChores
        }
        .onChange(of: boardChores) { oldChores, newChores in
          syncBoardChangesToDatabase(oldChores: oldChores, newChores: newChores)
        }
        .onAppear {
          boardChores = chores
        }
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  @State private var viewMode = ChoreViewMode.list
  @State private var showAddChore = false
  @State private var choreToEdit: Chore?
  @State private var boardChores = [Chore]()

  private var choreContent: some View {
    VStack(spacing: 0) {
      viewModePicker

      switch viewMode {
      case .list:
        listView
      case .board:
        boardView
      }
    }
  }

  @ToolbarContentBuilder
  private var addChoreToolbar: some ToolbarContent {
    ToolbarItem(placement: .primaryAction) {
      Button("Add") {
        showAddChore = true
      }
    }
  }

  private var pendingChores: [Chore] {
    chores.filter { !$0.isCompleted }
  }

  private var completedChores: [Chore] {
    chores.filter(\.isCompleted)
  }

  private var viewModePicker: some View {
    IronSegmentedControl(
      selection: $viewMode,
      options: ChoreViewMode.allCases,
      size: .medium,
    ) { mode in
      HStack(spacing: theme.spacing.xs) {
        IronIcon(systemName: mode.icon, size: .small, color: .inherit)
        IronText(LocalizedStringKey(mode.rawValue), style: .labelMedium, color: .primary)
      }
    }
    .padding(.horizontal, theme.spacing.md)
    .padding(.vertical, theme.spacing.sm)
  }

  private var listView: some View {
    List {
      Section("Pending") {
        ForEach(pendingChores) { chore in
          ChoreRow(
            chore: chore,
            member: members.first { $0.id == chore.assigneeId },
            showCheckbox: true,
            showEditButton: true,
            onToggle: { toggleChore(chore) },
            onEdit: { choreToEdit = chore },
          )
          .padding(.vertical, theme.spacing.xs)
        }
        .onDelete { indexSet in
          deleteChores(at: indexSet, from: pendingChores)
        }
      }

      Section("Completed") {
        ForEach(completedChores) { chore in
          ChoreRow(
            chore: chore,
            member: members.first { $0.id == chore.assigneeId },
            showCheckbox: true,
            showEditButton: true,
            onToggle: { toggleChore(chore) },
            onEdit: { choreToEdit = chore },
          )
          .padding(.vertical, theme.spacing.xs)
        }
        .onDelete { indexSet in
          deleteChores(at: indexSet, from: completedChores)
        }
      }
    }
    .animation(.smooth, value: chores.map(\.isCompleted))
  }

  private var boardView: some View {
    ChoreBoardView(chores: $boardChores, members: members)
  }

  private func editChoreSheet(for chore: Chore) -> some View {
    AddChoreSheet(
      isPresented: Binding(
        get: { choreToEdit != nil },
        set: { if !$0 { choreToEdit = nil } },
      ),
      members: members,
      choreToEdit: chore,
    )
  }

  private func syncBoardChangesToDatabase(oldChores: [Chore], newChores: [Chore]) {
    for newChore in newChores {
      if
        let oldChore = oldChores.first(where: { $0.id == newChore.id }),
        oldChore.status != newChore.status
      {
        try? database.write { db in
          try Chore
            .find(newChore.id)
            .update {
              $0.status = newChore.status
              if newChore.status == .done {
                $0.isCompleted = true
                $0.completedAt = Date()
              } else if oldChore.status == .done {
                $0.isCompleted = false
                $0.completedAt = nil
              }
            }
            .execute(db)
        }
      }
    }
  }

  private func toggleChore(_ chore: Chore) {
    withAnimation(.smooth) {
      try? database.write { db in
        try Chore
          .find(chore.id)
          .update {
            $0.isCompleted.toggle()
            $0.completedAt = !chore.isCompleted ? Date() : nil
            $0.status = !chore.isCompleted ? .done : .todo
          }
          .execute(db)
      }
    }
  }

  private func deleteChore(_ chore: Chore) {
    try? database.write { db in
      try Chore.delete(chore).execute(db)
    }
  }

  private func deleteChores(at indexSet: IndexSet, from choreList: [Chore]) {
    for index in indexSet {
      deleteChore(choreList[index])
    }
  }
}

#Preview {
  ChoreListView()
    .ironTheme(IronDefaultTheme())
}
