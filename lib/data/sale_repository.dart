import 'dart:convert';

import 'package:drift/drift.dart';

import 'audit_logger.dart';
import 'database.dart';

class MinSellPriceException implements Exception {
  MinSellPriceException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PriceOverrideAuthorizationException implements Exception {
  PriceOverrideAuthorizationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PrescriptionRequiredException implements Exception {
  PrescriptionRequiredException(this.message);
  final String message;

  @override
  String toString() => message;
}

class InsufficientStockException implements Exception {
  InsufficientStockException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ShiftRequiredException implements Exception {
  ShiftRequiredException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CartItemInput {
  CartItemInput({
    required this.product,
    required this.qtyBaseUnit,
    required this.unitPrice,
  });

  final Product product;
  final int qtyBaseUnit;
  final double unitPrice;

  double get subtotal => qtyBaseUnit * unitPrice;
}

class SaleRepository {
  SaleRepository(this._db, {AuditLogger? auditLogger})
      : _auditLogger = auditLogger;

  final AppDatabase _db;
  final AuditLogger? _auditLogger;

  /// Process a point-of-sale transaction with FEFO batch stock allocation.
  Future<SaleTransaction> createSaleTransaction({
    required int cashierId,
    required List<CartItemInput> items,
    required String paymentMethod,
    String? patientName,
    String? doctorName,
    String? prescriptionPhotoPath,
    bool hasPrescription = false,
    String? priceOverrideReason,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('Cart items cannot be empty.');
    }

    final activeShift = await (_db.select(_db.cashierShifts)
          ..where((shift) =>
              shift.cashierId.equals(cashierId) & shift.status.equals('open')))
        .getSingleOrNull();
    if (activeShift == null) {
      throw ShiftRequiredException('An active cashier shift is required before checkout.');
    }

    final isOwnerUse = paymentMethod == 'Owner Use';

    final belowCostItems = items
        .where((item) => !isOwnerUse && item.unitPrice < item.product.costPricePerBaseUnit)
        .toList();
    if (belowCostItems.isNotEmpty) {
      if (priceOverrideReason == null || priceOverrideReason.trim().isEmpty) {
        throw MinSellPriceException(
          'A documented reason is required to sell below cost price.',
        );
      }
      final cashier = await (_db.select(_db.users)
            ..where((user) => user.id.equals(cashierId)))
          .getSingleOrNull();
      if (cashier?.role.trim().toLowerCase() != 'admin') {
        throw PriceOverrideAuthorizationException(
          'Only an administrator can authorize a below-cost sale.',
        );
      }
    }

    // 1. Validation: minimum sell price and controlled-drug prescription.
    for (final item in items) {
      if (item.product.isControlled && !hasPrescription) {
        throw PrescriptionRequiredException(
          '${item.product.name} is a controlled drug. Prescription details and doctor name are required.',
        );
      }
    }

    // Generate unique transaction number
    final now = DateTime.now();
    final txnNo =
        'TXN-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';

    double totalAmount = 0;
    for (final item in items) {
      totalAmount += item.subtotal;
    }
    if (isOwnerUse) {
      totalAmount = 0.0;
    }

    return _db.transaction(() async {
      // Insert SaleTransaction master record
      final txnId = await _db.into(_db.saleTransactions).insert(
            SaleTransactionsCompanion.insert(
              txnNo: txnNo,
              cashierId: cashierId,
              totalAmount: totalAmount,
              paymentMethod: paymentMethod,
              patientName: Value(patientName),
              doctorName: Value(doctorName),
              prescriptionPhotoPath: Value(prescriptionPhotoPath),
              hasPrescription: Value(hasPrescription),
            ),
          );

      // 2. FEFO Stock Batch Allocation and SaleItems creation
      for (final item in items) {
        int remainingToDeduct = item.qtyBaseUnit;

        // Fetch batches ordered by expiry date ASC (First-Expired, First-Out)
        final batches = await (_db.select(_db.stockBatches)
              ..where(
                (tbl) =>
                    tbl.productId.equals(item.product.id) &
                    tbl.qtyRemaining.isBiggerThanValue(0),
              )
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.expiryDate)]))
            .get();

        int availableTotal = batches.fold(0, (sum, b) => sum + b.qtyRemaining);
        if (availableTotal < item.qtyBaseUnit) {
          throw InsufficientStockException(
            'Insufficient stock for ${item.product.name}. Requested: ${item.qtyBaseUnit}, Available: $availableTotal',
          );
        }

        for (final batch in batches) {
          if (remainingToDeduct <= 0) break;

          final deductFromThisBatch =
              remainingToDeduct <= batch.qtyRemaining
                  ? remainingToDeduct
                  : batch.qtyRemaining;

          // Update batch remaining stock
          final updatedBatch = batch.copyWith(
            qtyRemaining: batch.qtyRemaining - deductFromThisBatch,
            updatedAt: Value(now),
          );
          await _db.update(_db.stockBatches).replace(updatedBatch);

          // Insert SaleItem record tied to this batch
          await _db.into(_db.saleItems).insert(
                SaleItemsCompanion.insert(
                  transactionId: txnId,
                  productId: item.product.id,
                  batchId: batch.id,
                  qtySold: deductFromThisBatch,
                  unitPrice: item.unitPrice,
                  subtotal: deductFromThisBatch * item.unitPrice,
                ),
              );

          remainingToDeduct -= deductFromThisBatch;
        }
      }

      if (_auditLogger != null) {
        await _auditLogger.log(
          tableName: 'sale_transactions',
          recordId: txnId,
          action: 'create',
          newValue: jsonEncode({
            'txnNo': txnNo,
            'totalAmount': totalAmount,
            'itemCount': items.length,
            if (belowCostItems.isNotEmpty) 'priceOverrideReason': priceOverrideReason!.trim(),
            if (belowCostItems.isNotEmpty)
              'belowCostProducts': belowCostItems.map((item) => item.product.id).toList(),
          }),
          userId: cashierId,
        );
      }

      final created = await (_db.select(_db.saleTransactions)
            ..where((tbl) => tbl.id.equals(txnId)))
          .getSingle();

      return created;
    });
  }

  /// Lists past sale transactions.
  Future<List<SaleTransaction>> listTransactions() {
    return (_db.select(_db.saleTransactions)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
  }

  /// Retrieves transaction items with batch details for receipt generation.
  Future<List<SaleItem>> getSaleItemsForTransaction(int transactionId) {
    return (_db.select(_db.saleItems)
          ..where((tbl) => tbl.transactionId.equals(transactionId)))
        .get();
  }
}
