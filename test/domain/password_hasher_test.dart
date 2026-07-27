import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/domain/password_hasher.dart';

void main() {
  final hasher = PasswordHasher();

  test('verify returns true for the password that was hashed', () {
    final hash = hasher.hash('correct horse battery staple');
    expect(hasher.verify('correct horse battery staple', hash), isTrue);
  });

  test('verify returns false for a wrong password', () {
    final hash = hasher.hash('correct horse battery staple');
    expect(hasher.verify('wrong password', hash), isFalse);
  });

  test('hashing the same password twice produces different hashes (random salt)', () {
    final first = hasher.hash('same password');
    final second = hasher.hash('same password');
    expect(first, isNot(equals(second)));
  });
}
