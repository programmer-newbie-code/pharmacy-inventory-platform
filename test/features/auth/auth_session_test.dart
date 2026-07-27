import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/auth/auth_session.dart';

void main() {
  test('login succeeds with the right password and fails with the wrong one', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);

    final hasher = container.read(passwordHasherProvider);
    await container.read(userRepositoryProvider).createUser(
          username: 'budi',
          passwordHash: hasher.hash('secret123'),
          role: 'admin',
        );

    expect(container.read(authSessionProvider), isNull);

    final wrongPassword = await container
        .read(authSessionProvider.notifier)
        .login('budi', 'wrong-password');
    expect(wrongPassword, isFalse);
    expect(container.read(authSessionProvider), isNull);

    final rightPassword = await container
        .read(authSessionProvider.notifier)
        .login('budi', 'secret123');
    expect(rightPassword, isTrue);
    expect(container.read(authSessionProvider)!.username, 'budi');

    container.read(authSessionProvider.notifier).logout();
    expect(container.read(authSessionProvider), isNull);
  });
}
