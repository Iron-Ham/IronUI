import Foundation
import Testing
@testable import IronForms

// MARK: - IronValidatorTests

@Suite("IronValidator")
struct IronValidatorTests {

  @Test("custom validator returns nil for valid input")
  func customValidatorReturnsNilForValid() {
    let validator = IronValidator<String> { value in
      value.count > 3 ? nil : "Too short"
    }

    let result = validator.validate("Hello")

    #expect(result == nil)
  }

  @Test("custom validator returns error for invalid input")
  func customValidatorReturnsErrorForInvalid() {
    let validator = IronValidator<String> { value in
      value.count > 3 ? nil : "Too short"
    }

    let result = validator.validate("Hi")

    #expect(result == "Too short")
  }

  @Test("and() runs second validator when first passes")
  func andRunsSecondWhenFirstPasses() {
    let first = IronValidator<String> { _ in nil }
    let second = IronValidator<String> { _ in "Second failed" }

    let combined = first.and(second)
    let result = combined.validate("test")

    #expect(result == "Second failed")
  }

  @Test("and() stops at first failure")
  func andStopsAtFirstFailure() {
    let first = IronValidator<String> { _ in "First failed" }
    let second = IronValidator<String> { _ in "Second failed" }

    let combined = first.and(second)
    let result = combined.validate("test")

    #expect(result == "First failed")
  }

  @Test("and() returns nil when both pass")
  func andReturnsNilWhenBothPass() {
    let first = IronValidator<String> { _ in nil }
    let second = IronValidator<String> { _ in nil }

    let combined = first.and(second)
    let result = combined.validate("test")

    #expect(result == nil)
  }

  @Test("chaining multiple validators works")
  func chainingMultipleValidatorsWorks() {
    let validator = IronValidator<String>.required()
      .and(.minLength(3))
      .and(.maxLength(10))

    #expect(validator.validate("") == "This field is required")
    #expect(validator.validate("ab") == "Must be at least 3 characters")
    #expect(validator.validate("12345678901") == "Must be at most 10 characters")
    #expect(validator.validate("valid") == nil)
  }
}

// MARK: - IronValidatorStringTests

@Suite("IronValidator - String")
struct IronValidatorStringTests {

  @Test("required fails for empty string")
  func requiredFailsForEmpty() {
    let validator = IronValidator<String>.required()

    #expect(validator.validate("") != nil)
  }

  @Test("required fails for whitespace-only string")
  func requiredFailsForWhitespace() {
    let validator = IronValidator<String>.required()

    #expect(validator.validate("   ") != nil)
    #expect(validator.validate("\n\t") != nil)
  }

  @Test("required passes for non-empty string")
  func requiredPassesForNonEmpty() {
    let validator = IronValidator<String>.required()

    #expect(validator.validate("Hello") == nil)
    #expect(validator.validate("  Hello  ") == nil)
  }

  @Test("required uses custom message")
  func requiredUsesCustomMessage() {
    let validator = IronValidator<String>.required("Custom required message")

    #expect(validator.validate("") == "Custom required message")
  }

  @Test("email passes for valid emails")
  func emailPassesForValid() {
    let validator = IronValidator<String>.email()

    #expect(validator.validate("test@example.com") == nil)
    #expect(validator.validate("user.name@domain.co.uk") == nil)
    #expect(validator.validate("user+tag@example.org") == nil)
  }

  @Test("email fails for invalid emails")
  func emailFailsForInvalid() {
    let validator = IronValidator<String>.email()

    #expect(validator.validate("not-an-email") != nil)
    #expect(validator.validate("missing@domain") != nil)
    #expect(validator.validate("@no-local-part.com") != nil)
    #expect(validator.validate("spaces in@email.com") != nil)
  }

  @Test("email skips validation for empty string")
  func emailSkipsEmpty() {
    let validator = IronValidator<String>.email()

    // Empty strings should not trigger email validation
    // (use .required() for that)
    #expect(validator.validate("") == nil)
  }

  @Test("email uses custom message")
  func emailUsesCustomMessage() {
    let validator = IronValidator<String>.email("Please provide email")

    #expect(validator.validate("invalid") == "Please provide email")
  }

  @Test("minLength passes when at or above minimum")
  func minLengthPassesAtOrAboveMinimum() {
    let validator = IronValidator<String>.minLength(5)

    #expect(validator.validate("12345") == nil)
    #expect(validator.validate("123456") == nil)
  }

  @Test("minLength fails below minimum")
  func minLengthFailsBelowMinimum() {
    let validator = IronValidator<String>.minLength(5)

    #expect(validator.validate("1234") != nil)
    #expect(validator.validate("") != nil)
  }

  @Test("minLength uses custom message")
  func minLengthUsesCustomMessage() {
    let validator = IronValidator<String>.minLength(8, "Need 8+ chars")

    #expect(validator.validate("short") == "Need 8+ chars")
  }

