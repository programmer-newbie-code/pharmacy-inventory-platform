import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/product_repository.dart';
import 'package:pharmacy_inventory_platform/data/stock_batch_repository.dart';
import 'package:pharmacy_inventory_platform/features/alerts/alerts_screen.dart';

void main() {
  testWidgets('renders AlertsScreen with prioritized alerts', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final productRepo = ProductRepository(db);
    final batchRepo = StockBatchRepository(db);

    final prodId = await productRepo.createProduct(
      barcode: '8993333444555',
      internalCode: 'ALT-MED',
      name: 'Alert Test Medicine',
      activeIngredient: 'TestIng',
      ingredientPct: 100.0,
      baseUnit: 'tablet',
      purchaseUnit: 'box',
      unitsPerPurchaseUnit: 10,
      costPricePerBaseUnit: 100.0,
      marginPct: 20.0,
      reorderThreshold: 50,
      category: 'General',
      createdBy: 'admin',
    );

    await batchRepo.createStockBatch(
      productId: prodId,
      batchNo: 'B-ALERT-01',
      receivedDate: DateTime.now(),
      expiryDate: DateTime.now().add(const Duration(days: 20)),
      qtyReceivedBaseUnit: 10,
      costPricePerBaseUnit: 100.0,
      supplier: 'Kimia Farma',
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
          home: AlertsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pharmacy Alerts'), findsOneWidget);
    expect(find.textContaining('Alert Test Medicine'), findsWidgets);
    expect(find.text('expiring'), findsOneWidget);
    expect(find.text('lowStock'), findsOneWidget);
  });
}
