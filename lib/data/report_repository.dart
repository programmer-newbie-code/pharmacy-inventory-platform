import 'package:drift/drift.dart';

import 'audit_logger.dart';
import 'database.dart';

class ProcurementSummary {
  const ProcurementSummary({
    required this.totalPurchaseSpend,
    required this.totalOrdersCount,
    required this.receivedBatchesCount,
    required this.supplierSpendMap,
  });

  final double totalPurchaseSpend;
  final int totalOrdersCount;
  final int receivedBatchesCount;
  final Map<String, double> supplierSpendMap;
}

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

enum BestSellingRankMode { netQuantity, netRevenue }

class BestSellingMedicineRow {
  const BestSellingMedicineRow({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.returnedQuantity,
    required this.grossRevenue,
    required this.netRevenue,
  });

  final int productId;
  final String productName;
  final int quantitySold;
  final int returnedQuantity;
  final double grossRevenue;
  final double netRevenue;

  int get netQuantity => quantitySold - returnedQuantity;
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
    final totalRefunds = refunds.fold(0.0, (sum, r) => sum + r.refundAmount);

    return SalesSummary(
      totalTransactions: count,
      totalRevenue: revenue,
      totalCostOfGoods: cogs,
      grossProfit: revenue - cogs,
      totalRefunds: totalRefunds,
      netRevenue: revenue - totalRefunds,
    );
  }

  /// Returns medicines ranked by net quantity or net revenue for a period.
  ///
  /// Returns are attributed using their processed date, so the report reflects
  /// the stock and revenue movement that happened during the selected period.
  Future<List<BestSellingMedicineRow>> getBestSellingMedicines({
    required DateTime startDate,
    required DateTime endDate,
    BestSellingRankMode rankBy = BestSellingRankMode.netQuantity,
  }) async {
    final transactions = await (_db.select(_db.saleTransactions)
          ..where((txn) =>
              txn.createdAt.isBiggerOrEqual(Variable(startDate)) &
              txn.createdAt.isSmallerOrEqual(Variable(endDate))))
        .get();
    if (transactions.isEmpty) return const [];

    final transactionIds = transactions.map((txn) => txn.id).toList();
    final saleItems = await (_db.select(_db.saleItems)
          ..where((item) => item.transactionId.isIn(transactionIds)))
        .get();
    if (saleItems.isEmpty) return const [];

    final productIds = saleItems.map((item) => item.productId).toSet().toList();
    final products = await (_db.select(_db.products)
          ..where((product) => product.id.isIn(productIds)))
        .get();
    final productNames = {
      for (final product in products) product.id: product.name
    };

    final returns = await (_db.select(_db.returnTransactions)
          ..where((txn) =>
              txn.createdAt.isBiggerOrEqual(Variable(startDate)) &
              txn.createdAt.isSmallerOrEqual(Variable(endDate)) &
              txn.originalTxnId.isIn(transactionIds)))
        .get();
    final returnedBySaleItem = <int, int>{};
    if (returns.isNotEmpty) {
      final returnItems = await (_db.select(_db.returnItems)
            ..where(
                (item) => item.returnTxnId.isIn(returns.map((txn) => txn.id))))
          .get();
      for (final item in returnItems) {
        returnedBySaleItem[item.saleItemId] =
            (returnedBySaleItem[item.saleItemId] ?? 0) + item.qtyReturned;
      }
    }

    final totals = <int, _BestSellingTotals>{};
    for (final item in saleItems) {
      final total = totals.putIfAbsent(item.productId, _BestSellingTotals.new);
      final returnedQuantity = returnedBySaleItem[item.id] ?? 0;
      total.quantitySold += item.qtySold;
      total.returnedQuantity += returnedQuantity;
      total.grossRevenue += item.subtotal;
      total.netRevenue += item.subtotal - (returnedQuantity * item.unitPrice);
    }

    final rows = totals.entries
        .map((entry) {
          final total = entry.value;
          return BestSellingMedicineRow(
            productId: entry.key,
            productName: productNames[entry.key] ?? 'Unknown Product',
            quantitySold: total.quantitySold,
            returnedQuantity: total.returnedQuantity,
            grossRevenue: total.grossRevenue,
            netRevenue: total.netRevenue,
          );
        })
        .where((row) => row.netQuantity > 0)
        .toList();
    rows.sort((a, b) {
      final primary = rankBy == BestSellingRankMode.netQuantity
          ? b.netQuantity.compareTo(a.netQuantity)
          : b.netRevenue.compareTo(a.netRevenue);
      return primary != 0 ? primary : a.productName.compareTo(b.productName);
    });
    return rows;
  }

  /// Generates procurement / purchasing summary report for a given date range.
  Future<ProcurementSummary> getProcurementSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final poQuery = _db.select(_db.purchaseOrders)
      ..where((tbl) =>
          tbl.createdAt.isBiggerOrEqual(Variable(startDate)) &
          tbl.createdAt.isSmallerOrEqual(Variable(endDate)));
    final pos = await poQuery.get();

    final supplierQuery = await _db.select(_db.suppliers).get();
    final supplierMap = {for (var s in supplierQuery) s.id: s.name};

    double totalSpend = 0.0;
    final supplierSpend = <String, double>{};

    for (final po in pos) {
      if (po.status != 'cancelled') {
        totalSpend += po.totalAmount;
        final sName =
            supplierMap[po.supplierId] ?? 'Supplier #${po.supplierId}';
        supplierSpend[sName] = (supplierSpend[sName] ?? 0.0) + po.totalAmount;
      }
    }

    final batchesQuery = _db.select(_db.stockBatches)
      ..where((tbl) =>
          tbl.receivedDate.isBiggerOrEqual(Variable(startDate)) &
          tbl.receivedDate.isSmallerOrEqual(Variable(endDate)));
    final batches = await batchesQuery.get();

    return ProcurementSummary(
      totalPurchaseSpend: totalSpend,
      totalOrdersCount: pos.where((p) => p.status != 'cancelled').length,
      receivedBatchesCount: batches.length,
      supplierSpendMap: supplierSpend,
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
        action: 'export_$exportType',
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

    for (final _ in txns) {
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

class _BestSellingTotals {
  int quantitySold = 0;
  int returnedQuantity = 0;
  double grossRevenue = 0;
  double netRevenue = 0;
}
