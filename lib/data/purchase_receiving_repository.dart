import 'dart:convert';
import 'package:drift/drift.dart';
import 'audit_logger.dart';
import 'database.dart';

/// Input for a single line item in a receiving session.
class ReceivingItemInput {
  ReceivingItemInput({
    required this.productId,
    required this.qtyOrdered,
    required this.qtyReceived,
    required this.batchNo,
    required this.expiryDate,
    required this.costPricePerBaseUnit,
    this.discrepancyReason,
  });

  final int productId;
  final int qtyOrdered;
  final int qtyReceived;
  final String batchNo;
  final DateTime expiryDate;
  final double costPricePerBaseUnit;
  final String? discrepancyReason;

  bool get hasDiscrepancy => qtyReceived != qtyOrdered;
}

class PurchaseReceivingRepository {
  PurchaseReceivingRepository(this._db, {AuditLogger? auditLogger})
      : _auditLogger = auditLogger;

  final AppDatabase _db;
  final AuditLogger? _auditLogger;

  /// Processes a receiving session for a purchase order.
  ///
  /// In a single transaction:
  /// 1. Inserts [PurchaseReceivingItem] records for each line
  /// 2. Creates [StockBatch] entries for received quantities
  /// 3. Updates the PO line items' qtyReceived
  /// 4. Updates the PO status (received or partial)
  Future<void> processReceiving({
    required int purchaseOrderId,
    required List<ReceivingItemInput> items,
    required int receivedByUserId,
    String? deviceId,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('Receiving items cannot be empty.');
    }

    final now = DateTime.now();

    await _db.transaction(() async {
      final po = await (_db.select(_db.purchaseOrders)
            ..where((tbl) => tbl.id.equals(purchaseOrderId)))
          .getSingle();

      final supplier = await (_db.select(_db.suppliers)
            ..where((tbl) => tbl.id.equals(po.supplierId)))
          .getSingle();

      for (final item in items) {
        if (item.qtyReceived < 0) {
          throw ArgumentError('Received quantity cannot be negative.');
        }

        // Insert receiving record
        await _db.into(_db.purchaseReceivingItems).insert(
              PurchaseReceivingItemsCompanion.insert(
                purchaseOrderId: purchaseOrderId,
                productId: item.productId,
                qtyOrdered: item.qtyOrdered,
                qtyReceived: item.qtyReceived,
                batchNo: item.batchNo,
                expiryDate: item.expiryDate,
                costPricePerBaseUnit: item.costPricePerBaseUnit,
                discrepancyReason: Value(item.discrepancyReason),
                receivedBy: Value(receivedByUserId),
                receivedAt: now,
                createdAt: Value(now),
                deviceId: Value(deviceId),
              ),
            );

        // Create stock batch only if quantity received > 0
        if (item.qtyReceived > 0) {
          await _db.into(_db.stockBatches).insert(
                StockBatchesCompanion.insert(
                  productId: item.productId,
                  batchNo: item.batchNo,
                  receivedDate: now,
                  expiryDate: item.expiryDate,
                  qtyReceived: item.qtyReceived,
                  qtyRemaining: item.qtyReceived,
                  costPricePerBaseUnit: item.costPricePerBaseUnit,
                  supplier: supplier.name,
                  createdBy: po.createdBy,
                  createdAt: Value(now),
                ),
              );
        }

        // Update PO line item qtyReceived
        final poItems = await (_db.select(_db.purchaseOrderItems)
              ..where((tbl) =>
                  tbl.purchaseOrderId.equals(purchaseOrderId) &
                  tbl.productId.equals(item.productId)))
            .get();

        for (final poItem in poItems) {
          final updatedItem = poItem.copyWith(
            qtyReceived: poItem.qtyReceived + item.qtyReceived,
          );
          await _db.update(_db.purchaseOrderItems).replace(updatedItem);
        }
      }

      // Determine PO status: fully received or still partial
      final allPoItems = await (_db.select(_db.purchaseOrderItems)
            ..where((tbl) => tbl.purchaseOrderId.equals(purchaseOrderId)))
          .get();

      final isComplete = allPoItems.every(
        (item) => item.qtyReceived >= item.qtyOrdered,
      );

      final updatedPo = po.copyWith(
        status: isComplete ? 'received' : 'sent',
        receivedAt: isComplete ? Value(now) : const Value.absent(),
      );
      await _db.update(_db.purchaseOrders).replace(updatedPo);

      // Audit log
      if (_auditLogger != null) {
        await _auditLogger.log(
          tableName: 'purchase_receiving_items',
          recordId: purchaseOrderId,
          action: 'create',
          newValue: jsonEncode({
            'purchaseOrderId': purchaseOrderId,
            'itemCount': items.length,
            'totalReceived': items.fold<int>(0, (s, i) => s + i.qtyReceived),
            'hasDiscrepancies': items.any((i) => i.hasDiscrepancy),
            'status': isComplete ? 'received' : 'partial',
          }),
          userId: receivedByUserId,
        );
      }
    });
  }

  /// Lists all receiving records for a purchase order.
  Future<List<PurchaseReceivingItem>> getReceivingHistory(int poId) {
    return (_db.select(_db.purchaseReceivingItems)
          ..where((tbl) => tbl.purchaseOrderId.equals(poId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.receivedAt)]))
        .get();
  }

  /// Lists all receiving records with discrepancies for a purchase order.
  Future<List<PurchaseReceivingItem>> getDiscrepancies(int poId) {
    return (_db.select(_db.purchaseReceivingItems)
          ..where((tbl) =>
              tbl.purchaseOrderId.equals(poId) &
              tbl.qtyReceived.isSmallerThan(tbl.qtyOrdered)))
        .get();
  }
}
