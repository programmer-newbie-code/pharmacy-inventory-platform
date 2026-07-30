import 'dart:convert';
import 'package:drift/drift.dart';
import 'audit_logger.dart';
import 'database.dart';

class ReturnItemInput {
  ReturnItemInput({
    required this.saleItem,
    required this.qtyReturned,
    this.restock = true,
  });

  final SaleItem saleItem;
  final int qtyReturned;
  final bool restock;

  double get subtotal => qtyReturned * saleItem.unitPrice;
}

class ReturnRepository {
  ReturnRepository(this._db, {AuditLogger? auditLogger})
      : _auditLogger = auditLogger;

  final AppDatabase _db;
  final AuditLogger? _auditLogger;

  /// Processes a return transaction for a sale, restocking batches if specified.
  Future<ReturnTransaction> processReturn({
    required int originalTxnId,
    required int processedBy,
    required String reason,
    required String refundMethod,
    required List<ReturnItemInput> returnItems,
  }) async {
    if (returnItems.isEmpty) {
      throw ArgumentError('Return items cannot be empty.');
    }

    for (final item in returnItems) {
      if (item.qtyReturned <= 0 || item.qtyReturned > item.saleItem.qtySold) {
        throw ArgumentError('Invalid returned quantity for SaleItem #${item.saleItem.id}');
      }
    }

    final now = DateTime.now();
    final returnNo =
        'RET-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';

    double refundAmount = 0;
    for (final item in returnItems) {
      refundAmount += item.subtotal;
    }

    return _db.transaction(() async {
      final priorReturns = await (_db.select(_db.returnTransactions)
            ..where((txn) => txn.originalTxnId.equals(originalTxnId)))
          .get();
      final priorReturnIds = priorReturns.map((txn) => txn.id).toList();

      for (final item in returnItems) {
        final priorItems = priorReturnIds.isEmpty
            ? <ReturnItem>[]
            : await (_db.select(_db.returnItems)
                  ..where((returned) =>
                      returned.returnTxnId.isIn(priorReturnIds) &
                      returned.saleItemId.equals(item.saleItem.id)))
                .get();
        final alreadyReturned = priorItems.fold<int>(
          0,
          (total, returned) => total + returned.qtyReturned,
        );
        if (alreadyReturned + item.qtyReturned > item.saleItem.qtySold) {
          throw ArgumentError(
            'Return quantity exceeds the quantity originally sold for SaleItem #${item.saleItem.id}.',
          );
        }
      }

      // 1. Insert ReturnTransaction master
      final returnId = await _db.into(_db.returnTransactions).insert(
            ReturnTransactionsCompanion.insert(
              returnNo: returnNo,
              originalTxnId: originalTxnId,
              processedBy: processedBy,
              reason: reason,
              refundAmount: refundAmount,
              refundMethod: refundMethod,
              createdAt: Value(now),
            ),
          );

      // 2. Process return items & restock stock batch
      for (final item in returnItems) {
        await _db.into(_db.returnItems).insert(
              ReturnItemsCompanion.insert(
                returnTxnId: returnId,
                saleItemId: item.saleItem.id,
                qtyReturned: item.qtyReturned,
                restocked: Value(item.restock),
              ),
            );

        if (item.restock) {
          final batch = await (_db.select(_db.stockBatches)
                ..where((tbl) => tbl.id.equals(item.saleItem.batchId)))
              .getSingle();

          final updatedBatch = batch.copyWith(
            qtyRemaining: batch.qtyRemaining + item.qtyReturned,
            updatedAt: Value(now),
          );
          await _db.update(_db.stockBatches).replace(updatedBatch);
        }
      }

      if (_auditLogger != null) {
        await _auditLogger.log(
          tableName: 'return_transactions',
          recordId: returnId,
          action: 'create',
          newValue: jsonEncode({
            'returnNo': returnNo,
            'originalTxnId': originalTxnId,
            'refundAmount': refundAmount,
            'itemCount': returnItems.length,
          }),
          userId: processedBy,
        );
      }

      return (_db.select(_db.returnTransactions)
            ..where((tbl) => tbl.id.equals(returnId)))
          .getSingle();
    });
  }

  /// Lists return transactions for a specific sale.
  Future<List<ReturnTransaction>> getReturnsForTransaction(int originalTxnId) {
    return (_db.select(_db.returnTransactions)
          ..where((tbl) => tbl.originalTxnId.equals(originalTxnId)))
        .get();
  }

  /// Lists all return transactions ordered by createdAt DESC.
  Future<List<ReturnTransaction>> listReturns() {
    return (_db.select(_db.returnTransactions)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
  }
}
