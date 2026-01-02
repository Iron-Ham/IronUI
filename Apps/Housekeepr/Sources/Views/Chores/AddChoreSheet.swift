import IronComponents
import IronCore
import IronForms
import IronLayouts
import IronPrimitives
import SQLiteData
import SwiftUI

struct AddChoreSheet: View {

  // MARK: Lifecycle

  init(isPresented: Binding<Bool>, members: [HouseholdMember], choreToEdit: Chore? = nil) {
    _isPresented = isPresented
    self.members = members
    self.choreToEdit = choreToEdit

    if let chore = choreToEdit {
      _title = State(initialValue: chore.title)
      _notes = State(initialValue: chore.notes)
      _selectedCategory = State(initialValue: chore.category)
      _selectedFrequency = State(initialValue: chore.frequency)
      _dueDate = State(initialValue: chore.dueDate ?? Date())
      _hasDueDate = State(initialValue: chore.dueDate != nil)
      _selectedMemberId = State(initialValue: chore.assigneeId)
    }
  }

  // MARK: Internal

  @Binding var isPresented: Bool

  @Dependency(\.defaultDatabase) var database
  let members: [HouseholdMember]
  var choreToEdit: Chore?

  var body: some View {
    NavigationStack {
      IronForm {
        IronFormField("Chore Name") {
          IronTextField("What needs to be done?", text: $title, style: .outlined)
            .ironShake(isActive: $shakeTitle)
        }

        IronFormField("Notes (optional)") {
          IronTextField("Any additional details...", text: $notes, style: .outlined)
        }

        IronFormField("Category") {
          IronFlow(horizontalSpacing: theme.spacing.xs, verticalSpacing: theme.spacing.xs) {
            ForEach(ChoreCategory.allCases, id: \.self) { category in
              IronChip(
                LocalizedStringKey(category.displayName),
                icon: category.icon,
                isSelected: Binding(
                  get: { selectedCategory == category },
                  set: { if $0 { selectedCategory = category } },
                ),
                size: .medium,
              )
            }
          }
        }

        IronFormField("Frequency") {
          IronRadioGroup(selection: $selectedFrequency) {
            ForEach(ChoreFrequency.allCases, id: \.self) { frequency in
              IronRadio(frequency.displayName, value: frequency, selection: $selectedFrequency)
            }
          }
        }

        IronFormField("Due Date") {
          VStack(alignment: .leading, spacing: theme.spacing.sm) {
            IronToggle("Set due date", isOn: $hasDueDate)

            if hasDueDate {
              IronDatePicker(selection: $dueDate, displayedComponents: .date)
            }
          }
        }

        IronFormField("Assign To") {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.sm) {
              ForEach(members) { member in
                memberButton(member)
              }

              // Unassigned option
              Button {
                selectedMemberId = nil
              } label: {
                VStack(spacing: theme.spacing.xxs) {
                  ZStack {
                    Circle()
                      .fill(selectedMemberId == nil ? theme.colors.primary.opacity(0.2) : theme.colors.surface)
                      .frame(width: 48, height: 48)
                      .overlay(
                        Circle()
                          .strokeBorder(
                            selectedMemberId == nil ? theme.colors.primary : theme.colors.border,
                            lineWidth: 2,
                          )
                      )

                    IronIcon(systemName: "person.slash", size: .medium)
                      .foregroundStyle(theme.colors.textSecondary)
                  }

                  IronText("Anyone", style: .caption)
                    .foregroundStyle(theme.colors.textSecondary)
                }
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
      .navigationTitle(isEditing ? "Edit Chore" : "New Chore")
      #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
              isPresented = false
            }
          }

          ToolbarItem(placement: .confirmationAction) {
            Button(isEditing ? "Save" : "Add") {
              saveChore()
            }
            .disabled(title.isEmpty)
          }
        }
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  @State private var title = ""
  @State private var notes = ""
  @State private var selectedCategory = ChoreCategory.general
  @State private var selectedFrequency = ChoreFrequency.once
  @State private var dueDate = Date()
  @State private var hasDueDate = true
  @State private var selectedMemberId: UUID?
  @State private var showValidationError = false
  @State private var shakeTitle = false

  private var isEditing: Bool {
    choreToEdit != nil
  }

  @ViewBuilder
  private func memberButton(_ member: HouseholdMember) -> some View {
    let isSelected = selectedMemberId == member.id

    Button {
      selectedMemberId = member.id
    } label: {
      VStack(spacing: theme.spacing.xxs) {
        ZStack {
          Circle()
            .fill(isSelected ? member.color.opacity(0.2) : theme.colors.surface)
            .frame(width: 48, height: 48)
            .overlay(
              Circle()
                .strokeBorder(isSelected ? member.color : theme.colors.border, lineWidth: 2)
            )

          Text(member.avatarEmoji)
            .font(.system(size: 24))
        }

        IronText(member.name, style: .caption)
          .foregroundStyle(isSelected ? member.color : theme.colors.textSecondary)
      }
    }
    .buttonStyle(.plain)
  }

  private func saveChore() {
    guard !title.isEmpty else {
      shakeTitle = true
      return
    }

    let chore = Chore(
      id: choreToEdit?.id ?? UUID(),
      title: title,
      notes: notes,
      category: selectedCategory,
      frequency: selectedFrequency,
      dueDate: hasDueDate ? dueDate : nil,
      isCompleted: choreToEdit?.isCompleted ?? false,
      completedAt: choreToEdit?.completedAt,
      assigneeId: selectedMemberId,
    )

    do {
      try database.write { db in
        try Chore.upsert { chore }.execute(db)
      }
      isPresented = false
    } catch {
      shakeTitle = true
    }
  }
}

#Preview {
  AddChoreSheet(
    isPresented: .constant(true),
    members: SampleData.members,
  )
  .ironTheme(IronDefaultTheme())
}
