import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/users/user_management_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets('renders UserManagementScreen and opens add user dialog', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    await container.read(userRepositoryProvider).createUser(
          username: 'admin_test',
          passwordHash: 'hash',
          role: 'admin',
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('id'),
          home: UserManagementScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Manajemen Karyawan & Pengguna'), findsOneWidget);
    expect(find.text('admin_test'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addUserFab')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('addUsernameInput')), findsOneWidget);
    expect(find.byKey(const Key('addPasswordInput')), findsOneWidget);
  });
}
