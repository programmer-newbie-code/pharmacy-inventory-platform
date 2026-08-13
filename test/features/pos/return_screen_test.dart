import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/sale_repository.dart';
import 'package:pharmacy_inventory_platform/features/pos/return_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets('renders ReturnScreen, searches sale, and processes return', (tester) async {
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
            name: 'Paracetamol 500mg',
            activeIngredient: 'Paracetamol',
            ingredientPct: 100,
            baseUnit: 'tablet',
            purchaseUnit: 'strip',
            unitsPerPurchaseUnit: 10,
            costPricePerBaseUnit: 1000,
            marginPct: 50,
            reorderThreshold: 20,
            category: 'Obat Bebas',
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
    final prod = await (db.select(db.products)..where((p) => p.id.equals(10))).getSingle();
    final txn = await saleRepo.createSaleTransaction(
      cashierId: 1,
      items: [CartItemInput(product: prod, qtyBaseUnit: 5, unitPrice: 1500)],
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
          home: ReturnScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Returns & Refunds'), findsOneWidget);
    expect(find.byKey(const Key('searchTxnInput')), findsOneWidget);

    // Search for transaction
    await tester.enterText(find.byKey(const Key('searchTxnInput')), txn.txnNo);
    await tester.tap(find.byKey(const Key('searchTxnBtn')));
    await tester.pumpAndSettle();

    expect(find.text('Txn: ${txn.txnNo}'), findsOneWidget);
    expect(find.text('Paracetamol 500mg'), findsOneWidget);

    // Add return qty
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('processReturnBtn')), findsOneWidget);
    await tester.tap(find.byKey(const Key('processReturnBtn')));
    await tester.pumpAndSettle();

    expect(find.text('Return Processed'), findsOneWidget);
  });

  testWidgets('browses recent sales transactions from directory', (tester) async {
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
            name: 'Paracetamol 500mg',
            activeIngredient: 'Paracetamol',
            ingredientPct: 100,
            baseUnit: 'tablet',
            purchaseUnit: 'strip',
            unitsPerPurchaseUnit: 10,
            costPricePerBaseUnit: 1000,
            marginPct: 50,
            reorderThreshold: 20,
            category: 'Obat Bebas',
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
    final prod = await (db.select(db.products)..where((p) => p.id.equals(10))).getSingle();
    final txn = await saleRepo.createSaleTransaction(
      cashierId: 1,
      items: [CartItemInput(product: prod, qtyBaseUnit: 2, unitPrice: 1500)],
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
          home: ReturnScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('browseRecentTxnsBtn')), findsOneWidget);
    await tester.tap(find.byKey(const Key('browseRecentTxnsBtn')));
    await tester.pumpAndSettle();

    expect(find.text('Browse Recent Sales'), findsOneWidget);
    expect(find.byKey(Key('recentTxnTile_${txn.id}')), findsOneWidget);

    await tester.tap(find.byKey(Key('recentTxnTile_${txn.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Txn: ${txn.txnNo}'), findsOneWidget);
  });
}
