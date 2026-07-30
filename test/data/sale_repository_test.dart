import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/audit_logger.dart';
import 'package:pharmacy_inventory_platform/data/cashier_shift_repository.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/product_repository.dart';
import 'package:pharmacy_inventory_platform/data/sale_repository.dart';
import 'package:pharmacy_inventory_platform/data/stock_batch_repository.dart';

void main() {
  late AppDatabase db;
  late AuditLogger auditLogger;
  late ProductRepository productRepo;
  late StockBatchRepository batchRepo;
  late SaleRepository saleRepo;
  late CashierShiftRepository shiftRepo;
  late Product normalProduct;
  late Product controlledProduct;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    auditLogger = AuditLogger(db);
    productRepo = ProductRepository(db, auditLogger: auditLogger);
    batchRepo = StockBatchRepository(db, auditLogger: auditLogger);
    saleRepo = SaleRepository(db, auditLogger: auditLogger);
    shiftRepo = CashierShiftRepository(db);
    await shiftRepo.openShift(cashierId: 1, openingBalance: 0);

    final normalId = await productRepo.createProduct(
      barcode: '8991111111111',
      internalCode: 'PCT-500',
      name: 'Paracetamol 500mg',
      activeIngredient: 'Paracetamol',
      ingredientPct: 100.0,
      baseUnit: 'tablet',
      purchaseUnit: 'box',
      unitsPerPurchaseUnit: 100,
      costPricePerBaseUnit: 200.0,
      marginPct: 25.0,
      reorderThreshold: 50,
      isControlled: false,
      category: 'Analgesik',
      createdBy: 'admin',
    );
    normalProduct = (await productRepo.getProductById(normalId))!;

    final controlledId = await productRepo.createProduct(
      barcode: '8992222222222',
      internalCode: 'CDN-10',
      name: 'Codeine 10mg',
      activeIngredient: 'Codeine',
      ingredientPct: 100.0,
      baseUnit: 'tablet',
      purchaseUnit: 'strip',
      unitsPerPurchaseUnit: 10,
      costPricePerBaseUnit: 1000.0,
      marginPct: 30.0,
      reorderThreshold: 20,
      isControlled: true,
      category: 'Narkotika',
      createdBy: 'admin',
    );
    controlledProduct = (await productRepo.getProductById(controlledId))!;
  });

  tearDown(() async {
    await db.close();
  });

  test('executes FEFO stock allocation across multiple batches', () async {
    // Batch A: Expiring sooner (Oct 2026), 15 units remaining
    await batchRepo.createStockBatch(
      productId: normalProduct.id,
      batchNo: 'BATCH-SOONER',
      receivedDate: DateTime(2026, 7, 1),
      expiryDate: DateTime(2026, 10, 1),
      qtyReceivedBaseUnit: 15,
      costPricePerBaseUnit: 200.0,
      supplier: 'Kimia Farma',
      createdBy: 'admin',
    );

    // Batch B: Expiring later (Dec 2027), 50 units remaining
    await batchRepo.createStockBatch(
      productId: normalProduct.id,
      batchNo: 'BATCH-LATER',
      receivedDate: DateTime(2026, 7, 1),
      expiryDate: DateTime(2027, 12, 31),
      qtyReceivedBaseUnit: 50,
      costPricePerBaseUnit: 200.0,
      supplier: 'Kimia Farma',
      createdBy: 'admin',
    );

    // Sell 20 tablets at Rp 250 each
    final txn = await saleRepo.createSaleTransaction(
      cashierId: 1,
      items: [
        CartItemInput(
          product: normalProduct,
          qtyBaseUnit: 20,
          unitPrice: 250.0,
        ),
      ],
      paymentMethod: 'Cash',
    );

    expect(txn.totalAmount, equals(5000.0));

    final items = await saleRepo.getSaleItemsForTransaction(txn.id);
    expect(items, hasLength(2)); // FEFO split across 2 batches (15 from Batch A, 5 from Batch B)

    final batchesAfter = await batchRepo.listBatchesForProduct(normalProduct.id);
    expect(batchesAfter.first.qtyRemaining, equals(0)); // Batch A fully depleted
    expect(batchesAfter.last.qtyRemaining, equals(45)); // Batch B reduced by 5
  });

  test('throws ShiftRequiredException when checkout has no active shift', () async {
    final shift = await shiftRepo.getActiveShift(1);
    await shiftRepo.closeShift(shiftId: shift!.id, actualCash: 0);

    expect(
      () => saleRepo.createSaleTransaction(
        cashierId: 1,
        items: [CartItemInput(product: normalProduct, qtyBaseUnit: 1, unitPrice: 250)],
        paymentMethod: 'Cash',
      ),
      throwsA(isA<ShiftRequiredException>()),
    );
  });

  test('throws MinSellPriceException when selling below cost price', () async {
    await batchRepo.createStockBatch(
      productId: normalProduct.id,
      batchNo: 'BATCH-001',
      receivedDate: DateTime(2026, 7, 1),
      expiryDate: DateTime(2027, 1, 1),
      qtyReceivedBaseUnit: 10,
      costPricePerBaseUnit: 200.0,
      supplier: 'Kimia Farma',
      createdBy: 'admin',
    );

    expect(
      () => saleRepo.createSaleTransaction(
        cashierId: 1,
        items: [
          CartItemInput(
            product: normalProduct,
            qtyBaseUnit: 5,
            unitPrice: 150.0, // Below cost price 200.0!
          ),
        ],
        paymentMethod: 'Cash',
      ),
      throwsA(isA<MinSellPriceException>()),
    );
  });

  test('throws PrescriptionRequiredException for controlled drugs without prescription',
      () async {
    await batchRepo.createStockBatch(
      productId: controlledProduct.id,
      batchNo: 'BATCH-CTRL-01',
      receivedDate: DateTime(2026, 7, 1),
      expiryDate: DateTime(2027, 1, 1),
      qtyReceivedBaseUnit: 10,
      costPricePerBaseUnit: 1000.0,
      supplier: 'Kimia Farma',
      createdBy: 'admin',
    );

    expect(
      () => saleRepo.createSaleTransaction(
        cashierId: 1,
        items: [
          CartItemInput(
            product: controlledProduct,
            qtyBaseUnit: 2,
            unitPrice: 1300.0,
          ),
        ],
        paymentMethod: 'Cash',
        hasPrescription: false, // Missing prescription!
      ),
      throwsA(isA<PrescriptionRequiredException>()),
    );
  });

  test('throws InsufficientStockException when stock is not enough', () async {
    expect(
      () => saleRepo.createSaleTransaction(
        cashierId: 1,
        items: [
          CartItemInput(
            product: normalProduct,
            qtyBaseUnit: 100,
            unitPrice: 250.0,
          ),
        ],
        paymentMethod: 'Cash',
      ),
      throwsA(isA<InsufficientStockException>()),
    );
  });
}
