import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/purchase_order_repository.dart';
import 'package:pharmacy_inventory_platform/data/supplier_repository.dart';
import 'package:pharmacy_inventory_platform/features/auth/auth_session.dart';
import 'package:pharmacy_inventory_platform/features/suppliers/purchase_receiving_screen.dart';

class _AuthenticatedSession extends AuthSession {
  _AuthenticatedSession(this.user);

  final User user;

  @override
  User build() => user;
}

void main() {
  testWidgets('renders PurchaseReceivingScreen and completes receiving session',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final supplierRepo = SupplierRepository(db);
    final poRepo = PurchaseOrderRepository(db);

    await db.into(db.users).insert(
          UsersCompanion.insert(
            id: const Value(2),
            username: 'receiver',
            passwordHash: 'hash',
            role: 'inventory',
          ),
        );
    final receiver =
        await (db.select(db.users)..where((u) => u.id.equals(2))).getSingle();

    await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: const Value(10),
            barcode: '899123456701',
            internalCode: 'P001',
            name: 'Paracetamol 500mg',
            activeIngredient: 'Paracetamol',
            ingredientPct: 100,
            baseUnit: 'tablet',
            purchaseUnit: 'box',
            unitsPerPurchaseUnit: 100,
            costPricePerBaseUnit: 200,
            marginPct: 30,
            reorderThreshold: 100,
            category: 'Analgesic',
            createdBy: 'admin',
          ),
        );

    final supplier = await supplierRepo.createSupplier(name: 'PT Kimia Farma');
    final po = await poRepo.createPurchaseOrder(
      supplierId: supplier.id,
      createdBy: 'admin',
      items: [
        POItemInput(productId: 10, qtyOrdered: 100, unitCost: 200),
      ],
    );

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      authSessionProvider.overrideWith(() => _AuthenticatedSession(receiver)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PurchaseReceivingScreen(purchaseOrderId: po.id),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Receive'), findsWidgets);
    expect(find.text('Paracetamol 500mg'), findsOneWidget);

    // Enter batch number
    await tester.enterText(
        find.widgetWithText(TextField, 'Batch No *'), 'BATCH-001');
    await tester.pumpAndSettle();

    // Complete receiving
    await tester.tap(find.byKey(const Key('completeReceivingBtn')));
    await tester.pumpAndSettle();

    // Verify PO status in DB updated to received
    final updatedPo = await (db.select(db.purchaseOrders)
          ..where((p) => p.id.equals(po.id)))
        .getSingle();
    expect(updatedPo.status, equals('received'));

    final receivingItem = await (db.select(db.purchaseReceivingItems)
          ..where((item) => item.purchaseOrderId.equals(po.id)))
        .getSingle();
    expect(receivingItem.receivedBy, equals(receiver.id));
  });
}
