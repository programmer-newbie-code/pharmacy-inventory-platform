import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/alert_repository.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/product_repository.dart';
import 'package:pharmacy_inventory_platform/data/stock_batch_repository.dart';

void main() {
  late AppDatabase db;
  late ProductRepository productRepo;
  late StockBatchRepository batchRepo;
  late AlertRepository alertRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    productRepo = ProductRepository(db);
    batchRepo = StockBatchRepository(db);
    alertRepo = AlertRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('lists expiring batches and low stock products correctly', () async {
    final prodId = await productRepo.createProduct(
      barcode: '8997777888999',
      internalCode: 'ALT-1',
      name: 'Alert Medicine 100mg',
      activeIngredient: 'Alertin',
      ingredientPct: 100.0,
      baseUnit: 'tablet',
      purchaseUnit: 'box',
      unitsPerPurchaseUnit: 10,
      costPricePerBaseUnit: 100.0,
      marginPct: 20.0,
      reorderThreshold: 50,
      category: 'General',
      createdBy: 'admin',
    );

    // Add batch expiring in 15 days, 10 units remaining (below reorderThreshold 50!)
    await batchRepo.createStockBatch(
      productId: prodId,
      batchNo: 'BATCH-EXP-SOON',
      receivedDate: DateTime.now(),
      expiryDate: DateTime.now().add(const Duration(days: 15)),
      qtyReceivedBaseUnit: 10,
      costPricePerBaseUnit: 100.0,
      supplier: 'Supplier A',
      createdBy: 'admin',
    );

    final expiring = await alertRepo.listExpiringBatches(daysThreshold: 90);
    expect(expiring, hasLength(1));
    expect(expiring.first.batch.batchNo, equals('BATCH-EXP-SOON'));
    expect(expiring.first.daysUntilExpiry, lessThanOrEqualTo(15));

    final lowStock = await alertRepo.listLowStockProducts();
    expect(lowStock, hasLength(1));
    expect(lowStock.first.product.name, equals('Alert Medicine 100mg'));
    expect(lowStock.first.currentTotalStock, equals(10));
  });
}
