import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/auth/auth_session.dart';
import 'package:pharmacy_inventory_platform/features/auth/setup_admin_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets('creating the first admin logs them in', (tester) async {
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
          locale: Locale('id'),
          home: SetupAdminScreen(),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('setupAdminUsername')), 'budi');
    await tester.enterText(find.byKey(const Key('setupAdminPassword')), 'secret123');
    await tester.enterText(find.byKey(const Key('setupAdminConfirmPassword')), 'secret123');
    final submitBtn = find.byKey(const Key('setupAdminSubmit'));
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pump();

    expect(container.read(authSessionProvider)?.username, 'budi');
    expect(container.read(authSessionProvider)?.role, 'admin');
    expect(await container.read(userRepositoryProvider).countUsers(), 1);

    // Cancel the inactivity timer so it does not trip '!timersPending'.
    container.read(authSessionProvider.notifier).logout();
  });
}
