import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/cashier_shift_repository.dart';
import 'package:pharmacy_inventory_platform/data/product_repository.dart';
import 'package:pharmacy_inventory_platform/data/stock_batch_repository.dart';
import 'package:pharmacy_inventory_platform/features/pos/pos_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets('renders PosScreen, adds product to cart, and completes checkout', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final productRepo = ProductRepository(db);
    final batchRepo = StockBatchRepository(db);
    await CashierShiftRepository(db).openShift(cashierId: 1, openingBalance: 0);

    final prodId = await productRepo.createProduct(
      barcode: '8990000111222',
      internalCode: 'VIT-C',
      name: 'Vitamin C 500mg',
      activeIngredient: 'Ascorbic Acid',
      ingredientPct: 100.0,
      baseUnit: 'tablet',
      purchaseUnit: 'botol',
      unitsPerPurchaseUnit: 30,
      costPricePerBaseUnit: 500.0,
      marginPct: 20.0,
      reorderThreshold: 10,
      category: 'Vitamin',
      createdBy: 'admin',
    );

    final product = (await productRepo.getProductById(prodId))!;

    await batchRepo.createStockBatch(
      productId: product.id,
      batchNo: 'B-VIT-01',
      receivedDate: DateTime(2026, 7, 1),
      expiryDate: DateTime(2027, 1, 1),
      qtyReceivedBaseUnit: 100,
      costPricePerBaseUnit: 500.0,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('id'),
          home: PosScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Kasir POS'), findsOneWidget);
    expect(find.text('Vitamin C 500mg'), findsOneWidget);

    // Tap Add to Cart button
    await tester.tap(find.byKey(Key('addToCart_${product.id}')));
    await tester.pump();

    expect(find.text('1 item'), findsOneWidget);

    // Complete Checkout
    await tester.tap(find.byKey(const Key('checkoutButton')));
    await tester.pumpAndSettle();

    // Verify receipt modal appears
    expect(find.text('Transaction Receipt'), findsOneWidget);
    expect(find.byKey(const Key('closeReceiptButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('closeReceiptButton')));
    await tester.pumpAndSettle();
  });
}
