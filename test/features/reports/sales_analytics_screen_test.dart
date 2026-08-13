import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/sale_repository.dart';
import 'package:pharmacy_inventory_platform/features/reports/sales_analytics_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets(
      'renders SalesAnalyticsScreen with executive metrics and best-selling medicines controls',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // Seed DB with user, product, batch, and sale
    await db.into(db.users).insert(
          UsersCompanion.insert(
            id: const Value(1),
            username: 'cashier1',
            passwordHash: 'hash',
            role: 'kasir',
          ),
        );
    await db.into(db.cashierShifts).insert(
          CashierShiftsCompanion.insert(
            cashierId: 1,
            openingBalance: 0,
            status: 'open',
          ),
        );
    await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: const Value(10),
            barcode: '899123456701',
            internalCode: 'P001',
            name: 'Amoxicillin 500mg',
            activeIngredient: 'Amoxicillin',
            ingredientPct: 100,
            baseUnit: 'kaplet',
            purchaseUnit: 'strip',
            unitsPerPurchaseUnit: 10,
            costPricePerBaseUnit: 1000,
            marginPct: 50,
            reorderThreshold: 20,
            category: 'Obat Keras',
            createdBy: 'admin',
          ),
        );
    await db.into(db.stockBatches).insert(
          StockBatchesCompanion.insert(
            id: const Value(101),
            productId: 10,
            batchNo: 'B001',
            receivedDate: DateTime.now(),
            expiryDate: DateTime.now().add(const Duration(days: 365)),
            qtyReceived: 100,
            qtyRemaining: 100,
            costPricePerBaseUnit: 1000,
            supplier: 'PT Pharma',
            createdBy: 'admin',
          ),
        );

    final saleRepo = SaleRepository(db);
    final prod = await (db.select(db.products)..where((p) => p.id.equals(10)))
        .getSingle();
    await saleRepo.createSaleTransaction(
      cashierId: 1,
      items: [CartItemInput(product: prod, qtyBaseUnit: 10, unitPrice: 1500)],
      paymentMethod: 'Cash',
    );

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
          home: SalesAnalyticsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sales Analytics & Insights'), findsOneWidget);
    expect(find.text('Net revenue'), findsNWidgets(3));
    expect(find.text('Gross revenue'), findsOneWidget);
    expect(find.text('Net profit'), findsOneWidget);
    expect(find.text('Amoxicillin 500mg'), findsOneWidget);
    expect(find.text('Sales by product category'), findsOneWidget);
    expect(find.text('Best-selling medicines'), findsOneWidget);
    expect(find.text('Net units'), findsNWidgets(2));
    expect(find.text('Custom Date Range'), findsOneWidget);
  });

  testWidgets(
      'export button is enabled with sales data and shows busy state on tap',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.into(db.users).insert(
          UsersCompanion.insert(
            id: const Value(1),
            username: 'cashier1',
            passwordHash: 'hash',
            role: 'kasir',
          ),
        );
    await db.into(db.cashierShifts).insert(
          CashierShiftsCompanion.insert(
            cashierId: 1,
            openingBalance: 0,
            status: 'open',
          ),
        );
    await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: const Value(10),
            barcode: '899123456701',
            internalCode: 'P001',
            name: 'Amoxicillin 500mg',
            activeIngredient: 'Amoxicillin',
            ingredientPct: 100,
            baseUnit: 'kaplet',
            purchaseUnit: 'strip',
            unitsPerPurchaseUnit: 10,
            costPricePerBaseUnit: 1000,
            marginPct: 50,
            reorderThreshold: 20,
            category: 'Obat Keras',
            createdBy: 'admin',
          ),
        );
    await db.into(db.stockBatches).insert(
          StockBatchesCompanion.insert(
            id: const Value(101),
            productId: 10,
            batchNo: 'B001',
            receivedDate: DateTime.now(),
            expiryDate: DateTime.now().add(const Duration(days: 365)),
            qtyReceived: 100,
            qtyRemaining: 100,
            costPricePerBaseUnit: 1000,
            supplier: 'PT Pharma',
            createdBy: 'admin',
          ),
        );

    final saleRepo = SaleRepository(db);
    final prod = await (db.select(db.products)..where((p) => p.id.equals(10)))
        .getSingle();
    await saleRepo.createSaleTransaction(
      cashierId: 1,
      items: [CartItemInput(product: prod, qtyBaseUnit: 10, unitPrice: 1500)],
      paymentMethod: 'Cash',
    );

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
          home: SalesAnalyticsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final exportButtonFinder = find.byKey(const Key('exportBestSellingBtn'));
    expect(exportButtonFinder, findsOneWidget);

    final button = tester.widget<OutlinedButton>(exportButtonFinder);
    expect(button.onPressed, isNotNull,
        reason: 'export button must be enabled when best-selling rows exist');

    await tester.tap(exportButtonFinder);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('export button is disabled when there are no sales in period',
      (tester) async {
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
          home: SalesAnalyticsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final exportButtonFinder = find.byKey(const Key('exportBestSellingBtn'));
    expect(exportButtonFinder, findsOneWidget);

    final button = tester.widget<OutlinedButton>(exportButtonFinder);
    expect(button.onPressed, isNull,
        reason: 'export button must be disabled when there is nothing to export');
  });
}
