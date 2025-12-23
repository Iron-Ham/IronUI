import Foundation
import SwiftUI

// MARK: - IronValidator

/// A validator that checks a value and returns an optional error message.
///
/// Validators can be composed and chained together for complex validation logic.
///
/// ## Built-in Validators
///
/// ```swift
/// IronValidator.required("This field is required")
/// IronValidator.email("Please enter a valid email")
/// IronValidator.minLength(8, "Must be at least 8 characters")
/// ```
///
/// ## Custom Validators
///
/// ```swift
/// let usernameValidator = IronValidator<String> { value in
///   if value.contains(" ") {
///     return "Username cannot contain spaces"
///   }
///   return nil
/// }
/// ```
public struct IronValidator<Value: Sendable>: Sendable {

  // MARK: Lifecycle

  /// Creates a validator with the given validation function.
  ///
  /// - Parameter validate: A function that returns an error message if validation fails.
  public init(_ validate: @escaping @Sendable (Value) -> String?) {
    self.validate = validate
  }

  // MARK: Public

  /// The validation function.
  public let validate: @Sendable (Value) -> String?

  /// Combines this validator with another, running both.
  ///
  /// - Parameter other: Another validator to run.
  /// - Returns: A new validator that runs both validations.
  public func and(_ other: IronValidator<Value>) -> IronValidator<Value> {
    IronValidator { value in
      if let error = validate(value) {
        return error
      }
      return other.validate(value)
    }
  }
}

// MARK: - String Validators

extension IronValidator where Value == String {

  /// Validates that a string is not empty.
  ///
  /// - Parameter message: The error message if validation fails.
  /// - Returns: A required string validator.
  public static func required(_ message: String = "This field is required") -> IronValidator<String> {
    IronValidator { value in
      value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? message : nil
    }
  }

  /// Validates that a string is a valid email address.
  ///
  /// - Parameter message: The error message if validation fails.
  /// - Returns: An email validator.
  public static func email(_ message: String = "Please enter a valid email address") -> IronValidator<String> {
    IronValidator { value in
      let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.isEmpty { return nil } // Don't validate empty (use .required for that)

      let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
      let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
      return predicate.evaluate(with: trimmed) ? nil : message
    }
  }

  /// Validates that a string has a minimum length.
  ///
  /// - Parameters:
  ///   - length: The minimum required length.
  ///   - message: The error message if validation fails.
  /// - Returns: A minimum length validator.
  public static func minLength(_ length: Int, _ message: String? = nil) -> IronValidator<String> {
    IronValidator { value in
      let effectiveMessage = message ?? "Must be at least \(length) characters"
      return value.count >= length ? nil : effectiveMessage
    }
  }

  /// Validates that a string has a maximum length.
  ///
  /// - Parameters:
  ///   - length: The maximum allowed length.
  ///   - message: The error message if validation fails.
  /// - Returns: A maximum length validator.
  public static func maxLength(_ length: Int, _ message: String? = nil) -> IronValidator<String> {
    IronValidator { value in
      let effectiveMessage = message ?? "Must be at most \(length) characters"
      return value.count <= length ? nil : effectiveMessage
    }
  }

  /// Validates that a string matches a regular expression pattern.
  ///
  /// - Parameters:
  ///   - pattern: The regex pattern to match.
  ///   - message: The error message if validation fails.
  /// - Returns: A pattern validator.
  public static func pattern(_ pattern: String, _ message: String = "Invalid format") -> IronValidator<String> {
    IronValidator { value in
      if value.isEmpty { return nil }
      let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
      return predicate.evaluate(with: value) ? nil : message
    }
  }

  /// Validates that a string contains only alphanumeric characters.
  ///
  /// - Parameter message: The error message if validation fails.
  /// - Returns: An alphanumeric validator.
  public static func alphanumeric(_ message: String = "Only letters and numbers allowed") -> IronValidator<String> {
    pattern(#"^[a-zA-Z0-9]*$"#, message)
  }

  /// Validates that a string is a valid URL.
  ///
  /// - Parameter message: The error message if validation fails.
  /// - Returns: A URL validator.
  public static func url(_ message: String = "Please enter a valid URL") -> IronValidator<String> {
    IronValidator { value in
      if value.isEmpty { return nil }
      guard URL(string: value) != nil else { return message }
      return nil
    }
  }
}

// MARK: - Optional String Validators

extension IronValidator where Value == String? {

  /// Validates that an optional string has a value.
  ///
  /// - Parameter message: The error message if validation fails.
  /// - Returns: A required validator for optional strings.
  public static func required(_ message: String = "This field is required") -> IronValidator<String?> {
    IronValidator { value in
      guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        return message
      }
      return nil
    }
  }
}