  @Test("minLength generates default message with length")
  func minLengthGeneratesDefaultMessage() {
    let validator = IronValidator<String>.minLength(10)
    let result = validator.validate("short")

    #expect(result?.contains("10") == true)
  }

  @Test("maxLength passes when at or below maximum")
  func maxLengthPassesAtOrBelowMaximum() {
    let validator = IronValidator<String>.maxLength(5)

    #expect(validator.validate("12345") == nil)
    #expect(validator.validate("1234") == nil)
    #expect(validator.validate("") == nil)
  }

  @Test("maxLength fails above maximum")
  func maxLengthFailsAboveMaximum() {
    let validator = IronValidator<String>.maxLength(5)

    #expect(validator.validate("123456") != nil)
  }

  @Test("maxLength uses custom message")
  func maxLengthUsesCustomMessage() {
    let validator = IronValidator<String>.maxLength(3, "Too long!")

    #expect(validator.validate("1234") == "Too long!")
  }

  @Test("pattern passes for matching strings")
  func patternPassesForMatching() {
    let validator = IronValidator<String>.pattern(#"^\d{3}-\d{4}$"#)

    #expect(validator.validate("123-4567") == nil)
  }

  @Test("pattern fails for non-matching strings")
  func patternFailsForNonMatching() {
    let validator = IronValidator<String>.pattern(#"^\d{3}-\d{4}$"#)

    #expect(validator.validate("123-456") != nil)
    #expect(validator.validate("abc-defg") != nil)
  }

  @Test("pattern skips validation for empty string")
  func patternSkipsEmpty() {
    let validator = IronValidator<String>.pattern(#"^\d+$"#)

    #expect(validator.validate("") == nil)
  }

  @Test("pattern uses custom message")
  func patternUsesCustomMessage() {
    let validator = IronValidator<String>.pattern(#"^\d+$"#, "Numbers only")

    #expect(validator.validate("abc") == "Numbers only")
  }

  @Test("alphanumeric passes for letters and numbers")
  func alphanumericPassesForLettersAndNumbers() {
    let validator = IronValidator<String>.alphanumeric()

    #expect(validator.validate("abc123") == nil)
    #expect(validator.validate("ABC") == nil)
    #expect(validator.validate("123") == nil)
  }

  @Test("alphanumeric fails for special characters")
  func alphanumericFailsForSpecialChars() {
    let validator = IronValidator<String>.alphanumeric()

    #expect(validator.validate("hello world") != nil) // space
    #expect(validator.validate("hello!") != nil)
    #expect(validator.validate("user@name") != nil)
  }

  @Test("alphanumeric passes for empty string")
  func alphanumericPassesForEmpty() {
    let validator = IronValidator<String>.alphanumeric()

    #expect(validator.validate("") == nil)
  }

  @Test("url passes for valid URLs")
  func urlPassesForValid() {
    let validator = IronValidator<String>.url()

    #expect(validator.validate("https://example.com") == nil)
    #expect(validator.validate("http://localhost:8080") == nil)
    #expect(validator.validate("ftp://files.example.com") == nil)
  }

  @Test("url skips validation for empty string")
  func urlSkipsEmpty() {
    let validator = IronValidator<String>.url()

    #expect(validator.validate("") == nil)
  }
}

// MARK: - IronValidatorOptionalStringTests

@Suite("IronValidator - Optional String")
struct IronValidatorOptionalStringTests {

  @Test("required fails for nil")
  func requiredFailsForNil() {
    let validator = IronValidator<String?>.required()

    #expect(validator.validate(nil) != nil)
  }

  @Test("required fails for empty string")
  func requiredFailsForEmpty() {
    let validator = IronValidator<String?>.required()

    #expect(validator.validate("") != nil)
  }

  @Test("required fails for whitespace-only")
  func requiredFailsForWhitespace() {
    let validator = IronValidator<String?>.required()

    #expect(validator.validate("   ") != nil)
  }

  @Test("required passes for non-empty string")
  func requiredPassesForNonEmpty() {
    let validator = IronValidator<String?>.required()

    #expect(validator.validate("Hello") == nil)
  }

  @Test("required uses custom message")
  func requiredUsesCustomMessage() {
    let validator = IronValidator<String?>.required("Field needed")

    #expect(validator.validate(nil) == "Field needed")
  }
}

// MARK: - IronValidatorComparableTests

@Suite("IronValidator - Comparable")
struct IronValidatorComparableTests {

  @Test("range passes for values within range")
  func rangePassesWithinRange() {
    let validator = IronValidator<Int>.range(1...10)

    #expect(validator.validate(1) == nil)
    #expect(validator.validate(5) == nil)
    #expect(validator.validate(10) == nil)
  }

  @Test("range fails for values outside range")
  func rangeFailsOutsideRange() {
    let validator = IronValidator<Int>.range(1...10)

    #expect(validator.validate(0) != nil)
    #expect(validator.validate(11) != nil)
    #expect(validator.validate(-5) != nil)
  }

  @Test("range uses custom message")
  func rangeUsesCustomMessage() {
    let validator = IronValidator<Int>.range(1...100, "Out of bounds")

    #expect(validator.validate(0) == "Out of bounds")
  }

  @Test("min passes for values at or above minimum")
  func minPassesAtOrAboveMinimum() {
    let validator = IronValidator<Double>.min(5.0)

    #expect(validator.validate(5.0) == nil)
    #expect(validator.validate(10.0) == nil)
  }

  @Test("min fails for values below minimum")
  func minFailsBelowMinimum() {
    let validator = IronValidator<Double>.min(5.0)

    #expect(validator.validate(4.9) != nil)
    #expect(validator.validate(0) != nil)
  }

  @Test("min uses custom message")
  func minUsesCustomMessage() {
    let validator = IronValidator<Int>.min(18, "Must be 18+")

    #expect(validator.validate(17) == "Must be 18+")
  }

  @Test("max passes for values at or below maximum")
  func maxPassesAtOrBelowMaximum() {
    let validator = IronValidator<Int>.max(100)

    #expect(validator.validate(100) == nil)
    #expect(validator.validate(50) == nil)
    #expect(validator.validate(0) == nil)
  }

  @Test("max fails for values above maximum")
  func maxFailsAboveMaximum() {
    let validator = IronValidator<Int>.max(100)

    #expect(validator.validate(101) != nil)
  }

  @Test("max uses custom message")
  func maxUsesCustomMessage() {
    let validator = IronValidator<Int>.max(10, "Maximum is 10")

    #expect(validator.validate(11) == "Maximum is 10")
  }

  @Test("validators work with Int")
  func validatorsWorkWithInt() {
    let rangeValidator = IronValidator<Int>.range(0...100)
    let minValidator = IronValidator<Int>.min(0)
    let maxValidator = IronValidator<Int>.max(100)

    #expect(rangeValidator.validate(50) == nil)
    #expect(minValidator.validate(0) == nil)
    #expect(maxValidator.validate(100) == nil)
  }

  @Test("validators work with Double")
  func validatorsWorkWithDouble() {
    let rangeValidator = IronValidator<Double>.range(0.0...1.0)

    #expect(rangeValidator.validate(0.5) == nil)
    #expect(rangeValidator.validate(1.5) != nil)
  }

  @Test("validators work with Date")
  func validatorsWorkWithDate() {
    let now = Date()
    let yesterday = now.addingTimeInterval(-86400)
    let tomorrow = now.addingTimeInterval(86400)

    let futureValidator = IronValidator<Date>.min(now, "Must be in the future")

    #expect(futureValidator.validate(tomorrow) == nil)
    #expect(futureValidator.validate(yesterday) == "Must be in the future")
  }
}

// MARK: - IronValidatorScenariosTests

@Suite("IronValidator - Real-World Scenarios")
struct IronValidatorScenariosTests {

  @Test("password validation with multiple rules")
  func passwordValidation() {
    let passwordValidator = IronValidator<String>.required("Password is required")
      .and(.minLength(8, "Password must be at least 8 characters"))
      .and(.maxLength(128, "Password is too long"))

    // Missing password
    #expect(passwordValidator.validate("") == "Password is required")

    // Too short
    #expect(passwordValidator.validate("abc") == "Password must be at least 8 characters")

    // Valid
    #expect(passwordValidator.validate("validpassword123") == nil)
  }

  @Test("username validation")
  func usernameValidation() {
    let usernameValidator = IronValidator<String>.required("Username is required")
      .and(.minLength(3, "Username too short"))
      .and(.maxLength(20, "Username too long"))
      .and(.alphanumeric("Username can only contain letters and numbers"))

    #expect(usernameValidator.validate("") == "Username is required")
    #expect(usernameValidator.validate("ab") == "Username too short")
    #expect(usernameValidator.validate("user@name") == "Username can only contain letters and numbers")
    #expect(usernameValidator.validate("validuser123") == nil)
  }

  @Test("age validation")
  func ageValidation() {
    let ageValidator = IronValidator<Int>.range(0...150, "Please enter a valid age")
      .and(.min(18, "Must be 18 or older"))

    #expect(ageValidator.validate(-1) == "Please enter a valid age")
    #expect(ageValidator.validate(17) == "Must be 18 or older")
    #expect(ageValidator.validate(25) == nil)
  }

  @Test("email with required validation")
  func emailWithRequired() {
    let emailValidator = IronValidator<String>.required("Email is required")
      .and(.email("Please enter a valid email"))

    #expect(emailValidator.validate("") == "Email is required")
    #expect(emailValidator.validate("invalid") == "Please enter a valid email")
    #expect(emailValidator.validate("valid@email.com") == nil)
  }
}
