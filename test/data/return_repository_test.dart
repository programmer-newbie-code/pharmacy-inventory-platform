import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/return_repository.dart';
import 'package:pharmacy_inventory_platform/data/sale_repository.dart';

void main() {
  late AppDatabase db;
  late ReturnRepository returnRepo;
  late SaleRepository saleRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    returnRepo = ReturnRepository(db);
    saleRepo = SaleRepository(db);

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
  });

  tearDown(() async {
    await db.close();
  });

  test('processReturn creates return transaction, calculates refund, and restocks batch', () async {
    final prod = await (db.select(db.products)..where((p) => p.id.equals(10))).getSingle();

    // 1. Create sale of 10 tablets @ Rp 1,500
    final txn = await saleRepo.createSaleTransaction(
      cashierId: 1,
      items: [
        CartItemInput(product: prod, qtyBaseUnit: 10, unitPrice: 1500),
      ],
      paymentMethod: 'Cash',
    );

    final saleItems = await saleRepo.getSaleItemsForTransaction(txn.id);
    expect(saleItems, hasLength(1));

    // Initial batch remaining = 100 - 10 = 90
    var batch = await (db.select(db.stockBatches)..where((b) => b.id.equals(101))).getSingle();
    expect(batch.qtyRemaining, equals(90));

    // 2. Return 4 tablets with restocking
    final ret = await returnRepo.processReturn(
      originalTxnId: txn.id,
      processedBy: 1,
      reason: 'wrong_product',
      refundMethod: 'Cash',
      returnItems: [
        ReturnItemInput(saleItem: saleItems.first, qtyReturned: 4, restock: true),
      ],
    );

    expect(ret.refundAmount, equals(6000)); // 4 * 1500
    expect(ret.reason, equals('wrong_product'));

    // Batch remaining after restock = 90 + 4 = 94
    batch = await (db.select(db.stockBatches)..where((b) => b.id.equals(101))).getSingle();
    expect(batch.qtyRemaining, equals(94));

    final returnsList = await returnRepo.getReturnsForTransaction(txn.id);
    expect(returnsList, hasLength(1));

    final allReturns = await returnRepo.listReturns();
    expect(allReturns, isNotEmpty);
  });
}
