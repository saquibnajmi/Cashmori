// Shared validation helpers used by forms across the app.
// They keep input checks consistent for required fields and numeric values.
class AppValidators {
  // Checks whether a text field has any meaningful content after trimming spaces.
  /// Validates that a field contains at least one non-whitespace character.
  static String? required(String? value,
      {String label = 'This field',
      String message = 'Please fill this field.'}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return message;
    }
    return null;
  }

  // Variant used by text inputs that only need a non-empty value without extra labels.
  /// Convenience version of [required] for plain text inputs without a label.
  static String? requiredText(String? value,
      {String message = 'Please fill this field.'}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return message;
    }
    return null;
  }

  // Restricts values to numbers greater than zero, which is used for amounts.
  /// Ensures a value is a positive number, typically used for monetary amounts.
  static String? positiveNumber(String? value,
      {String message = 'Enter a valid amount greater than zero.'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please fill this field.';
    }

    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return message;
    }
    return null;
  }

  // Accepts zero and positive values for totals or quantities that can be zero.
  /// Accepts zero or higher values for numbers like quantities or totals.
  static String? nonNegativeNumber(String? value,
      {String message = 'Enter a valid number.'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please fill this field.';
    }

    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return message;
    }
    return null;
  }
}
