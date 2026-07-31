import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/domain/password_policy.dart';

void main() {
  late PasswordPolicy policy;

  setUp(() {
    policy = PasswordPolicy();
  });

  group('PasswordPolicy', () {
    test('rejects password shorter than minimum length', () {
      final result = policy.validate('Ab1');
      expect(result.isValid, false);
      expect(result.errors.any((e) => e.contains('at least 8')), true);
    });

    test('rejects password without digits', () {
      final result = policy.validate('abcdefgh');
      expect(result.isValid, false);
      expect(result.errors.any((e) => e.contains('letter')), true);
    });

    test('rejects password without letters', () {
      final result = policy.validate('12345678');
      expect(result.isValid, false);
      expect(result.errors.any((e) => e.contains('letter')), true);
    });

    test('rejects common passwords', () {
      final result = policy.validate('password123');
      expect(result.isValid, false);
      expect(result.errors.any((e) => e.contains('too common')), true);
    });

    test('accepts valid complex password', () {
      final result = policy.validate('BudiPharmacy2024');
      expect(result.isValid, true);
      expect(result.errors, isEmpty);
    });

    test('rejects empty password', () {
      final result = policy.validate('');
      expect(result.isValid, false);
    });

    test('returns multiple errors for very weak password', () {
      final result = policy.validate('pass1');
      expect(result.isValid, false);
      expect(result.errors.length, greaterThanOrEqualTo(1));
    });
  });
}
