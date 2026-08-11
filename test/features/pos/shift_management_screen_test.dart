import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/auth/auth_session.dart';
import 'package:pharmacy_inventory_platform/features/pos/shift_management_screen.dart';

import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets('renders ShiftManagementScreen and opens shift', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.into(db.users).insert(
          UsersCompanion.insert(
            id: const Value(2),
            username: 'cashier',
            passwordHash: 'hash',
            role: 'cashier',
          ),
        );
    final user =
        await (db.select(db.users)..where((u) => u.id.equals(2))).getSingle();
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      authSessionProvider.overrideWith(() => _AuthenticatedSession(user)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('id'),
          home: ShiftManagementScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rekonsiliasi Kas Shift'), findsOneWidget);
    expect(find.byKey(const Key('openShiftBtn')), findsOneWidget);

    await tester.tap(find.byKey(const Key('openShiftBtn')));
    await tester.pumpAndSettle();

    expect(find.text('Buka shift kasir'), findsOneWidget);
    expect(find.byKey(const Key('confirmOpenShiftBtn')), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmOpenShiftBtn')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Shift aktif (terbuka)'), findsOneWidget);
    expect(find.byKey(const Key('cashMovementBtn')), findsOneWidget);
    expect(find.byKey(const Key('closeShiftBtn')), findsOneWidget);

    await tester.tap(find.byKey(const Key('cashMovementBtn')));
    await tester.pumpAndSettle();
    expect(find.text('Catat Arus Kas / Prive Owner'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('closeShiftBtn')));
    await tester.pumpAndSettle();

    expect(find.text('Tutup shift dan rekonsiliasi kas'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('actualCashInput')), '100000');
    await tester.tap(find.byKey(const Key('confirmCloseShiftBtn')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tidak ada shift aktif'), findsOneWidget);
    expect(
        find.textContaining('Shift ditutup dan kas seimbang.'), findsWidgets);
  });
}

class _AuthenticatedSession extends AuthSession {
  _AuthenticatedSession(this.user);

  final User user;

  @override
  User build() => user;
}
