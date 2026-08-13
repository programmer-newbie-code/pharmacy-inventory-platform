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
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

class _AuthenticatedSession extends AuthSession {
  _AuthenticatedSession(this.user);

  final User user;

  @override
  User build() => user;
}

class _ReceivingFixture {
  const _ReceivingFixture({
    required this.db,
    required this.po,
    required this.receiver,
  });

  final AppDatabase db;
  final PurchaseOrder po;
  final User receiver;
}

Future<_ReceivingFixture> _createFixture() async {
  final db = AppDatabase(NativeDatabase.memory());
  final supplierRepo = SupplierRepository(db);
  final poRepo = PurchaseOrderRepository(db);

  await db.batch((batch) {
    batch.insertAll(db.users, [
      UsersCompanion.insert(
        id: const Value(1),
        username: 'admin',
        passwordHash: 'hash',
        role: 'admin',
      ),
      UsersCompanion.insert(
        id: const Value(2),
        username: 'receiver',
        passwordHash: 'hash',
        role: 'inventory',
      ),
    ]);
    batch.insert(
      db.products,
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
  });

  final receiver = await (db.select(
    db.users,
  )..where((u) => u.id.equals(2)))
      .getSingle();
  final supplier = await supplierRepo.createSupplier(name: 'PT Kimia Farma');
  final po = await poRepo.createPurchaseOrder(
    supplierId: supplier.id,
    createdBy: 'admin',
    items: [POItemInput(productId: 10, qtyOrdered: 100, unitCost: 200)],
  );
  return _ReceivingFixture(db: db, po: po, receiver: receiver);
}

Widget _app(
  ProviderContainer container,
  int purchaseOrderId, {
  Locale? locale,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PurchaseReceivingScreen(purchaseOrderId: purchaseOrderId),
    ),
  );
}

void main() {
  testWidgets(
    'renders PurchaseReceivingScreen and completes receiving session',
    (tester) async {
      final fixture = await _createFixture();
      addTearDown(fixture.db.close);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(fixture.db),
          authSessionProvider.overrideWith(
            () => _AuthenticatedSession(fixture.receiver),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_app(container, fixture.po.id));

      await tester.pumpAndSettle();

      expect(find.textContaining('Receive'), findsWidgets);
      expect(find.text('Paracetamol 500mg'), findsOneWidget);

      // Enter batch number
      await tester.enterText(
        find.widgetWithText(TextField, 'Batch No *'),
        'BATCH-001',
      );
      await tester.pumpAndSettle();

      // Complete receiving
      await tester.tap(find.byKey(const Key('completeReceivingBtn')));
      await tester.pumpAndSettle();

      // Verify PO status in DB updated to received
      final updatedPo = await (fixture.db.select(
        fixture.db.purchaseOrders,
      )..where((p) => p.id.equals(fixture.po.id)))
          .getSingle();
      expect(updatedPo.status, equals('received'));

      final receivingItem =
          await (fixture.db.select(fixture.db.purchaseReceivingItems)
                ..where((item) => item.purchaseOrderId.equals(fixture.po.id)))
              .getSingle();
      expect(receivingItem.receivedBy, equals(fixture.receiver.id));
    },
  );

  testWidgets('signed-out completion creates no receiving mutation', (
    tester,
  ) async {
    final fixture = await _createFixture();
    addTearDown(fixture.db.close);

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(fixture.db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_app(container, fixture.po.id));
    await tester.pumpAndSettle();

    final initialStockBatches =
        await fixture.db.select(fixture.db.stockBatches).get();
    final initialAuditLogs =
        await fixture.db.select(fixture.db.auditLogs).get();

    await tester.enterText(
      find.widgetWithText(TextField, 'Batch No *'),
      'BATCH-001',
    );
    await tester.tap(find.byKey(const Key('completeReceivingBtn')));
    await tester.pumpAndSettle();

    final receivingItems =
        await fixture.db.select(fixture.db.purchaseReceivingItems).get();
    final stockBatches = await fixture.db.select(fixture.db.stockBatches).get();
    final auditLogs = await fixture.db.select(fixture.db.auditLogs).get();
    final unchangedPo = await (fixture.db.select(
      fixture.db.purchaseOrders,
    )..where((po) => po.id.equals(fixture.po.id)))
        .getSingle();

    expect(receivingItems, isEmpty);
    expect(stockBatches, hasLength(initialStockBatches.length));
    expect(auditLogs, hasLength(initialAuditLogs.length));
    expect(unchangedPo.status, fixture.po.status);
    expect(find.text('Please sign in again to continue.'), findsOneWidget);
  });

  testWidgets('renders and validates receiving workflow in Indonesian', (
    tester,
  ) async {
    final fixture = await _createFixture();
    addTearDown(fixture.db.close);

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(fixture.db),
        authSessionProvider.overrideWith(
          () => _AuthenticatedSession(fixture.receiver),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _app(container, fixture.po.id, locale: const Locale('id')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Terima PO'), findsOneWidget);
    expect(find.text('Selesaikan'), findsOneWidget);
    expect(find.text('Jumlah Diterima'), findsOneWidget);
    expect(find.text('Nomor Batch *'), findsOneWidget);

    await tester.tap(find.byKey(const Key('completeReceivingBtn')));
    await tester.pump();

    expect(
      find.text('Nomor batch wajib diisi untuk Paracetamol 500mg'),
      findsOneWidget,
    );
  });
}
