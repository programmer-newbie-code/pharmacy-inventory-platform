import 'package:drift/drift.dart' hide Column, isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/inventory/edit_product_dialog.dart';

import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets('renders EditProductDialog and updates product details',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: const Value(1),
            barcode: '8990001',
            internalCode: 'P-001',
            name: 'Amoxicillin 500mg',
            activeIngredient: 'Amoxicillin',
            ingredientPct: 100,
            baseUnit: 'kaplet',
            purchaseUnit: 'box',
            unitsPerPurchaseUnit: 100,
            costPricePerBaseUnit: 500,
            marginPct: 20,
            reorderThreshold: 50,
            isControlled: const Value(false),
            category: 'Antibiotik',
            createdBy: 'admin',
          ),
        );

    final prod = await (db.select(db.products)
          ..where((p) => p.id.equals(1)))
        .getSingle();

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('id'),
          home: Scaffold(
            body: EditProductDialog(product: prod),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Edit Detail Produk'), findsOneWidget);
    expect(find.byKey(const Key('saveEditProductBtn')), findsOneWidget);

    // Edit product name
    await tester.enterText(
        find.byKey(const Key('editProductNameInput')), 'Amoxicillin 500mg (Updated)');
    await tester.pumpAndSettle();

    // Change purchase unit price and base cost price
    await tester.dragUntilVisible(
      find.byKey(const Key('editBaseUnitDropdown')),
      find.byType(SingleChildScrollView),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();

    // Toggle controlled substance switch
    await tester.dragUntilVisible(
      find.byType(SwitchListTile),
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    // Tap Save
    await tester.dragUntilVisible(
      find.byKey(const Key('saveEditProductBtn')),
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    await tester.tap(find.byKey(const Key('saveEditProductBtn')));
    await tester.pumpAndSettle();

    final updatedProd = await (db.select(db.products)
          ..where((p) => p.id.equals(1)))
        .getSingle();

    expect(updatedProd.name, equals('Amoxicillin 500mg (Updated)'));
    expect(updatedProd.isControlled, isTrue);
  });
}
