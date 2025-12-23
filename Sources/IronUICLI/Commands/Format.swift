import ArgumentParser
import Foundation
import Noora

extension IronUICLI {
  struct Format: AsyncParsableCommand, IronUICommand {

    static let configuration = CommandConfiguration(
      abstract: "Formats Swift sources using the Airbnb Swift Style Guide."
    )

    func run() async throws {
      try await runner.runScript("Scripts/format.sh")
      noora.success("Formatting complete")
    }
  }
}
