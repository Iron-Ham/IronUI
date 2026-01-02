import IronComponents
import IronCore
import IronNavigation
import IronPrimitives
import SQLiteData
import SwiftUI

// MARK: - MembersView

struct MembersView: View {

  // MARK: Internal

  @FetchAll var members: [HouseholdMember]

  @FetchAll var chores: [Chore]

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: theme.spacing.md) {
          ForEach(members) { member in
            memberCard(member)
              .onTapGesture {
                selectedMember = member
                showMemberDetail = true
              }
          }
        }
        .padding(theme.spacing.md)
      }
      .navigationTitle("Household")
      .ironTray(isPresented: $showMemberDetail) {
        if let member = selectedMember {
          MemberDetailSheet(member: member, chores: chores)
        }
      }
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  @State private var selectedMember: HouseholdMember?
  @State private var showMemberDetail = false

  @ViewBuilder
  private func memberCard(_ member: HouseholdMember) -> some View {
    let memberChores = chores.filter { $0.assigneeId == member.id }
    let completedCount = memberChores.filter(\.isCompleted).count
    let pendingCount = memberChores.count(where: { !$0.isCompleted })
    let progress = memberChores.isEmpty ? 0.0 : Double(completedCount) / Double(memberChores.count)

    IronCard(style: .elevated) {
      HStack(spacing: theme.spacing.md) {
        ZStack {
          Circle()
            .fill(member.color.opacity(0.2))
            .frame(width: 64, height: 64)

          Text(member.avatarEmoji)
            .font(.system(size: 32))
        }

        VStack(alignment: .leading, spacing: theme.spacing.xs) {
          IronText(member.name, style: .headlineSmall)

          HStack(spacing: theme.spacing.md) {
            statLabel(value: pendingCount, label: "Pending", color: theme.colors.warning)
            statLabel(value: completedCount, label: "Done", color: theme.colors.success)
          }

          IronProgress(value: progress, color: progress == 1.0 ? .success : .primary)
        }

        Spacer()

        IronIcon(systemName: "chevron.right", size: .small)
          .foregroundStyle(theme.colors.textSecondary)
      }
      .padding(theme.spacing.md)
    }
    .ironRipple()
  }

  private func statLabel(value: Int, label: String, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      IronText("\(value)", style: .titleMedium)
        .foregroundStyle(color)

      IronText(label, style: .caption)
        .foregroundStyle(theme.colors.textSecondary)
    }
  }
}

// MARK: - MemberDetailSheet

struct MemberDetailSheet: View {

  // MARK: Internal

  let member: HouseholdMember
  let chores: [Chore]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: theme.spacing.lg) {
          // Avatar header
          VStack(spacing: theme.spacing.sm) {
            ZStack {
              Circle()
                .fill(member.color.opacity(0.2))
                .frame(width: 80, height: 80)

              Text(member.avatarEmoji)
                .font(.system(size: 48))
            }

            IronText(member.name, style: .headlineLarge)
          }
          .padding(.top, theme.spacing.md)

          // Stats
          HStack(spacing: theme.spacing.xl) {
            statCard(value: pendingChores.count, label: "Pending", color: theme.colors.warning)
            statCard(value: completedChores.count, label: "Completed", color: theme.colors.success)
            statCard(value: memberChores.count, label: "Total", color: theme.colors.primary)
          }
          .padding(.horizontal, theme.spacing.md)

          // Assigned chores
          if !pendingChores.isEmpty {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
              IronText("Pending Chores", style: .titleMedium)
                .padding(.horizontal, theme.spacing.md)

              ForEach(pendingChores) { chore in
                ChoreRow(
                  chore: chore,
                  showCheckbox: false,
                  showEditButton: false,
                )
                .padding(theme.spacing.md)
                .background(theme.colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: theme.radii.sm))
                .padding(.horizontal, theme.spacing.md)
              }
            }
          }
        }
        .padding(.bottom, theme.spacing.lg)
      }
      .navigationTitle("Member Details")
      #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private var memberChores: [Chore] {
    chores.filter { $0.assigneeId == member.id }
  }

  private var pendingChores: [Chore] {
    memberChores.filter { !$0.isCompleted }
  }

  private var completedChores: [Chore] {
    memberChores.filter(\.isCompleted)
  }

  private func statCard(value: Int, label: String, color: Color) -> some View {
    VStack(spacing: theme.spacing.xs) {
      IronText("\(value)", style: .displaySmall)
        .foregroundStyle(color)

      IronText(label, style: .bodySmall)
        .foregroundStyle(theme.colors.textSecondary)
    }
    .frame(maxWidth: .infinity)
    .padding(theme.spacing.md)
    .background(theme.colors.surfaceElevated)
    .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
  }
}

#Preview {
  MembersView()
    .ironTheme(IronDefaultTheme())
}
