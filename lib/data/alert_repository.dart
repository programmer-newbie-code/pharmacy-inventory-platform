import 'package:drift/drift.dart';

import 'database.dart';

class ExpiringBatchDetail {
  ExpiringBatchDetail({
    required this.batch,
    required this.product,
    required this.daysUntilExpiry,
  });

  final StockBatch batch;
  final Product product;
  final int daysUntilExpiry;
}

class LowStockProductDetail {
  LowStockProductDetail({
    required this.product,
    required this.currentTotalStock,
  });

  final Product product;
  final int currentTotalStock;
}

class AlertRepository {
  AlertRepository(this._db);

  final AppDatabase _db;

  /// Returns batches expiring within [daysThreshold] days (default: 90 days).
  Future<List<ExpiringBatchDetail>> listExpiringBatches({int daysThreshold = 90}) async {
    final now = DateTime.now();
    final thresholdDate = now.add(Duration(days: daysThreshold));

    final query = _db.select(_db.stockBatches).join([
      innerJoin(_db.products, _db.products.id.equalsExpr(_db.stockBatches.productId)),
    ])
      ..where(
        _db.stockBatches.qtyRemaining.isBiggerThanValue(0) &
            _db.stockBatches.expiryDate.isSmallerOrEqualValue(thresholdDate),
      )
      ..orderBy([OrderingTerm.asc(_db.stockBatches.expiryDate)]);

    final rows = await query.get();
    return rows.map((row) {
      final batch = row.readTable(_db.stockBatches);
      final product = row.readTable(_db.products);
      final daysLeft = batch.expiryDate.difference(now).inDays;
      return ExpiringBatchDetail(
        batch: batch,
        product: product,
        daysUntilExpiry: daysLeft,
      );
    }).toList();
  }

  /// Returns products where total remaining stock across active batches is at or below [reorderThreshold].
  Future<List<LowStockProductDetail>> listLowStockProducts() async {
    final products = await _db.select(_db.products).get();
    final lowStockList = <LowStockProductDetail>[];

    for (final prod in products) {
      final batches = await (_db.select(_db.stockBatches)
            ..where(
              (tbl) =>
                  tbl.productId.equals(prod.id) &
                  tbl.qtyRemaining.isBiggerThanValue(0),
            ))
          .get();

      final totalStock = batches.fold<int>(0, (sum, b) => sum + b.qtyRemaining);
      if (totalStock <= prod.reorderThreshold) {
        lowStockList.add(
          LowStockProductDetail(
            product: prod,
            currentTotalStock: totalStock,
          ),
        );
      }
    }

    return lowStockList;
  }
}
