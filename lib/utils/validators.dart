class Validators {
  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value, label: 'Email');
    if (requiredError != null) return requiredError;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = required(value, label: 'Password');
    if (requiredError != null) return requiredError;
    if (value!.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? phone(String? value) {
    final requiredError = required(value, label: 'Phone');
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 8) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  static String? positiveNumber(String? value, {String label = 'Value'}) {
    final requiredError = required(value, label: label);
    if (requiredError != null) return requiredError;
    final parsed = num.tryParse(value!.trim());
    if (parsed == null || parsed <= 0) {
      return '$label must be greater than zero';
    }
    return null;
  }
}
