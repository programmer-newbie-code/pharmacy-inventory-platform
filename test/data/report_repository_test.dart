import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/cashier_shift_repository.dart';
import 'package:pharmacy_inventory_platform/data/product_repository.dart';
import 'package:pharmacy_inventory_platform/data/report_repository.dart';
import 'package:pharmacy_inventory_platform/data/sale_repository.dart';
import 'package:pharmacy_inventory_platform/data/stock_batch_repository.dart';

void main() {
  late AppDatabase db;
  late ProductRepository productRepo;
  late StockBatchRepository batchRepo;
  late SaleRepository saleRepo;
  late ReportRepository reportRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    productRepo = ProductRepository(db);
    batchRepo = StockBatchRepository(db);
    saleRepo = SaleRepository(db);
    reportRepo = ReportRepository(db);
    await CashierShiftRepository(db).openShift(cashierId: 1, openingBalance: 0);
  });

  tearDown(() async {
    await db.close();
  });

  test('calculates sales summary revenue, COGS, and gross profit correctly', () async {
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

    // Sell 10 tablets at Rp 150 each (Total revenue = 1500, COGS = 1000, Profit = 500)
    await saleRepo.createSaleTransaction(
      cashierId: 1,
      items: [
        CartItemInput(
          product: product,
          qtyBaseUnit: 10,
          unitPrice: 150.0,
        ),
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
  });
}
