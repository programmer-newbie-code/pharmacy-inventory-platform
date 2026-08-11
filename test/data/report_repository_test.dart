import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/audit_logger.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/cashier_shift_repository.dart';
import 'package:pharmacy_inventory_platform/data/product_repository.dart';
import 'package:pharmacy_inventory_platform/data/report_repository.dart';
import 'package:pharmacy_inventory_platform/data/sale_repository.dart';
import 'package:pharmacy_inventory_platform/data/stock_batch_repository.dart';
import 'package:pharmacy_inventory_platform/data/return_repository.dart';

void main() {
  late AppDatabase db;
  late ProductRepository productRepo;
  late StockBatchRepository batchRepo;
  late SaleRepository saleRepo;
  late ReportRepository reportRepo;
  late ReturnRepository returnRepo;
  late CashierShiftRepository shiftRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    productRepo = ProductRepository(db);
    batchRepo = StockBatchRepository(db);
    saleRepo = SaleRepository(db);
    reportRepo = ReportRepository(db);
    returnRepo = ReturnRepository(db);
    shiftRepo = CashierShiftRepository(db);

    await db.into(db.users).insert(
          UsersCompanion.insert(
            id: const Value(1),
            username: 'cashier',
            passwordHash: 'hash',
            role: 'kasir',
          ),
        );
    await shiftRepo.openShift(cashierId: 1, openingBalance: 0);
  });

  tearDown(() async {
    await db.close();
  });

  test('calculates sales summary revenue, COGS, and gross profit', () async {
    final prodId = await productRepo.createProduct(
      barcode: '8999999000111',
      internalCode: 'RPT-1',
      name: 'Report Test Medicine',
      activeIngredient: 'TestIng',
      ingredientPct: 100.0,
      baseUnit: 'tablet',
      purchaseUnit: 'box',
      unitsPerPurchaseUnit: 10,
      costPricePerBaseUnit: 100.0,
      marginPct: 50.0,
      reorderThreshold: 10,
      category: 'General',
      createdBy: 'admin',
    );

    final product = (await productRepo.getProductById(prodId))!;

    await batchRepo.createStockBatch(
      productId: prodId,
      batchNo: 'B-RPT-01',
      receivedDate: DateTime.now(),
      expiryDate: DateTime.now().add(const Duration(days: 180)),
      qtyReceivedBaseUnit: 50,
      costPricePerBaseUnit: 100.0,
      supplier: 'Kimia Farma',
      createdBy: 'admin',
    );

    await saleRepo.createSaleTransaction(
      cashierId: 1,
      items: [
        CartItemInput(product: product, qtyBaseUnit: 10, unitPrice: 150.0),
      ],
      paymentMethod: 'Cash',
    );

    final now = DateTime.now();
    final summary = await reportRepo.getSalesSummary(
      startDate: now.subtract(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 1)),
    );

    expect(summary.totalTransactions, equals(1));
    expect(summary.totalRevenue, equals(1500.0));
    expect(summary.totalCostOfGoods, equals(1000.0));
    expect(summary.grossProfit, equals(500.0));
    expect(summary.totalRefunds, equals(0.0));
    expect(summary.netRevenue, equals(1500.0));
  });

  test('includes refunds in sales summary', () async {
    final prodId = await productRepo.createProduct(
      barcode: '8999999000222',
      internalCode: 'RPT-2',
      name: 'Refundable Medicine',
      activeIngredient: 'TestIng',
      ingredientPct: 100.0,
      baseUnit: 'tablet',
      purchaseUnit: 'box',
      unitsPerPurchaseUnit: 10,
      costPricePerBaseUnit: 100.0,
      marginPct: 50.0,
      reorderThreshold: 10,
      category: 'General',
      createdBy: 'admin',
    );
    final product = (await productRepo.getProductById(prodId))!;

    await batchRepo.createStockBatch(
      productId: prodId,
      batchNo: 'B-RPT-02',
      receivedDate: DateTime.now(),
      expiryDate: DateTime.now().add(const Duration(days: 180)),
      qtyReceivedBaseUnit: 50,
      costPricePerBaseUnit: 100.0,
      supplier: 'Kimia Farma',
      createdBy: 'admin',
    );

    final txn = await saleRepo.createSaleTransaction(
      cashierId: 1,
      items: [
        CartItemInput(product: product, qtyBaseUnit: 10, unitPrice: 200.0),
      ],
      paymentMethod: 'Cash',
    );

    // Get the sale items for the return
    final saleItems = await (db.select(db.saleItems)
          ..where((t) => t.transactionId.equals(txn.id)))
        .get();

    await returnRepo.processReturn(
      originalTxnId: txn.id,
      processedBy: 1,
      reason: 'defective',
      refundMethod: 'Cash',
      returnItems: [
        ReturnItemInput(
          saleItem: saleItems.first,
          qtyReturned: 5,
        ),
      ],
    );

    final now = DateTime.now();
    final summary = await reportRepo.getSalesSummary(
      startDate: now.subtract(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 1)),
    );

    expect(summary.totalTransactions, equals(1));
    expect(summary.totalRevenue, equals(2000.0));
    expect(summary.totalRefunds, equals(1000.0));
    expect(summary.netRevenue, equals(1000.0));
  });

  test('ranks best-selling medicines by net quantity and revenue', () async {
    Future<Product> createProduct(String suffix, String name) async {
      final productId = await productRepo.createProduct(
        barcode: '8999999000$suffix',
        internalCode: 'BEST-$suffix',
        name: name,
        activeIngredient: name,
        ingredientPct: 100,
        baseUnit: 'tablet',
        purchaseUnit: 'box',
        unitsPerPurchaseUnit: 10,
        costPricePerBaseUnit: 100,
        marginPct: 50,
        reorderThreshold: 10,
        category: 'General',
        createdBy: 'admin',
      );
      await batchRepo.createStockBatch(
        productId: productId,
        batchNo: 'BEST-$suffix',
        receivedDate: DateTime(2026, 8, 1),
        expiryDate: DateTime(2027, 8, 1),
        qtyReceivedBaseUnit: 100,
        costPricePerBaseUnit: 100,
        supplier: 'Supplier',
        createdBy: 'admin',
      );
      return (await productRepo.getProductById(productId))!;
    }

    final quantityLeader = await createProduct('41', 'Quantity Leader');
    final revenueLeader = await createProduct('42', 'Revenue Leader');
    final transactionDate = DateTime(2026, 8, 5, 10);

    final quantitySale = await saleRepo.createSaleTransaction(
      cashierId: 1,
      items: [
        CartItemInput(product: quantityLeader, qtyBaseUnit: 10, unitPrice: 100),
      ],
      paymentMethod: 'Cash',
    );
    final revenueSale = await saleRepo.createSaleTransaction(
      cashierId: 1,
      items: [
        CartItemInput(product: revenueLeader, qtyBaseUnit: 5, unitPrice: 500),
      ],
      paymentMethod: 'Cash',
    );
    await (db.update(db.saleTransactions)
          ..where((txn) => txn.id.equals(quantitySale.id)))
        .write(SaleTransactionsCompanion(createdAt: Value(transactionDate)));
    await (db.update(db.saleTransactions)
          ..where((txn) => txn.id.equals(revenueSale.id)))
        .write(SaleTransactionsCompanion(createdAt: Value(transactionDate)));

    final quantitySaleItem = await (db.select(db.saleItems)
          ..where((item) => item.transactionId.equals(quantitySale.id)))
        .getSingle();
    final returned = await returnRepo.processReturn(
      originalTxnId: quantitySale.id,
      processedBy: 1,
      reason: 'defective',
      refundMethod: 'Cash',
      returnItems: [
        ReturnItemInput(saleItem: quantitySaleItem, qtyReturned: 2),
      ],
    );
    await (db.update(db.returnTransactions)
          ..where((txn) => txn.id.equals(returned.id)))
        .write(ReturnTransactionsCompanion(createdAt: Value(transactionDate)));

    final byQuantity = await reportRepo.getBestSellingMedicines(
      BestSellingMedicinesFilter(
        startDate: DateTime(2026, 8, 5),
        endDate: DateTime(2026, 8, 5, 23, 59, 59),
        rankMode: BestSellingRankMode.netQuantity,
      ),
    );
    final byRevenue = await reportRepo.getBestSellingMedicines(
      BestSellingMedicinesFilter(
        startDate: DateTime(2026, 8, 5),
        endDate: DateTime(2026, 8, 5, 23, 59, 59),
        rankMode: BestSellingRankMode.netRevenue,
      ),
    );

    expect(byQuantity.map((row) => row.productName), [
      'Quantity Leader',
      'Revenue Leader',
    ]);
    expect(byQuantity.first.grossQuantity, 10);
    expect(byQuantity.first.returnedQuantity, 2);
    expect(byQuantity.first.netQuantity, 8);
    expect(byQuantity.first.grossRevenue, 1000);
    expect(byQuantity.first.refundedRevenue, 200);
    expect(byQuantity.first.netRevenue, 800);
    expect(byRevenue.first.productName, 'Revenue Leader');
    expect(byRevenue.first.netRevenue, 2500);

    final analytics = await reportRepo.getSalesAnalytics(
      BestSellingMedicinesFilter(
        startDate: DateTime(2026, 8, 5),
        endDate: DateTime(2026, 8, 5, 23, 59, 59),
        rankMode: BestSellingRankMode.netQuantity,
      ),
    );
    expect(analytics.paymentCounts['Cash'], 2);
    expect(analytics.categoryRevenue['General'], 3300);
    expect(analytics.bestSellingMedicines.first.productName, 'Quantity Leader');
  });

  test(
      'returns no best-selling medicines when the selected period has no sales',
      () async {
    final rows = await reportRepo.getBestSellingMedicines(
      BestSellingMedicinesFilter(
        startDate: DateTime(2020, 1, 1),
        endDate: DateTime(2020, 1, 1, 23, 59, 59),
        rankMode: BestSellingRankMode.netQuantity,
      ),
    );

    expect(rows, isEmpty);
  });

  test('returns shift discrepancies for date range', () async {
    final prodId = await productRepo.createProduct(
      barcode: '8999999000333',
      internalCode: 'RPT-3',
      name: 'Disc Test',
      activeIngredient: 'TestIng',
      ingredientPct: 100.0,
      baseUnit: 'tablet',
      purchaseUnit: 'box',
      unitsPerPurchaseUnit: 10,
      costPricePerBaseUnit: 100.0,
      marginPct: 50.0,
      reorderThreshold: 10,
      category: 'General',
      createdBy: 'admin',
    );
    final product = (await productRepo.getProductById(prodId))!;
    await batchRepo.createStockBatch(
      productId: prodId,
      batchNo: 'B-RPT-03',
      receivedDate: DateTime.now(),
      expiryDate: DateTime.now().add(const Duration(days: 180)),
      qtyReceivedBaseUnit: 50,
      costPricePerBaseUnit: 100.0,
      supplier: 'Kimia Farma',
      createdBy: 'admin',
    );
    await saleRepo.createSaleTransaction(
      cashierId: 1,
      items: [
        CartItemInput(product: product, qtyBaseUnit: 5, unitPrice: 1000.0)
      ],
      paymentMethod: 'Cash',
    );

    // actualCash = 4000 but expected = 0 + 5000 = 5000, so discrepancy = -1000
    await shiftRepo.closeShift(
      shiftId: 1,
      actualCash: 4000,
      discrepancyReason: 'cashier miscount',
    );

    final now = DateTime.now();
    final discrepancies = await reportRepo.getShiftDiscrepancies(
      startDate: now.subtract(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 1)),
    );

    expect(discrepancies.length, equals(1));
    expect(discrepancies.single.discrepancyReason, equals('cashier miscount'));
  });

  test('logExport writes to audit trail', () async {
    final auditRepo = ReportRepository(db, auditLogger: AuditLogger(db));

    await auditRepo.logExport(
      userId: 1,
      exportType: 'excel_sales',
      details: 'Period: 2026-07-01 to 2026-07-31',
    );

    final logs = await db.select(db.auditLogs).get();
    expect(logs.length, equals(1));
    expect(logs.single.action, equals('export_excel_sales'));
  });
}
