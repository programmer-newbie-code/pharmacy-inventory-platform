import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/product_repository.dart';
import 'package:pharmacy_inventory_platform/features/inventory/add_stock_batch_dialog.dart';

import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets('renders and submits AddStockBatchDialog form with unit conversion preview',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final productRepo = ProductRepository(db);
    final prodId = await productRepo.createProduct(
      barcode: '8995555444333',
      internalCode: 'CTZ-10',
      name: 'Cetirizine 10mg',
      activeIngredient: 'Cetirizine',
      ingredientPct: 100.0,
      baseUnit: 'tablet',
      purchaseUnit: 'strip',
      unitsPerPurchaseUnit: 10,
      costPricePerBaseUnit: 300.0,
      marginPct: 20.0,
      reorderThreshold: 20,
      category: 'Antihistamin',
      createdBy: 'admin',
    );

    final product = (await productRepo.getProductById(prodId))!;

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('id'),
          home: Scaffold(
            body: AddStockBatchDialog(product: product),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Receive Stock: Cetirizine 10mg'), findsOneWidget);
    expect(find.text('= 10 tablets total stock'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('batchNoInput')), 'B-2026-001');
    await tester.enterText(find.byKey(const Key('supplierInput')), 'PT Medika');
    await tester.enterText(find.byKey(const Key('qtyPurchaseUnitInput')), '5');
    await tester.pump();

    expect(find.text('= 50 tablets total stock'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('saveBatchButton')));
    await tester.tap(find.byKey(const Key('saveBatchButton')));
    await tester.pumpAndSettle();

    final batchRepo = container.read(stockBatchRepositoryProvider);
    final batches = await batchRepo.listBatchesForProduct(prodId);
    expect(batches, hasLength(1));
    expect(batches.first.batchNo, equals('B-2026-001'));
    expect(batches.first.qtyReceived, equals(50));
  });
}
