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

    expect(find.text('Manajemen Karyawan'), findsOneWidget);
    expect(find.text('admin_test'), findsOneWidget);

    // 1. Test Add User Dialog
    await tester.tap(find.byKey(const Key('addUserFab')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('addUsernameInput')), 'new_kasir');
    await tester.enterText(find.byKey(const Key('addPasswordInput')), 'kasir123');
    await tester.tap(find.byKey(const Key('submitAddUserBtn')));
    await tester.pumpAndSettle();

    expect(find.text('new_kasir'), findsOneWidget);

    // 2. Test Reset Password Dialog
    final user = await container.read(userRepositoryProvider).findByUsername('new_kasir');
    expect(user, isNotNull);

    await tester.tap(find.byKey(Key('resetPasswordBtn_${user!.id}')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('resetPasswordInput')), 'newpass123');
    await tester.tap(find.byKey(const Key('submitResetPassBtn')));
    await tester.pumpAndSettle();

    // 3. Test Change Role Dialog
    await tester.tap(find.byKey(Key('changeRoleBtn_${user.id}')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('submitChangeRoleBtn')));
    await tester.pumpAndSettle();
  });
}
