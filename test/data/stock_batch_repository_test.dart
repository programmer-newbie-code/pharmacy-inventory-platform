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
    );

    expect(batchLater, isPositive);
    expect(batchSooner, isPositive);

    final batches = await batchRepo.listBatchesForProduct(productId);
    expect(batches, hasLength(2));
    // FEFO order check: batchSooner (exp: Oct 2026) must come before batchLater (exp: Dec 2027)
    expect(batches.first.batchNo, equals('BATCH-2026-A'));
    expect(batches.last.batchNo, equals('BATCH-2026-B'));

    final totalStock = await batchRepo.getTotalStockForProduct(productId);
    expect(totalStock, equals(150));
  });

  test('deducts batch stock correctly', () async {
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
  });
}