// MARK: - Numeric Validators

extension IronValidator where Value: Comparable & Sendable {

  /// Validates that a value is within a range.
  ///
  /// - Parameters:
  ///   - range: The allowed range.
  ///   - message: The error message if validation fails.
  /// - Returns: A range validator.
  public static func range(_ range: ClosedRange<Value>, _ message: String = "Value out of range") -> IronValidator<Value> {
    IronValidator { value in
      range.contains(value) ? nil : message
    }
  }

  /// Validates that a value is at least a minimum.
  ///
  /// - Parameters:
  ///   - minimum: The minimum allowed value.
  ///   - message: The error message if validation fails.
  /// - Returns: A minimum value validator.
  public static func min(_ minimum: Value, _ message: String = "Value too low") -> IronValidator<Value> {
    IronValidator { value in
      value >= minimum ? nil : message
    }
  }

  /// Validates that a value is at most a maximum.
  ///
  /// - Parameters:
  ///   - maximum: The maximum allowed value.
  ///   - message: The error message if validation fails.
  /// - Returns: A maximum value validator.
  public static func max(_ maximum: Value, _ message: String = "Value too high") -> IronValidator<Value> {
    IronValidator { value in
      value <= maximum ? nil : message
    }
  }
}

// MARK: - IronValidatedField

/// A property wrapper that validates a value and tracks its error state.
///
/// ```swift
/// @IronValidatedField(
///   validators: [.required(), .email()]
/// )
/// var email = ""
///
/// // Check validation
/// if $email.isValid {
///   // Submit form
/// }
/// ```
@propertyWrapper
public struct IronValidatedField<Value: Sendable>: DynamicProperty {

  // MARK: Lifecycle

  /// Creates a validated field with initial value and validators.
  ///
  /// - Parameters:
  ///   - wrappedValue: The initial value.
  ///   - validators: The validators to apply.
  public init(
    wrappedValue: Value,
    validators: [IronValidator<Value>] = [],
  ) {
    _value = State(initialValue: wrappedValue)
    _error = State(initialValue: nil)
    _hasBeenEdited = State(initialValue: false)
    self.validators = validators
  }

  // MARK: Public

  public var wrappedValue: Value {
    get { value }
    nonmutating set {
      value = newValue
      hasBeenEdited = true
      validate()
    }
  }

  public var projectedValue: Projection {
    Projection(field: self)
  }

  // MARK: Private

  @State private var value: Value
  @State private var error: String?
  @State private var hasBeenEdited: Bool

  private let validators: [IronValidator<Value>]

  private func validate() {
    for validator in validators {
      if let errorMessage = validator.validate(value) {
        error = errorMessage
        return
      }
    }
    error = nil
  }
}

// MARK: IronValidatedField.Projection

extension IronValidatedField {
  /// Projection for accessing validation state.
  ///
  /// This type is `@MainActor` because it interacts with SwiftUI state
  /// which must be accessed from the main thread.
  @MainActor
  public struct Projection {

    // MARK: Lifecycle

    fileprivate nonisolated init(field: IronValidatedField) {
      self.field = field
    }

    // MARK: Public

    /// Binding to the wrapped value.
    public var binding: Binding<Value> {
      Binding(
        get: { field.value },
        set: { newValue in
          field.value = newValue
          field.hasBeenEdited = true
          field.validate()
        },
      )
    }

    /// The current error message, if any.
    public var error: String? {
      field.hasBeenEdited ? field.error : nil
    }

    /// Whether the field is currently valid.
    public var isValid: Bool {
      field.error == nil
    }

    /// Whether the field has been edited.
    public var hasBeenEdited: Bool {
      field.hasBeenEdited
    }

    /// Manually triggers validation.
    public func validate() {
      field.hasBeenEdited = true
      field.validate()
    }

    // MARK: Private

    private nonisolated(unsafe) let field: IronValidatedField
  }
}

// MARK: - Previews

#Preview("IronValidation - Email") {
  struct Demo: View {
    @IronValidatedField(validators: [.required(), .email()])
    var email = ""

    var body: some View {
      IronForm {
        IronFormSection("Contact") {
          IronFormField("Email", error: $email.error) {
            IronTextField("Enter email", text: $email.binding)
          }
        }
      }
    }
  }

  return Demo()
}

#Preview("IronValidation - Password") {
  struct Demo: View {
    @IronValidatedField(validators: [
      .required("Password is required"),
      .minLength(8, "Password must be at least 8 characters"),
    ])
    var password = ""

    var body: some View {
      IronForm {
        IronFormSection("Security") {
          IronFormField("Password", error: $password.error, isRequired: true) {
            IronSecureField("Enter password", text: $password.binding)
          }
        }
      }
    }
  }

  return Demo()
}
