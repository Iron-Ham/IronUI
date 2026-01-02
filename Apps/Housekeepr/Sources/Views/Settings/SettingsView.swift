import IronCore
import IronForms
import IronPrimitives
import SwiftUI

struct SettingsView: View {

  // MARK: Internal

  var body: some View {
    NavigationStack {
      IronForm {
        Section {
          IronFormField("Notifications") {
            IronToggle("Enable notifications", isOn: $notificationsEnabled)
          }

          IronFormField("Sounds") {
            IronToggle("Enable sounds", isOn: $soundsEnabled)
          }

          IronFormField("Haptic Feedback") {
            IronToggle("Enable haptics", isOn: $hapticFeedbackEnabled)
          }
        } header: {
          IronText("Preferences", style: .titleSmall)
            .foregroundStyle(theme.colors.textSecondary)
        }

        IronDivider()
          .padding(.vertical, theme.spacing.sm)

        Section {
          IronFormField("Show Completed") {
            IronToggle("Show completed chores in list", isOn: $showCompletedChores)
          }
        } header: {
          IronText("Display", style: .titleSmall)
            .foregroundStyle(theme.colors.textSecondary)
        }

        IronDivider()
          .padding(.vertical, theme.spacing.sm)

        Section {
          IronAlert(
            "Data is stored locally on this device. Sync features coming soon!",
            variant: .info,
          )
        } header: {
          IronText("About", style: .titleSmall)
            .foregroundStyle(theme.colors.textSecondary)
        }

        VStack(spacing: theme.spacing.sm) {
          IronText("Housekeepr", style: .headlineSmall)

          IronText("A sample app showcasing IronUI components", style: .bodySmall)
            .foregroundStyle(theme.colors.textSecondary)
            .multilineTextAlignment(.center)

          IronText("Version 1.0.0", style: .caption)
            .foregroundStyle(theme.colors.textDisabled)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, theme.spacing.xl)
      }
      .navigationTitle("Settings")
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  @AppStorage("notificationsEnabled") private var notificationsEnabled = true
  @AppStorage("soundsEnabled") private var soundsEnabled = true
  @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
  @AppStorage("showCompletedChores") private var showCompletedChores = true

}

#Preview {
  SettingsView()
    .ironTheme(IronDefaultTheme())
}
