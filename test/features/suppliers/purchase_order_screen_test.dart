import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/purchase_order_repository.dart';
import 'package:pharmacy_inventory_platform/data/supplier_repository.dart';
import 'package:pharmacy_inventory_platform/features/suppliers/purchase_order_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets('renders PurchaseOrderScreen, creates PO, and receives delivery into stock', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // Seed product and supplier
    await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: const Value(10),
            barcode: '899123456701',
            internalCode: 'P001',
            name: 'Vitamin C 500mg',
            activeIngredient: 'Ascorbic Acid',
            ingredientPct: 100,
            baseUnit: 'tablet',
            purchaseUnit: 'bottle',
            unitsPerPurchaseUnit: 30,
            costPricePerBaseUnit: 500,
            marginPct: 50,
            reorderThreshold: 50,
            category: 'Vitamin',
            createdBy: 'admin',
          ),
        );

    final supplierRepo = SupplierRepository(db);
    await supplierRepo.createSupplier(name: 'PT Kalbe Farma');

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
          home: PurchaseOrderScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Purchase Orders & Reordering'), findsOneWidget);
    expect(find.byKey(const Key('createPoBtn')), findsOneWidget);

    // Tap create PO button
    await tester.tap(find.byKey(const Key('createPoBtn')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmCreatePoBtn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('receivePoBtn_1')), findsOneWidget);

    // Receive delivery
    await tester.tap(find.byKey(const Key('receivePoBtn_1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('confirmReceivePoBtn')), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmReceivePoBtn')));
    await tester.pumpAndSettle();

    // Verify status updated to RECEIVED
    expect(find.text('RECEIVED'), findsOneWidget);
  });

  testWidgets('cancels purchase order successfully', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: const Value(11),
            barcode: '899123456702',
            internalCode: 'P002',
            name: 'Paracetamol 500mg',
            activeIngredient: 'Paracetamol',
            ingredientPct: 100,
            baseUnit: 'tablet',
            purchaseUnit: 'bottle',
            unitsPerPurchaseUnit: 30,
            costPricePerBaseUnit: 200,
            marginPct: 50,
            reorderThreshold: 50,
            category: 'Analgesik',
            createdBy: 'admin',
          ),
        );

    final supplierRepo = SupplierRepository(db);
    await supplierRepo.createSupplier(name: 'PT Kimia Farma');

    final poRepo = PurchaseOrderRepository(db);
    final po = await poRepo.createPurchaseOrder(
      supplierId: 1,
      createdBy: 'admin',
      items: [POItemInput(productId: 11, qtyOrdered: 10, unitCost: 200)],
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
          home: PurchaseOrderScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(Key('cancelPoBtn_${po.id}')), findsOneWidget);
    await tester.tap(find.byKey(Key('cancelPoBtn_${po.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('confirmCancelPoBtn_${po.id}')), findsOneWidget);
    await tester.tap(find.byKey(Key('confirmCancelPoBtn_${po.id}')));
    await tester.pumpAndSettle();

    expect(find.text('CANCELLED'), findsOneWidget);
  });
}
