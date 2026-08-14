import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/auth/auth_session.dart';
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

    // The role subtitle renders from ARB via l10n.userRoleSubtitle(role),
    // in the pumped locale (id): 'Peran: ADMIN', not 'Role: ADMIN'.
    expect(find.text('Peran: ADMIN'), findsOneWidget);
    expect(find.text('Role: ADMIN'), findsNothing);

    // 1. Test Add User Dialog
    await tester.tap(find.byKey(const Key('addUserFab')));
    await tester.pumpAndSettle();

    expect(find.text('Simpan'), findsOneWidget);

    // Open the role dropdown to render all item labels from ARB.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Inventaris'), findsOneWidget);
    expect(find.text('Auditor'), findsOneWidget);
    // Close the dropdown by selecting the default (kasir) option again.
    await tester.tap(find.text('Kasir').last);
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

  testWidgets('renders access-denied and empty-state copy in English',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.into(db.users).insert(
          UsersCompanion.insert(
            id: const Value(9),
            username: 'cashier_only',
            passwordHash: 'hash',
            role: 'kasir',
          ),
        );
    final cashier =
        await (db.select(db.users)..where((u) => u.id.equals(9))).getSingle();

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      authSessionProvider.overrideWith(() => _AuthenticatedSession(cashier)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: UserManagementScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // A cashier session is not allowed to manage users, so the screen shows
    // the access-denied copy; assert the English strings render from ARB and
    // the Indonesian literals ('Akses Ditolak', 'Manajemen karyawan hanya
    // dapat diakses oleh Admin.') are not shown.
    expect(find.text('Access Denied'), findsOneWidget);
    expect(
      find.text('Employee management can only be accessed by Admin.'),
      findsOneWidget,
    );
    expect(find.text('Akses Ditolak'), findsNothing);
    expect(
      find.text('Manajemen karyawan hanya dapat diakses oleh Admin.'),
      findsNothing,
    );
  });

  testWidgets('renders empty-state copy in English', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: UserManagementScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // No users exist yet in this fresh database, and no auth session is
    // overridden (currentUser == null falls back to allowed, matching the
    // screen's own null-check), so the empty-state copy renders.
    expect(find.text('No employee accounts registered.'), findsOneWidget);
    expect(find.text('Belum ada akun karyawan terdaftar.'), findsNothing);
  });
}

class _AuthenticatedSession extends AuthSession {
  _AuthenticatedSession(this.user);

  final User user;

  @override
  User build() => user;
}
