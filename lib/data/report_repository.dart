import 'package:drift/drift.dart';

import 'database.dart';

class SalesSummary {
  SalesSummary({
    required this.totalTransactions,
    required this.totalRevenue,
    required this.totalCostOfGoods,
    required this.grossProfit,
  });

  final int totalTransactions;
  final double totalRevenue;
  final double totalCostOfGoods;
  final double grossProfit;
}

class ReportRepository {
  ReportRepository(this._db);

  final AppDatabase _db;

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

    return SalesSummary(
      totalTransactions: count,
      totalRevenue: revenue,
      totalCostOfGoods: cogs,
      grossProfit: revenue - cogs,
    );
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

    for (final t in txns) {
      buffer.writeln(
        '${t.txnNo},${t.createdAt.toIso8601String()},${t.cashierId},"${t.patientName ?? ''}","${t.doctorName ?? ''}",${t.totalAmount},${t.paymentMethod}',
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
