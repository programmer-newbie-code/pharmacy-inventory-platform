import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/purchase_order_repository.dart';
import 'package:pharmacy_inventory_platform/data/purchase_receiving_repository.dart';
import 'package:pharmacy_inventory_platform/data/supplier_repository.dart';

void main() {
  late AppDatabase db;
  late SupplierRepository supplierRepo;
  late PurchaseOrderRepository poRepo;
  late PurchaseReceivingRepository receivingRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    supplierRepo = SupplierRepository(db);
    poRepo = PurchaseOrderRepository(db);
    receivingRepo = PurchaseReceivingRepository(db);

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
  });

  tearDown(() async {
    await db.close();
  });

  test('processReceiving creates receiving items, stock batch, and updates PO',
      () async {
    final supplier = await supplierRepo.createSupplier(
      name: 'PT Kimia Farma',
      paymentTerms: 'Net 30',
    );

    final po = await poRepo.createPurchaseOrder(
      supplierId: supplier.id,
      createdBy: 'admin',
      items: [
        POItemInput(productId: 10, qtyOrdered: 500, unitCost: 200),
      ],
    );

    final expiry = DateTime.now().add(const Duration(days: 365));
    await receivingRepo.processReceiving(
      purchaseOrderId: po.id,
      receivedByUserId: 1,
      items: [
        ReceivingItemInput(
          productId: 10,
          qtyOrdered: 500,
          qtyReceived: 500,
          batchNo: 'BATCH-KF-001',
          expiryDate: expiry,
          costPricePerBaseUnit: 200,
        ),
      ],
    );

    // Verify receiving history
    final history = await receivingRepo.getReceivingHistory(po.id);
    expect(history, hasLength(1));
    expect(history.first.qtyReceived, equals(500));
    expect(history.first.batchNo, equals('BATCH-KF-001'));
    expect(history.first.discrepancyReason, isNull);

    // Verify stock batch auto-created
    final batches = await (db.select(db.stockBatches)
          ..where((b) => b.productId.equals(10)))
        .get();
    expect(batches, hasLength(1));
    expect(batches.first.batchNo, equals('BATCH-KF-001'));
    expect(batches.first.qtyRemaining, equals(500));
    expect(batches.first.supplier, equals('PT Kimia Farma'));

    // Verify PO status updated to received
    final updatedPo = await (db.select(db.purchaseOrders)
          ..where((p) => p.id.equals(po.id)))
        .getSingle();
    expect(updatedPo.status, equals('received'));
  });

  test('processReceiving flags discrepancy when received != ordered', () async {
    final supplier = await supplierRepo.createSupplier(name: 'PT Sanbe');

    final po = await poRepo.createPurchaseOrder(
      supplierId: supplier.id,
      createdBy: 'admin',
      items: [
        POItemInput(productId: 10, qtyOrdered: 500, unitCost: 200),
      ],
    );

    final expiry = DateTime.now().add(const Duration(days: 365));
    await receivingRepo.processReceiving(
      purchaseOrderId: po.id,
      receivedByUserId: 1,
      items: [
        ReceivingItemInput(
          productId: 10,
          qtyOrdered: 500,
          qtyReceived: 450,
          batchNo: 'BATCH-SANBE-001',
          expiryDate: expiry,
          costPricePerBaseUnit: 200,
          discrepancyReason: 'Damaged packaging during transit',
        ),
      ],
    );

    // Verify discrepancy recorded
    final discrepancies = await receivingRepo.getDiscrepancies(po.id);
    expect(discrepancies, hasLength(1));
    expect(discrepancies.first.qtyReceived, equals(450));
    expect(discrepancies.first.discrepancyReason,
        equals('Damaged packaging during transit'));

    // Verify PO status stays 'sent' since not fully received
    final updatedPo = await (db.select(db.purchaseOrders)
          ..where((p) => p.id.equals(po.id)))
        .getSingle();
    expect(updatedPo.status, equals('sent'));
  });

  test('supplier CRUD and filtering work correctly', () async {
    final s1 = await supplierRepo.createSupplier(
      name: 'PT Kalbe',
      contactPerson: 'Budi',
      phone: '0811111111',
      paymentTerms: 'Net 30',
      leadTimeDays: 5,
    );

    expect(s1.name, equals('PT Kalbe'));
    expect(s1.paymentTerms, equals('Net 30'));
    expect(s1.leadTimeDays, equals(5));
    expect(s1.isActive, isTrue);

    // Update supplier
    final updated = await supplierRepo.updateSupplier(
      id: s1.id,
      name: 'PT Kalbe Farma Tbk',
      contactPerson: 'Budi Santoso',
      paymentTerms: 'Net 45',
    );
    expect(updated.name, equals('PT Kalbe Farma Tbk'));
    expect(updated.paymentTerms, equals('Net 45'));

    // Deactivate supplier
    await supplierRepo.deactivateSupplier(s1.id);
    final activeList = await supplierRepo.listActiveSuppliers();
    expect(activeList, isEmpty);

    final allList = await supplierRepo.listSuppliers();
    expect(allList, hasLength(1));
    expect(allList.first.isActive, isFalse);

    // Reactivate
    await supplierRepo.activateSupplier(s1.id);
    final reactivatedList = await supplierRepo.listActiveSuppliers();
    expect(reactivatedList, hasLength(1));
  });
}
