import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/inventory/edit_product_dialog.dart';

void main() {
  testWidgets('renders EditProductDialog and updates product details',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final prod = Product(
      id: 1,
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
      isControlled: false,
      category: 'Antibiotik',
      createdBy: 'admin',
      createdAt: DateTime.now(),
    );

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: EditProductDialog(product: prod),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Edit Product: Amoxicillin 500mg'), findsOneWidget);
    expect(find.byKey(const Key('saveEditProductBtn')), findsOneWidget);
  });
}
