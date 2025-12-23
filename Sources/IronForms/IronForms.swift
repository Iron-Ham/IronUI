// IronForms - Form components and validation
// Contains: Form, FormField, DatePicker, validation utilities

@_exported import IronComponents
@_exported import IronCore
@_exported import IronPrimitives

/// The IronForms module provides form-related components.
///
/// ## Form Components
///
/// - ``IronForm`` - Scrollable form container
/// - ``IronFormSection`` - Groups related fields with header/footer
/// - ``IronFormRow`` - Horizontal layout for side-by-side fields
/// - ``IronFormField`` - Wrapper with label, hint, and error display
///
/// ## Date & Time
///
/// - ``IronDatePicker`` - Themed date selection
/// - ``IronTimePicker`` - Themed time selection
///
/// ## Validation
///
/// - ``IronValidator`` - Composable validation rules
/// - ``IronValidatedField`` - Property wrapper for automatic validation
///
/// ## Example
///
/// ```swift
/// @IronValidatedField(validators: [.required(), .email()])
/// var email = ""
///
/// IronForm {
///   IronFormSection("Contact") {
///     IronFormField("Email", error: $email.error) {
///       IronTextField("Enter email", text: $email.binding)
///     }
///   }
/// }
/// ```
public enum IronForms {
  /// The current version of IronForms.
  public static let version = "0.1.0"
}
