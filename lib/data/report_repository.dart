import 'package:drift/drift.dart';

import 'audit_logger.dart';
import 'database.dart';

class SalesSummary {
  const SalesSummary({
    required this.totalTransactions,
    required this.totalRevenue,
    required this.totalCostOfGoods,
    required this.grossProfit,
    required this.totalRefunds,
    required this.netRevenue,
  });

  final int totalTransactions;
  final double totalRevenue;
  final double totalCostOfGoods;
  final double grossProfit;
  final double totalRefunds;
  final double netRevenue;

  double get grossMarginPct =>
      totalRevenue > 0 ? (grossProfit / totalRevenue) * 100 : 0;
}

class ReportRepository {
  ReportRepository(this._db, {AuditLogger? auditLogger})
      : _auditLogger = auditLogger;

  final AppDatabase _db;
  final AuditLogger? _auditLogger;

  /// Generates sales summary report for a given date range.
  Future<SalesSummary> getSalesSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final query = _db.select(_db.saleTransactions)
      ..where((tbl) =>
          tbl.createdAt.isBiggerOrEqual(Variable(startDate)) &
          tbl.createdAt.isSmallerOrEqual(Variable(endDate)));
    final txns = await query.get();

    int count = txns.length;
    double revenue = txns.fold(0.0, (sum, t) => sum + t.totalAmount);

    // Calculate COGS by joining sale items with stock batches
    double cogs = 0.0;
    for (final txn in txns) {
      final items = await (_db.select(_db.saleItems)
            ..where((tbl) => tbl.transactionId.equals(txn.id)))
          .get();

      for (final item in items) {
        final batch = await (_db.select(_db.stockBatches)
              ..where((tbl) => tbl.id.equals(item.batchId)))
            .getSingleOrNull();

        final costPerUnit = batch?.costPricePerBaseUnit ?? 0.0;
        cogs += item.qtySold * costPerUnit;
      }
    }

    // Total refunds in the same period
    final refunds = await (_db.select(_db.returnTransactions)
          ..where((tbl) =>
              tbl.createdAt.isBiggerOrEqual(Variable(startDate)) &
              tbl.createdAt.isSmallerOrEqual(Variable(endDate))))
        .get();
    final totalRefunds =
        refunds.fold(0.0, (sum, r) => sum + r.refundAmount);

    return SalesSummary(
      totalTransactions: count,
      totalRevenue: revenue,
      totalCostOfGoods: cogs,
      grossProfit: revenue - cogs,
      totalRefunds: totalRefunds,
      netRevenue: revenue - totalRefunds,
    );
  }

  /// Returns cash discrepancies for closed shifts in the date range.
  Future<List<ShiftDiscrepancy>> getShiftDiscrepancies({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final shifts = await (_db.select(_db.cashierShifts)
          ..where((tbl) =>
              tbl.status.equals('closed') &
              tbl.closedAt.isBiggerOrEqual(Variable(startDate)) &
              tbl.closedAt.isSmallerOrEqual(Variable(endDate))))
        .get();

    return shifts
        .where((s) => s.discrepancy != null && s.discrepancy != 0)
        .map((s) => ShiftDiscrepancy(
              shiftId: s.id,
              cashierId: s.cashierId,
              expectedCash: s.expectedCash ?? 0,
              actualCash: s.actualCash ?? 0,
              discrepancy: s.discrepancy ?? 0,
              discrepancyReason: s.discrepancyReason,
              closedAt: s.closedAt!,
            ))
        .toList();
  }

  /// Logs a report export to the audit trail.
  Future<void> logExport({
    required int userId,
    required String exportType,
    String? details,
  }) async {
    if (_auditLogger != null) {
      await _auditLogger.log(
        tableName: 'report_exports',
        recordId: 0,
        action: 'export_',
        userId: userId,
        newValue: details,
      );
    }
  }

  /// Exports prescription sales log as CSV format for BPOM / Kemenkes compliance.
  Future<String> exportPrescriptionSalesCsv() async {
    final txns = await (_db.select(_db.saleTransactions)
          ..where((tbl) => tbl.hasPrescription.equals(true)))
        .get();

    final buffer = StringBuffer();
    buffer.writeln(
      'TransactionNo,Date,CashierID,PatientName,DoctorName,TotalAmount,PaymentMethod',
    );

    for (final txn in txns) {
      buffer.writeln(
        ',,,"","",,',
      );
    }

    return buffer.toString();
  }

  /// Fetches detailed line items for Excel breakdown.
  Future<List<DetailedSaleRow>> getDetailedSalesRows({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final txns = await (_db.select(_db.saleTransactions)
          ..where((tbl) =>
              tbl.createdAt.isBiggerOrEqual(Variable(startDate)) &
              tbl.createdAt.isSmallerOrEqual(Variable(endDate))))
        .get();

    final rows = <DetailedSaleRow>[];
    for (final txn in txns) {
      final items = await (_db.select(_db.saleItems)
            ..where((tbl) => tbl.transactionId.equals(txn.id)))
          .get();

      for (final item in items) {
        final product = await (_db.select(_db.products)
              ..where((tbl) => tbl.id.equals(item.productId)))
            .getSingleOrNull();

        rows.add(
          DetailedSaleRow(
            txnNo: txn.txnNo,
            createdAt: txn.createdAt,
            hasPrescription: txn.hasPrescription,
            doctorName: txn.doctorName,
            productName: product?.name ?? 'Unknown Product',
            qtySold: item.qtySold,
            unitPrice: item.unitPrice,
            subtotal: item.subtotal,
          ),
        );
      }
    }
    return rows;
  }
}

class ShiftDiscrepancy {
  const ShiftDiscrepancy({
    required this.shiftId,
    required this.cashierId,
    required this.expectedCash,
    required this.actualCash,
    required this.discrepancy,
    this.discrepancyReason,
    required this.closedAt,
  });

  final int shiftId;
  final int cashierId;
  final double expectedCash;
  final double actualCash;
  final double discrepancy;
  final String? discrepancyReason;
  final DateTime closedAt;
}

class DetailedSaleRow {
  DetailedSaleRow({
    required this.txnNo,
    required this.createdAt,
    required this.hasPrescription,
    required this.doctorName,
    required this.productName,
    required this.qtySold,
    required this.unitPrice,
    required this.subtotal,
  });

  final String txnNo;
  final DateTime createdAt;
  final bool hasPrescription;
  final String? doctorName;
  final String productName;
  final int qtySold;
  final double unitPrice;
  final double subtotal;
}


