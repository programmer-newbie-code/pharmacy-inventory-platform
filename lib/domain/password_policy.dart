import 'dart:convert';
import 'dart:io';

/// Validates passwords against pharmacy compliance policy.
///
/// Rules:
/// - Minimum 8 characters
/// - Not a common/weak password
/// - Contains at least one letter and one digit
class PasswordPolicy {
  final int minLength;
  final Set<String> _commonPasswords;

  PasswordPolicy({this.minLength = 8})
      : _commonPasswords = _defaultCommonPasswords();

  PasswordValidationResult validate(String password) {
    final errors = <String>[];

    if (password.length < minLength) {
      errors.add('Password must be at least $minLength characters.');
    }
    if (!RegExp(r'(?=.*[A-Za-z])(?=.*\d)').hasMatch(password)) {
      errors.add('Password must contain at least one letter and one digit.');
    }
    if (_commonPasswords.contains(password.toLowerCase())) {
      errors.add('Password is too common. Choose a more unique password.');
    }

    return PasswordValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  static Set<String> _defaultCommonPasswords() => {
        'password', 'password1', 'password123',
        '12345678', '123456789', 'qwerty123',
        'admin123', 'letmein', 'welcome1',
        'monkey123', 'passw0rd', 'hello123',
      };
}

class PasswordValidationResult {
  final bool isValid;
  final List<String> errors;

  PasswordValidationResult({
    required this.isValid,
    required this.errors,
  });
}
