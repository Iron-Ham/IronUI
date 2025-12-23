import SnapshotTesting
import SwiftUI
import Testing
@testable import IronUI

// MARK: - IronText Snapshot Tests

@Suite("IronText Snapshots")
struct IronTextSnapshotTests {

  @Test("Text - Display Styles")
  @MainActor
  func textDisplayStyles() {
    let view = VStack(alignment: .leading, spacing: 12) {
      IronText("Display Large", style: .displayLarge, color: .primary)
      IronText("Display Medium", style: .displayMedium, color: .primary)
      IronText("Display Small", style: .displaySmall, color: .primary)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Text - Headline Styles")
  @MainActor
  func textHeadlineStyles() {
    let view = VStack(alignment: .leading, spacing: 12) {
      IronText("Headline Large", style: .headlineLarge, color: .primary)
      IronText("Headline Medium", style: .headlineMedium, color: .primary)
      IronText("Headline Small", style: .headlineSmall, color: .primary)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Text - Title Styles")
  @MainActor
  func textTitleStyles() {
    let view = VStack(alignment: .leading, spacing: 10) {
      IronText("Title Large", style: .titleLarge, color: .primary)
      IronText("Title Medium", style: .titleMedium, color: .primary)
      IronText("Title Small", style: .titleSmall, color: .primary)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Text - Body Styles")
  @MainActor
  func textBodyStyles() {
    let view = VStack(alignment: .leading, spacing: 8) {
      IronText("Body Large - Lorem ipsum", style: .bodyLarge, color: .primary)
      IronText("Body Medium - Lorem ipsum", style: .bodyMedium, color: .primary)
      IronText("Body Small - Lorem ipsum", style: .bodySmall, color: .primary)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Text - Label Styles")
  @MainActor
  func textLabelStyles() {
    let view = VStack(alignment: .leading, spacing: 8) {
      IronText("Label Large", style: .labelLarge, color: .primary)
      IronText("Label Medium", style: .labelMedium, color: .primary)
      IronText("Label Small", style: .labelSmall, color: .primary)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Text - Color Variations")
  @MainActor
  func textColors() {
    let view = VStack(alignment: .leading, spacing: 8) {
      IronText("Primary Color", style: .bodyMedium, color: .primary)
      IronText("Secondary Color", style: .bodyMedium, color: .secondary)
      IronText("Disabled Color", style: .bodyMedium, color: .disabled)
      IronText("Success Color", style: .bodyMedium, color: .success)
      IronText("Warning Color", style: .bodyMedium, color: .warning)
      IronText("Error Color", style: .bodyMedium, color: .error)
      IronText("Info Color", style: .bodyMedium, color: .info)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Text - Dynamic Type Scaling")
  @MainActor
  func textDynamicType() {
    let view = VStack(alignment: .leading, spacing: 8) {
      IronText("Headline", style: .headlineMedium, color: .primary)
      IronText("Body text content", style: .bodyMedium, color: .secondary)
      IronText("Caption", style: .labelSmall, color: .disabled)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.forDevice(.iPhone17Pro))
  }
}
