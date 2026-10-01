class AppValidators {
  static String? required(String? value,
      {String label = 'This field',
      String message = 'Please fill this field.'}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return message;
    }
    return null;
  }

  static String? requiredText(String? value,
      {String message = 'Please fill this field.'}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return message;
    }
    return null;
  }

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
