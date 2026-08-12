import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/home/home_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'desktop workspace navigation is labelled and touch-sized',
    (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PharmacyShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Keyboard traversal itself is asserted in
      // test/features/home/home_screen_test.dart; this test covers semantics
      // and touch target only, which is what its name now claims.
      final inventory = find.byKey(const Key('desktopNavInventory'));
      expect(tester.getSemantics(inventory).label, 'Inventory Catalog');
      expect(tester.getSize(inventory).height, greaterThanOrEqualTo(48));
      await tester.tap(inventory);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('desktopSidebar')), findsOneWidget);
    },
  );

  testWidgets('phone workspace keeps labelled primary navigation visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PharmacyShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mobileShellNavigation')), findsOneWidget);
    expect(find.text('POS Register'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
