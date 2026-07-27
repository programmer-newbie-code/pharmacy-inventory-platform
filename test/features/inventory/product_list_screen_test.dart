import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/product_repository.dart';
import 'package:pharmacy_inventory_platform/features/inventory/product_list_screen.dart';

void main() {
  testWidgets('renders product list screen and opens add product dialog', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final productRepo = ProductRepository(db);
    await productRepo.createProduct(
      barcode: '8990000000001',
      internalCode: 'PCT-100',
      name: 'Paracetamol Syrup',
      activeIngredient: 'Paracetamol',
      ingredientPct: 100.0,
      baseUnit: 'botol',
      purchaseUnit: 'dus',
      unitsPerPurchaseUnit: 24,
      costPricePerBaseUnit: 12000.0,
      marginPct: 15.0,
      reorderThreshold: 10,
      category: 'Obat Bebas',
      createdBy: 'admin',
    );

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ProductListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Inventory Catalog'), findsOneWidget);
    expect(find.text('Paracetamol Syrup'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addProductFab')));
    await tester.pumpAndSettle();

    expect(find.text('Add New Product'), findsOneWidget);
  });
}
