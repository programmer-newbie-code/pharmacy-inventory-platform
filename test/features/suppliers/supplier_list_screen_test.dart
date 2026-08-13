import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/suppliers/supplier_list_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets('renders SupplierListScreen and adds a new supplier', (tester) async {
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
          home: SupplierListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Suppliers Directory'), findsOneWidget);
    expect(find.byKey(const Key('addSupplierBtn')), findsOneWidget);

    await tester.tap(find.byKey(const Key('addSupplierBtn')));
    await tester.pumpAndSettle();

    expect(find.text('Add New Supplier'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('supplierNameInput')), 'PT Kimia Farma');
    await tester.enterText(find.byKey(const Key('supplierPaymentTermsInput')), 'Net 30');
    await tester.tap(find.byKey(const Key('confirmAddSupplierBtn')));
    await tester.pumpAndSettle();

    expect(find.text('PT Kimia Farma'), findsOneWidget);
    expect(find.textContaining('Net 30'), findsOneWidget);
  });

  testWidgets('search and filter active suppliers works correctly', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final supplierRepo = containerRef(db).read(supplierRepositoryProvider);
    await supplierRepo.createSupplier(name: 'PT Kalbe');
    final s2 = await supplierRepo.createSupplier(name: 'PT Biofarma');
    await supplierRepo.deactivateSupplier(s2.id);

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
          home: SupplierListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Active only by default -> PT Kalbe visible, PT Biofarma hidden
    expect(find.text('PT Kalbe'), findsOneWidget);
    expect(find.text('PT Biofarma'), findsNothing);

    // Toggle active only filter off
    await tester.tap(find.byKey(const Key('activeFilterChip')));
    await tester.pumpAndSettle();

    expect(find.text('PT Kalbe'), findsOneWidget);
    expect(find.text('PT Biofarma'), findsOneWidget);

    // Search filter
    await tester.enterText(find.byKey(const Key('supplierSearchInput')), 'Bio');
    await tester.pumpAndSettle();

    expect(find.text('PT Kalbe'), findsNothing);
    expect(find.text('PT Biofarma'), findsOneWidget);
  });
}

ProviderContainer containerRef(AppDatabase db) => ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
