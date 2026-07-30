import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/auth/auth_session.dart';
import 'package:pharmacy_inventory_platform/features/home/home_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets('renders the app title from localized strings, default locale id',
      (tester) async {
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
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Platform Inventaris Apotek'), findsWidgets);
    expect(find.byKey(const Key('navBackupBtn')), findsOneWidget);
    expect(find.byKey(const Key('navUsersBtn')), findsOneWidget);
    expect(find.byKey(const Key('navReportsBtn')), findsOneWidget);
    expect(find.byKey(const Key('primaryStartSaleBtn')), findsOneWidget);
  });

  testWidgets('logout button clears the session', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    final hash = container.read(passwordHasherProvider).hash('secret123');
    await container.read(userRepositoryProvider).createUser(
          username: 'budi',
          passwordHash: hash,
          role: 'kasir',
        );
    await container.read(authSessionProvider.notifier).login('budi', 'secret123');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('id'),
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pump();

    expect(container.read(authSessionProvider), isNull);
  });
}
