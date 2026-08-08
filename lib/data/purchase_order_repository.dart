import 'dart:convert';
import 'package:drift/drift.dart';
import 'audit_logger.dart';
import 'database.dart';

class POItemInput {
  POItemInput({
    required this.productId,
    required this.qtyOrdered,
    required this.unitCost,
  });

  final int productId;
  final int qtyOrdered;
  final double unitCost;

  double get subtotal => qtyOrdered * unitCost;
}

class PurchaseOrderRepository {
  PurchaseOrderRepository(this._db, {AuditLogger? auditLogger})
      : _auditLogger = auditLogger;

  final AppDatabase _db;
  final AuditLogger? _auditLogger;

  /// Creates a purchase order and line items.
  Future<PurchaseOrder> createPurchaseOrder({
    required int supplierId,
    required String createdBy,
    String? notes,
    required List<POItemInput> items,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('PO items cannot be empty.');
    }

    final now = DateTime.now();
    final poNumber =
        'PO-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';

    double totalAmount = 0;
    for (final item in items) {
      totalAmount += item.subtotal;
    }

    return _db.transaction(() async {
      final poId = await _db.into(_db.purchaseOrders).insert(
            PurchaseOrdersCompanion.insert(
              poNumber: poNumber,
              supplierId: supplierId,
              status: 'sent',
              totalAmount: totalAmount,
              notes: Value(notes),
              createdBy: createdBy,
              createdAt: Value(now),
            ),
          );

      for (final item in items) {
        await _db.into(_db.purchaseOrderItems).insert(
              PurchaseOrderItemsCompanion.insert(
                purchaseOrderId: poId,
                productId: item.productId,
                qtyOrdered: item.qtyOrdered,
                qtyReceived: const Value(0),
                unitCost: item.unitCost,
              ),
            );
      }

      if (_auditLogger != null) {
        await _auditLogger.log(
          tableName: 'purchase_orders',
          recordId: poId,
          action: 'create',
          newValue: jsonEncode({
            'poNumber': poNumber,
            'supplierId': supplierId,
            'totalAmount': totalAmount,
            'itemCount': items.length,
          }),
          userId: 1,
        );
      }

      return (_db.select(_db.purchaseOrders)
            ..where((tbl) => tbl.id.equals(poId)))
          .getSingle();
    });
  }

  /// Marks PO received and automatically creates stock batches for received items.
  Future<PurchaseOrder> receivePurchaseOrder({
    required int poId,
    required String batchNoPrefix,
    required DateTime expiryDate,
    Map<int, int>? quantitiesByItemId,
  }) async {
    final now = DateTime.now();

    return _db.transaction(() async {
      final po = await (_db.select(_db.purchaseOrders)
            ..where((tbl) => tbl.id.equals(poId)))
          .getSingle();

      final supplier = await (_db.select(_db.suppliers)
            ..where((tbl) => tbl.id.equals(po.supplierId)))
          .getSingle();

      final poItems = await (_db.select(_db.purchaseOrderItems)
            ..where((tbl) => tbl.purchaseOrderId.equals(poId)))
          .get();

      // Receive only the delivered quantity for each line. Omitting a map keeps
      // the existing full-delivery behavior for callers that receive all lines.
      for (final item in poItems) {
        final remaining = item.qtyOrdered - item.qtyReceived;
        final delivered = quantitiesByItemId == null
            ? remaining
            : quantitiesByItemId[item.id] ?? 0;
        if (delivered < 0 || delivered > remaining) {
          throw ArgumentError.value(
            delivered,
            'quantitiesByItemId',
            'must be between zero and the unreceived quantity',
          );
        }
        if (delivered == 0) continue;

        final updatedItem = item.copyWith(qtyReceived: item.qtyReceived + delivered);
        await _db.update(_db.purchaseOrderItems).replace(updatedItem);

        // Auto-create StockBatch in database
        final batchNo = '$batchNoPrefix-${item.productId}-${updatedItem.qtyReceived}';
        await _db.into(_db.stockBatches).insert(
              StockBatchesCompanion.insert(
                productId: item.productId,
                batchNo: batchNo,
                receivedDate: now,
                expiryDate: expiryDate,
                qtyReceived: delivered,
                qtyRemaining: delivered,
                costPricePerBaseUnit: item.unitCost,
                supplier: supplier.name,
                createdBy: po.createdBy,
                createdAt: Value(now),
              ),
            );
      }

      final updatedItems = await (_db.select(_db.purchaseOrderItems)
            ..where((table) => table.purchaseOrderId.equals(poId)))
          .get();
      final isComplete = updatedItems.every(
        (item) => item.qtyReceived >= item.qtyOrdered,
      );

      // Keep a partially received PO open until every ordered line arrives.
      final updatedPo = po.copyWith(
        status: isComplete ? 'received' : 'sent',
        receivedAt: isComplete ? Value(now) : const Value.absent(),
      );
      await _db.update(_db.purchaseOrders).replace(updatedPo);

      return updatedPo;
    });
  }

  /// Lists all purchase orders ordered by createdAt DESC.
  Future<List<PurchaseOrder>> listPurchaseOrders() {
    return (_db.select(_db.purchaseOrders)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
  }

  /// Retrieves items for a specific purchase order.
  Future<List<PurchaseOrderItem>> getPOItems(int poId) {
    return (_db.select(_db.purchaseOrderItems)
          ..where((tbl) => tbl.purchaseOrderId.equals(poId)))
        .get();
  }

  /// Cancels a purchase order if it has not been received.
  Future<PurchaseOrder> cancelPurchaseOrder(int poId, {String? cancelReason}) async {
    final po = await (_db.select(_db.purchaseOrders)
          ..where((tbl) => tbl.id.equals(poId)))
        .getSingle();

    if (po.status == 'received') {
      throw StateError('Cannot cancel a purchase order that has already been received.');
    }

    final updated = po.copyWith(
      status: 'cancelled',
      notes: cancelReason != null ? Value('${po.notes ?? ''} [CANCELLED: $cancelReason]'.trim()) : Value(po.notes),
    );

    await _db.update(_db.purchaseOrders).replace(updated);

    if (_auditLogger != null) {
      await _auditLogger.log(
        tableName: 'purchase_orders',
        recordId: poId,
        action: 'cancel',
        newValue: jsonEncode({'status': 'cancelled', 'reason': cancelReason}),
        userId: 1,
      );
    }

    return updated;
  }
}
