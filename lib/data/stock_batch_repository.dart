import 'dart:convert';

import 'package:drift/drift.dart';

import 'audit_logger.dart';
import 'database.dart';

class StockBatchRepository {
  StockBatchRepository(this._db, {AuditLogger? auditLogger})
      : _auditLogger = auditLogger;

  final AppDatabase _db;
  final AuditLogger? _auditLogger;

  /// Creates a stock batch entry. Quantities MUST be in base units.
  Future<int> createStockBatch({
    required int productId,
    required String batchNo,
    required DateTime receivedDate,
    required DateTime expiryDate,
    required int qtyReceivedBaseUnit,
    required double costPricePerBaseUnit,
    required String supplier,
    required String createdBy,
    int? userIdForAudit,
  }) async {
    final id = await _db.into(_db.stockBatches).insert(
          StockBatchesCompanion.insert(
            productId: productId,
            batchNo: batchNo,
            receivedDate: receivedDate,
            expiryDate: expiryDate,
            qtyReceived: qtyReceivedBaseUnit,
            qtyRemaining: qtyReceivedBaseUnit,
            costPricePerBaseUnit: costPricePerBaseUnit,
            supplier: supplier,
            createdBy: createdBy,
          ),
        );

    if (_auditLogger != null && userIdForAudit != null) {
      await _auditLogger.log(
        tableName: 'stock_batches',
        recordId: id,
        action: 'create',
        newValue: jsonEncode({
          'batchNo': batchNo,
          'productId': productId,
          'qtyReceived': qtyReceivedBaseUnit,
          'expiryDate': expiryDate.toIso8601String(),
        }),
        userId: userIdForAudit,
      );
    }

    return id;
  }

  /// Lists batches for a specific product ordered by expiry date (FEFO: First-Expired First-Out).
  Future<List<StockBatch>> listBatchesForProduct(
    int productId, {
    bool availableOnly = false,
  }) async {
    final query = _db.select(_db.stockBatches)
      ..where((tbl) => tbl.productId.equals(productId));

    if (availableOnly) {
      query.where((tbl) => tbl.qtyRemaining.isBiggerThanValue(0));
    }

    query.orderBy([(tbl) => OrderingTerm.asc(tbl.expiryDate)]);
    return query.get();
  }

  /// Gets total remaining stock across all active batches for a product.
  Future<int> getTotalStockForProduct(int productId) async {
    final batches = await listBatchesForProduct(productId, availableOnly: true);
    return batches.fold<int>(0, (sum, batch) => sum + batch.qtyRemaining);
  }

  /// Lists batches expiring at or before [thresholdDate].
  Future<List<StockBatch>> listExpiringBatches(DateTime thresholdDate) async {
    final query = _db.select(_db.stockBatches)
      ..where(
        (tbl) =>
            tbl.qtyRemaining.isBiggerThanValue(0) &
            tbl.expiryDate.isSmallerOrEqualValue(thresholdDate),
      )
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.expiryDate)]);
    return query.get();
  }

  /// Deducts quantity from a specific batch. Returns updated batch or null if deduction fails.
  Future<bool> deductBatchStock(int batchId, int qtyToDeduct) async {
    final batches = await (_db.select(_db.stockBatches)
          ..where((tbl) => tbl.id.equals(batchId)))
        .get();

    if (batches.isEmpty) return false;
    final batch = batches.first;

    if (batch.qtyRemaining < qtyToDeduct) return false;

    final updated = batch.copyWith(
      qtyRemaining: batch.qtyRemaining - qtyToDeduct,
      updatedAt: Value(DateTime.now()),
    );

    return _db.update(_db.stockBatches).replace(updated);
  }

  /// Applies a traceable stock correction to one batch.
  ///
  /// Returns false without changing stock when the adjustment would make the
  /// batch quantity negative.
  Future<bool> adjustStock({
    required int batchId,
    required int delta,
    required String reason,
    required int userId,
  }) async {
    if (delta == 0) throw ArgumentError.value(delta, 'delta', 'must not be zero');
    if (reason.trim().isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'must not be empty');
    }

    return _db.transaction(() async {
      final batch = await (_db.select(_db.stockBatches)
            ..where((table) => table.id.equals(batchId)))
          .getSingleOrNull();
      if (batch == null || batch.qtyRemaining + delta < 0) return false;

      await _db.update(_db.stockBatches).replace(
            batch.copyWith(
              qtyRemaining: batch.qtyRemaining + delta,
              updatedAt: Value(DateTime.now()),
            ),
          );
      await _db.into(_db.stockAdjustments).insert(
            StockAdjustmentsCompanion.insert(
              productId: batch.productId,
              batchId: Value(batchId),
              quantityDelta: delta,
              reason: reason.trim(),
              createdBy: userId.toString(),
            ),
          );
      return true;
    });
  }
}
