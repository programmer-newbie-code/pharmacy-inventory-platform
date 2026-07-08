import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('inserts a product linked to a storage location and reads it back', () async {
    final locationId = await db.into(db.storageLocations).insert(
          StorageLocationsCompanion.insert(code: 'A1', name: 'Rak A1'),
        );

    final productId = await db.into(db.products).insert(
          ProductsCompanion.insert(
            barcode: '8991234567890',
            internalCode: 'PRD-001',
            name: 'Paracetamol 500mg',
            activeIngredient: 'Paracetamol',
            ingredientPct: 100.0,
            baseUnit: 'tablet',
            purchaseUnit: 'strip',
            unitsPerPurchaseUnit: 10,
            costPricePerBaseUnit: 200.0,
            marginPct: 0.3,
            reorderThreshold: 20,
            category: 'Analgesic',
            createdBy: 'seed-script',
            storageLocationId: Value(locationId),
          ),
        );

    final product = await (db.select(db.products)
          ..where((tbl) => tbl.id.equals(productId)))
        .getSingle();

    expect(product.name, 'Paracetamol 500mg');
    expect(product.storageLocationId, locationId);
    expect(product.isControlled, false);
  });

  test('stock batch tracks remaining quantity independently per delivery', () async {
    final productId = await db.into(db.products).insert(
          ProductsCompanion.insert(
            barcode: '8991234567891',
            internalCode: 'PRD-002',
            name: 'Amoxicillin 500mg',
            activeIngredient: 'Amoxicillin',
            ingredientPct: 100.0,
            baseUnit: 'tablet',
            purchaseUnit: 'strip',
            unitsPerPurchaseUnit: 10,
            costPricePerBaseUnit: 500.0,
            marginPct: 0.25,
            reorderThreshold: 30,
            category: 'Antibiotic',
            createdBy: 'seed-script',
          ),
        );

    final earlyBatchId = await db.into(db.stockBatches).insert(
          StockBatchesCompanion.insert(
            productId: productId,
            batchNo: 'B-001',
            receivedDate: DateTime(2026, 7, 1),
            expiryDate: DateTime(2026, 8, 1),
            qtyReceived: 100,
            qtyRemaining: 100,
            costPricePerBaseUnit: 500.0,
            supplier: 'PBF Sehat',
            createdBy: 'seed-script',
          ),
        );

    final laterBatchId = await db.into(db.stockBatches).insert(
          StockBatchesCompanion.insert(
            productId: productId,
            batchNo: 'B-002',
            receivedDate: DateTime(2026, 7, 8),
            expiryDate: DateTime(2027, 1, 1),
            qtyReceived: 100,
            qtyRemaining: 100,
            costPricePerBaseUnit: 510.0,
            supplier: 'PBF Sehat',
            createdBy: 'seed-script',
          ),
        );

    final batches = await (db.select(db.stockBatches)
          ..where((tbl) => tbl.productId.equals(productId)))
        .get();

    expect(batches, hasLength(2));
    expect(
      batches.map((b) => b.id),
      containsAll([earlyBatchId, laterBatchId]),
    );
    final earlyBatch = batches.firstWhere((b) => b.id == earlyBatchId);
    final laterBatch = batches.firstWhere((b) => b.id == laterBatchId);
    expect(earlyBatch.expiryDate, isNot(laterBatch.expiryDate));
  });
}
