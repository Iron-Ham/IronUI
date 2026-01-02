import IronComponents
import IronCore
import IronNavigation
import IronPrimitives
import SQLiteData
import SwiftUI

struct ChoreListView: View {

  // MARK: Internal

  @FetchAll(Chore.order(by: \.dueDate)) var chores: [Chore]

  @FetchAll var members: [HouseholdMember]

  @Dependency(\.defaultDatabase) var database

  var body: some View {
    NavigationStack {
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
      .navigationTitle("Chores")
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
      .sheet(item: $choreToEdit) { chore in
        AddChoreSheet(
          isPresented: Binding(
            get: { choreToEdit != nil },
            set: { if !$0 { choreToEdit = nil } },
          ),
          members: members,
          choreToEdit: chore,
        )
      }
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  @State private var showAddChore = false
  @State private var choreToEdit: Chore?

  private var pendingChores: [Chore] {
    chores.filter { !$0.isCompleted }
  }

  private var completedChores: [Chore] {
    chores.filter(\.isCompleted)
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
