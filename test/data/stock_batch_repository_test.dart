import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/audit_logger.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/product_repository.dart';
import 'package:pharmacy_inventory_platform/data/stock_batch_repository.dart';

void main() {
  late AppDatabase db;
  late AuditLogger auditLogger;
  late ProductRepository productRepo;
  late StockBatchRepository batchRepo;
  late int productId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    auditLogger = AuditLogger(db);
    productRepo = ProductRepository(db, auditLogger: auditLogger);
    batchRepo = StockBatchRepository(db, auditLogger: auditLogger);

    productId = await productRepo.createProduct(
      barcode: '8999999999999',
      internalCode: 'AMX-500',
      name: 'Amoxicillin 500mg',
      activeIngredient: 'Amoxicillin',
      ingredientPct: 100.0,
      baseUnit: 'kaplet',
      purchaseUnit: 'strip',
      unitsPerPurchaseUnit: 10,
      costPricePerBaseUnit: 500.0,
      marginPct: 15.0,
      reorderThreshold: 30,
      isControlled: true,
      category: 'Antibiotik',
      createdBy: 'admin',
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('creates stock batch and lists in FEFO order', () async {
    final batchLater = await batchRepo.createStockBatch(
      productId: productId,
      batchNo: 'BATCH-2026-B',
      receivedDate: DateTime(2026, 7, 1),
      expiryDate: DateTime(2027, 12, 31),
      qtyReceivedBaseUnit: 100,
      costPricePerBaseUnit: 500.0,
      supplier: 'PT Kimia Farma',
      createdBy: 'admin',
      userIdForAudit: 1,
    );

    final batchSooner = await batchRepo.createStockBatch(
      productId: productId,
      batchNo: 'BATCH-2026-A',
      receivedDate: DateTime(2026, 7, 1),
      expiryDate: DateTime(2026, 10, 1),
      qtyReceivedBaseUnit: 50,
      costPricePerBaseUnit: 500.0,
      supplier: 'PT Kimia Farma',
      createdBy: 'admin',
      userIdForAudit: 1,
    );

    expect(batchLater, isPositive);
    expect(batchSooner, isPositive);

    final batches = await batchRepo.listBatchesForProduct(productId);
    expect(batches, hasLength(2));
    expect(batches.first.batchNo, equals('BATCH-2026-A'));
    expect(batches.last.batchNo, equals('BATCH-2026-B'));

    final totalStock = await batchRepo.getTotalStockForProduct(productId);
    expect(totalStock, equals(150));

    final expiring = await batchRepo.listExpiringBatches(DateTime(2026, 11, 1));
    expect(expiring, hasLength(1));
    expect(expiring.first.batchNo, equals('BATCH-2026-A'));
  });

  test('deducts batch stock correctly and handles invalid deductions', () async {
    final batchId = await batchRepo.createStockBatch(
      productId: productId,
      batchNo: 'BATCH-DEDUCT',
      receivedDate: DateTime(2026, 7, 1),
      expiryDate: DateTime(2027, 1, 1),
      qtyReceivedBaseUnit: 50,
      costPricePerBaseUnit: 500.0,
      supplier: 'PT Pharos',
      createdBy: 'admin',
    );

    final deducted = await batchRepo.deductBatchStock(batchId, 20);
    expect(deducted, isTrue);

    final batches = await batchRepo.listBatchesForProduct(productId);
    expect(batches.first.qtyRemaining, equals(30));

    // Attempting to deduct more stock than remaining must return false
    final overDeduct = await batchRepo.deductBatchStock(batchId, 100);
    expect(overDeduct, isFalse);

    // Non-existent batch ID must return false
    final invalidBatch = await batchRepo.deductBatchStock(99999, 10);
    expect(invalidBatch, isFalse);
  });

  test('adjustStock records the correction and rejects negative stock', () async {
    final batchId = await batchRepo.createStockBatch(
      productId: productId,
      batchNo: 'BATCH-ADJUST',
      receivedDate: DateTime(2026, 7, 1),
      expiryDate: DateTime(2027, 1, 1),
      qtyReceivedBaseUnit: 10,
      costPricePerBaseUnit: 500,
      supplier: 'PT Pharos',
      createdBy: 'admin',
    );

    expect(
      await batchRepo.adjustStock(
        batchId: batchId,
        delta: -4,
        reason: 'Damaged packaging',
        userId: 1,
      ),
      isTrue,
    );
    expect(await batchRepo.getTotalStockForProduct(productId), 6);

    final adjustments = await db.select(db.stockAdjustments).get();
    expect(adjustments, hasLength(1));
    expect(adjustments.single.quantityDelta, -4);
    expect(adjustments.single.reason, 'Damaged packaging');
    expect(adjustments.single.createdBy, '1');

    expect(
      await batchRepo.adjustStock(
        batchId: batchId,
        delta: -7,
        reason: 'Cannot go below zero',
        userId: 1,
      ),
      isFalse,
    );
    expect(await batchRepo.getTotalStockForProduct(productId), 6);
    expect(await db.select(db.stockAdjustments).get(), hasLength(1));
  });
}
