import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/purchase_order_repository.dart';
import 'package:pharmacy_inventory_platform/data/supplier_repository.dart';

void main() {
  late AppDatabase db;
  late SupplierRepository supplierRepo;
  late PurchaseOrderRepository poRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    supplierRepo = SupplierRepository(db);
    poRepo = PurchaseOrderRepository(db);

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
  });

  tearDown(() async {
    await db.close();
  });

  test('createSupplier and listSuppliers work correctly', () async {
    final supplier = await supplierRepo.createSupplier(
      name: 'PT Kalbe Farma',
      contactPerson: 'Budi',
      phone: '081234567890',
    );

    expect(supplier.name, equals('PT Kalbe Farma'));

    final list = await supplierRepo.listSuppliers();
    expect(list, hasLength(1));
  });

  test('createPurchaseOrder and receivePurchaseOrder auto-creates stock batch', () async {
    final supplier = await supplierRepo.createSupplier(name: 'PT Biofarma');

    final po = await poRepo.createPurchaseOrder(
      supplierId: supplier.id,
      createdBy: 'admin',
      items: [
        POItemInput(productId: 10, qtyOrdered: 100, unitCost: 500),
      ],
    );

    expect(po.status, equals('sent'));
    expect(po.totalAmount, equals(50000));

    final items = await poRepo.getPOItems(po.id);
    expect(items, hasLength(1));

    // Receive purchase order delivery
    final expiry = DateTime.now().add(const Duration(days: 365));
    final receivedPo = await poRepo.receivePurchaseOrder(
      poId: po.id,
      batchNoPrefix: 'BATCH-2026',
      expiryDate: expiry,
    );

    expect(receivedPo.status, equals('received'));

    // Check that a new StockBatch was auto-created in database
    final batches = await (db.select(db.stockBatches)..where((b) => b.productId.equals(10))).get();
    expect(batches, hasLength(1));
    expect(batches.first.batchNo, equals('BATCH-2026-10-100'));
    expect(batches.first.qtyRemaining, equals(100));
    expect(batches.first.supplier, equals('PT Biofarma'));
  });

  test('partial receipt creates batches only for delivered lines and keeps PO open', () async {
    await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: const Value(11),
            barcode: '899123456702',
            internalCode: 'P002',
            name: 'Vitamin D 1000IU',
            activeIngredient: 'Cholecalciferol',
            ingredientPct: 100,
            baseUnit: 'tablet',
            purchaseUnit: 'bottle',
            unitsPerPurchaseUnit: 30,
            costPricePerBaseUnit: 700,
            marginPct: 50,
            reorderThreshold: 50,
            category: 'Vitamin',
            createdBy: 'admin',
          ),
        );
    final supplier = await supplierRepo.createSupplier(name: 'PT Biofarma');
    final po = await poRepo.createPurchaseOrder(
      supplierId: supplier.id,
      createdBy: 'admin',
      items: [
        POItemInput(productId: 10, qtyOrdered: 100, unitCost: 500),
        POItemInput(productId: 11, qtyOrdered: 40, unitCost: 700),
      ],
    );
    final items = await poRepo.getPOItems(po.id);

    final partial = await poRepo.receivePurchaseOrder(
      poId: po.id,
      batchNoPrefix: 'PARTIAL',
      expiryDate: DateTime(2027, 1, 1),
      quantitiesByItemId: {items.first.id: 25},
    );

    expect(partial.status, 'sent');
    expect(partial.receivedAt, isNull);
    final afterPartial = await poRepo.getPOItems(po.id);
    expect(afterPartial.first.qtyReceived, 25);
    expect(afterPartial.last.qtyReceived, 0);
    expect(await (db.select(db.stockBatches)..where((batch) => batch.productId.equals(10))).get(), hasLength(1));
    expect(await (db.select(db.stockBatches)..where((batch) => batch.productId.equals(11))).get(), isEmpty);

    final complete = await poRepo.receivePurchaseOrder(
      poId: po.id,
      batchNoPrefix: 'COMPLETE',
      expiryDate: DateTime(2027, 1, 1),
    );
    expect(complete.status, 'received');
    final batches = await (db.select(db.stockBatches)..where((batch) => batch.productId.isIn([10, 11]))).get();
    expect(batches, hasLength(3));
  });
}
