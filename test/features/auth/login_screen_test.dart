import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/auth/auth_session.dart';
import 'package:pharmacy_inventory_platform/features/auth/login_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  Future<ProviderContainer> setUpWithOneUser(WidgetTester tester) async {
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('id'),
          home: LoginScreen(),
        ),
      ),
    );
    return container;
  }

  testWidgets('correct credentials log the user in', (tester) async {
    final container = await setUpWithOneUser(tester);

    await tester.enterText(find.byKey(const Key('loginUsername')), 'budi');
    await tester.enterText(find.byKey(const Key('loginPassword')), 'secret123');
    await tester.tap(find.byKey(const Key('loginSubmit')));
    await tester.pumpAndSettle();

    expect(container.read(authSessionProvider)?.username, 'budi');
  });

  testWidgets('wrong password shows the error and does not log in', (tester) async {
    final container = await setUpWithOneUser(tester);

    await tester.enterText(find.byKey(const Key('loginUsername')), 'budi');
    await tester.enterText(find.byKey(const Key('loginPassword')), 'wrong');
    await tester.tap(find.byKey(const Key('loginSubmit')));
    await tester.pumpAndSettle();

    expect(container.read(authSessionProvider), isNull);
    expect(find.text('Nama pengguna atau kata sandi salah. Coba lagi.'), findsOneWidget);
  });
}
