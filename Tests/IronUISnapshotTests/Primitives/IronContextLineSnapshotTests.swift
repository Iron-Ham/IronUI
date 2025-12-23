import SnapshotTesting
import SwiftUI
import Testing
@testable import IronPrimitives

// MARK: - IronContextLine Snapshot Tests

@Suite("IronContextLine Snapshots")
struct IronContextLineSnapshotTests {

  @Test("ContextLine - Single")
  @MainActor
  func contextLineSingle() {
    let view = VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 8) {
        Image(systemName: "terminal")
        Text("Command")
          .fontWeight(.medium)
      }
      .padding(.bottom, 4)

      IronContextLine {
        Text("Result output")
          .foregroundStyle(.secondary)
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("ContextLine - Positions")
  @MainActor
  func contextLinePositions() {
    let view = VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 8) {
        Image(systemName: "list.bullet")
        Text("Results")
          .fontWeight(.medium)
      }
      .padding(.bottom, 4)

      IronContextLine(position: .first) {
        Text("First item")
      }
      IronContextLine(position: .middle) {
        Text("Middle item")
      }
      IronContextLine(position: .last) {
        Text("Last item")
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("ContextLine - Styles")
  @MainActor
  func contextLineStyles() {
    let view = VStack(alignment: .leading, spacing: 12) {
      IronContextLine(style: .subtle) {
        Text("Subtle")
      }
      IronContextLine(style: .standard) {
        Text("Standard")
      }
      IronContextLine(style: .prominent) {
        Text("Prominent")
      }
      IronContextLine(style: .accent) {
        Text("Accent")
      }
      IronContextLine(style: .success) {
        Text("Success")
      }
      IronContextLine(style: .error) {
        Text("Error")
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("ContextLine - Group")
  @MainActor
  func contextLineGroup() {
    let view = VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Image(systemName: "folder")
        Text("Build Output")
          .fontWeight(.medium)
      }

      IronContextGroup {
        Text("Compiling Module A...")
        Text("Compiling Module B...")
        Text("Linking...")
        Text("Build succeeded")
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("ContextLine - Nested")
  @MainActor
  func contextLineNested() {
    let view = VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 8) {
        Image(systemName: "network")
        Text("API Request")
          .fontWeight(.medium)
      }
      .padding(.bottom, 4)

      IronContextLine(position: .first) {
        HStack(spacing: 4) {
          Image(systemName: "arrow.up.circle")
          Text("Request sent")
        }
        .foregroundStyle(.secondary)
      }
      IronContextLine(position: .middle) {
        HStack(spacing: 4) {
          Image(systemName: "clock")
          Text("Processing...")
        }
        .foregroundStyle(.secondary)
      }
      IronContextLine(position: .last, style: .success) {
        HStack(spacing: 4) {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(.green)
          Text("200 OK")
        }
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

}
