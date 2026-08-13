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
  testWidgets(
      'uses the focused barcode field instead of camera scanning on Windows',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.windows),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('id'),
          home: const PosScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cameraScanBtn')), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('posSearchInput')))
          .autofocus,
      isTrue,
    );
  });

  testWidgets('renders PosScreen, adds product to cart, and completes checkout',
      (tester) async {
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
    expect(find.text('Struk Transaksi'), findsOneWidget);
    expect(find.byKey(const Key('closeReceiptButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('closeReceiptButton')));
    await tester.pumpAndSettle();
  });

  testWidgets('completes checkout with Owner Use payment option at 0 total',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final productRepo = ProductRepository(db);
    final batchRepo = StockBatchRepository(db);
    await CashierShiftRepository(db).openShift(cashierId: 1, openingBalance: 0);

    final prodId = await productRepo.createProduct(
      barcode: '8990000111223',
      internalCode: 'VIT-C2',
      name: 'Vitamin C 1000mg',
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
      batchNo: 'B-VIT-02',
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

    await tester.tap(find.byKey(Key('addToCart_${product.id}')));
    await tester.pump();

    // Select Owner Use payment option
    await tester.tap(find.byType(DropdownButtonHideUnderline));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Owner Use (Rp 0)').last);
    await tester.pumpAndSettle();

    expect(find.text('Rp 0 (Owner Use)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('checkoutButton')));
    await tester.pumpAndSettle();

    expect(find.text('Struk Transaksi'), findsOneWidget);
  });

  testWidgets('opens CashMovementDialog via posCashMovementBtn',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await CashierShiftRepository(db)
        .openShift(cashierId: 1, openingBalance: 100000);

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

    expect(find.byKey(const Key('posCashMovementBtn')), findsOneWidget);
    await tester.tap(find.byKey(const Key('posCashMovementBtn')));
    await tester.pumpAndSettle();

    expect(find.text('Catat Arus Kas / Prive Owner'), findsOneWidget);
  });

  testWidgets(
      'opens edit cart item quantity dialog and updates quantity directly',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final productRepo = ProductRepository(db);
    final prodId = await productRepo.createProduct(
      barcode: '8999999999999',
      internalCode: 'PAR-BOX',
      name: 'Paracetamol Box',
      activeIngredient: 'Paracetamol',
      ingredientPct: 100.0,
      baseUnit: 'tablet',
      purchaseUnit: 'box',
      unitsPerPurchaseUnit: 100,
      costPricePerBaseUnit: 100.0,
      marginPct: 20.0,
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('id'),
          home: PosScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('addToCart_$prodId')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('editCartQty_0')), findsOneWidget);

    final quantityControl = find.byKey(const Key('editCartQty_0'));
    await tester.ensureVisible(quantityControl);
    await tester.tap(quantityControl);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inputBoxQty')), findsOneWidget);
    expect(find.byKey(const Key('inputBaseQty')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('inputBoxQty')), '2');
    await tester.enterText(find.byKey(const Key('inputBaseQty')), '5');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('saveCartItemQtyBtn')));
    await tester.pumpAndSettle();

    expect(find.text('2 box + 5 tablet'), findsOneWidget);
  });
}
