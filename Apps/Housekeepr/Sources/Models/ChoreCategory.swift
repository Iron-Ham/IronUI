import GRDB
import IronCore
import SQLiteData
import SwiftUI

// MARK: - ChoreCategory

/// Categories for organizing household chores
enum ChoreCategory: String, CaseIterable, Codable, Sendable, DatabaseValueConvertible, QueryRepresentable, QueryBindable {
  case kitchen
  case bathroom
  case bedroom
  case laundry
  case outdoor
  case general

  // MARK: Internal

  static var _columnWidth: Int? {
    nil
  }

  var displayName: String {
    switch self {
    case .kitchen: "Kitchen"
    case .bathroom: "Bathroom"
    case .bedroom: "Bedroom"
    case .laundry: "Laundry"
    case .outdoor: "Outdoor"
    case .general: "General"
    }
  }

  var icon: String {
    switch self {
    case .kitchen: "fork.knife"
    case .bathroom: "shower.fill"
    case .bedroom: "bed.double.fill"
    case .laundry: "washer.fill"
    case .outdoor: "leaf.fill"
    case .general: "house.fill"
    }
  }

  var color: Color {
    switch self {
    case .kitchen: .orange
    case .bathroom: .cyan
    case .bedroom: .purple
    case .laundry: .blue
    case .outdoor: .green
    case .general: .gray
    }
  }
}

// MARK: - ChoreFrequency

/// Frequency options for recurring chores
enum ChoreFrequency: String, CaseIterable, Codable, Sendable, DatabaseValueConvertible, QueryRepresentable, QueryBindable {
  case once
  case daily
  case weekly
  case monthly

  static var _columnWidth: Int? {
    nil
  }

  var displayName: String {
    switch self {
    case .once: "One-time"
    case .daily: "Daily"
    case .weekly: "Weekly"
    case .monthly: "Monthly"
    }
  }
}
