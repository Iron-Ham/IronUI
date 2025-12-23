import ArgumentParser
import Foundation

extension IronUICLI {
  struct Format: ParsableCommand, IronUICommand {

    static let configuration = CommandConfiguration(
      abstract: "Formats Swift sources using the Airbnb Swift Style Guide."
    )

    func run() throws {
      try runner.runScript("Scripts/format.sh")
    }
  }
}
