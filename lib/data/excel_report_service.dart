import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'report_repository.dart';
import 'database.dart';

class ExcelReportService {
  /// Generates an Excel (.xlsx) file bytes for the provided [SalesSummary] data.
  List<int> generateSalesReport({
    required SalesSummary summary,
    required List<DetailedSaleRow> rows,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final excel = Excel.createExcel();

    // Rename default Sheet1 to Sales Summary
    const summarySheetName = 'Sales Summary';
    excel.rename('Sheet1', summarySheetName);
    final summarySheet = excel[summarySheetName];

    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    // Header Title
    summarySheet.appendRow([
      TextCellValue('PharmaLoka — Sales & Financial Report'),
    ]);
    summarySheet.appendRow([
      TextCellValue(
          'Period: ${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}'),
    ]);
    summarySheet.appendRow([]);

    // KPI Summary Table
    summarySheet.appendRow([
      TextCellValue('Metric'),
      TextCellValue('Value'),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Transactions'),
      IntCellValue(summary.totalTransactions),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Revenue'),
      TextCellValue(currencyFormat.format(summary.totalRevenue)),
    ]);
    summarySheet.appendRow([
      TextCellValue('Total Cost of Goods Sold (COGS)'),
      TextCellValue(currencyFormat.format(summary.totalCostOfGoods)),
    ]);
    summarySheet.appendRow([
      TextCellValue('Gross Profit'),
      TextCellValue(currencyFormat.format(summary.grossProfit)),
    ]);
    final marginPct = summary.totalRevenue > 0
        ? (summary.grossProfit / summary.totalRevenue) * 100
        : 0.0;
    summarySheet.appendRow([
      TextCellValue('Gross Margin (%)'),
      TextCellValue('${marginPct.toStringAsFixed(2)}%'),
    ]);

    // Breakdown Sheet
    const breakdownSheetName = 'Transaction Breakdown';
    final breakdownSheet = excel[breakdownSheetName];

    breakdownSheet.appendRow([
      TextCellValue('Txn No'),
      TextCellValue('Date & Time'),
      TextCellValue('Prescription'),
      TextCellValue('Doctor'),
      TextCellValue('Product Name'),
      TextCellValue('Qty Sold'),
      TextCellValue('Unit Price'),
      TextCellValue('Line Total'),
    ]);

    for (final r in rows) {
      breakdownSheet.appendRow([
        TextCellValue(r.txnNo),
        TextCellValue(dateFormat.format(r.createdAt)),
        TextCellValue(r.hasPrescription ? 'Yes' : 'No'),
        TextCellValue(r.doctorName ?? '-'),
        TextCellValue(r.productName),
        IntCellValue(r.qtySold),
        TextCellValue(currencyFormat.format(r.unitPrice)),
        TextCellValue(currencyFormat.format(r.subtotal)),
      ]);
    }

    final bytes = excel.save();
    return bytes ?? [];
  }

  /// Exports and saves the sales report file locally under the Documents directory.
  Future<File> exportAndSaveReport({
    required SalesSummary summary,
    required List<DetailedSaleRow> rows,
    required DateTime startDate,
    required DateTime endDate,
    Directory? baseDirectoryOverride,
  }) async {
    final bytes = generateSalesReport(
      summary: summary,
      rows: rows,
      startDate: startDate,
      endDate: endDate,
    );
    final docsDir =
        baseDirectoryOverride ?? await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file =
        File(p.join(docsDir.path, 'pharmacy_sales_report_$timestamp.xlsx'));
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Generates an Excel (.xlsx) file for the Best-Selling Medicines report.
  ///
  /// Rows are written in the exact order given (already ranked by the
  /// repository) so the exported file matches what the user saw on screen —
  /// this method never re-sorts.
  List<int> generateBestSellingMedicinesReport({
    required BestSellingMedicinesFilter filter,
    required List<BestSellingMedicineRow> rows,
  }) {
    final excel = Excel.createExcel();

    const sheetName = 'Best-Selling Medicines';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('yyyy-MM-dd');
    final rankModeLabel = filter.rankMode == BestSellingRankMode.netQuantity
        ? 'Net Quantity'
        : 'Net Revenue';

    sheet.appendRow([
      TextCellValue('PharmaLoka — Best-Selling Medicines Report'),
    ]);
    sheet.appendRow([
      TextCellValue(
          'Period: ${dateFormat.format(filter.startDate)} to ${dateFormat.format(filter.endDate)} · Ranked by: $rankModeLabel'),
    ]);
    sheet.appendRow([
      TextCellValue('Rank'),
      TextCellValue('Product Name'),
      TextCellValue('Gross Qty'),
      TextCellValue('Returned Qty'),
      TextCellValue('Net Qty'),
      TextCellValue('Gross Revenue'),
      TextCellValue('Refunded Revenue'),
      TextCellValue('Net Revenue'),
    ]);

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(row.productName),
        IntCellValue(row.grossQuantity),
        IntCellValue(row.returnedQuantity),
        IntCellValue(row.netQuantity),
        TextCellValue(currencyFormat.format(row.grossRevenue)),
        TextCellValue(currencyFormat.format(row.refundedRevenue)),
        TextCellValue(currencyFormat.format(row.netRevenue)),
      ]);
    }

    final bytes = excel.save();
    return bytes ?? [];
  }

  /// Exports and saves the Best-Selling Medicines report.
  ///
  /// [baseDirectoryOverride] lets tests write into a temp directory instead of
  /// the platform Documents directory (mirrors [ReceiptStorageService]).
  Future<File> exportAndSaveBestSellingMedicinesReport({
    required BestSellingMedicinesFilter filter,
    required List<BestSellingMedicineRow> rows,
    Directory? baseDirectoryOverride,
  }) async {
    final bytes =
        generateBestSellingMedicinesReport(filter: filter, rows: rows);
    final baseDir =
        baseDirectoryOverride ?? await getApplicationDocumentsDirectory();
    final fileDateFormat = DateFormat('yyyy-MM-dd');
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final rankModeSlug = filter.rankMode == BestSellingRankMode.netQuantity
        ? 'netQuantity'
        : 'netRevenue';
    final fileName = 'pharmacy_best_selling_medicines_'
        '${fileDateFormat.format(filter.startDate)}_'
        '${fileDateFormat.format(filter.endDate)}_'
        '${rankModeSlug}_'
        '$timestamp.xlsx';
    final file = File(p.join(baseDir.path, fileName));
    await file.writeAsBytes(bytes);
    return file;
  }

  List<int> generateProcurementReport({
    required ProcurementSummary summary,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final excel = Excel.createExcel();
    const sheetName = 'Procurement';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('yyyy-MM-dd');

    sheet.appendRow([
      TextCellValue('PharmaLoka — Procurement Report'),
    ]);
    sheet.appendRow([
      TextCellValue(
        'Period: ${dateFormat.format(startDate)} to ${dateFormat.format(endDate)}',
      ),
    ]);
    sheet.appendRow([TextCellValue('Metric'), TextCellValue('Value')]);
    sheet.appendRow([
      TextCellValue('Total Purchases'),
      TextCellValue(currencyFormat.format(summary.totalPurchaseSpend)),
    ]);
    sheet.appendRow([
      TextCellValue('Purchase Orders'),
      IntCellValue(summary.totalOrdersCount),
    ]);
    sheet.appendRow([
      TextCellValue('Batches Received'),
      IntCellValue(summary.receivedBatchesCount),
    ]);
    sheet.appendRow(
        [TextCellValue('Supplier'), TextCellValue('Purchase Spend')]);
    for (final entry in summary.supplierSpendMap.entries) {
      sheet.appendRow([
        TextCellValue(entry.key),
        TextCellValue(currencyFormat.format(entry.value)),
      ]);
    }

    return excel.save() ?? [];
  }

  Future<File> exportAndSaveProcurementReport({
    required ProcurementSummary summary,
    required DateTime startDate,
    required DateTime endDate,
    Directory? baseDirectoryOverride,
  }) async {
    final bytes = generateProcurementReport(
      summary: summary,
      startDate: startDate,
      endDate: endDate,
    );
    final baseDir =
        baseDirectoryOverride ?? await getApplicationDocumentsDirectory();
    final file = File(
      p.join(
        baseDir.path,
        'pharmacy_procurement_report_${DateFormat('yyyy-MM-dd').format(startDate)}_'
        '${DateFormat('yyyy-MM-dd').format(endDate)}_'
        '${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx',
      ),
    );
    await file.writeAsBytes(bytes);
    return file;
  }

  List<int> generateCashMovementReport({
    required List<CashMovement> movements,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final excel = Excel.createExcel();
    const sheetName = 'Cash Movements';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('yyyy-MM-dd HH:mm');

    double totalCashIn = 0;
    double totalCashOut = 0;
    double totalOwnerDraw = 0;
    for (final movement in movements) {
      if (movement.movementType == 'cash_out') {
        totalCashOut += movement.amount;
        if (movement.category == 'owner_draw') {
          totalOwnerDraw += movement.amount;
        }
      } else {
        totalCashIn += movement.amount;
      }
    }

    sheet.appendRow([
      TextCellValue('PharmaLoka — Cash Movement Report'),
    ]);
    sheet.appendRow([
      TextCellValue(
        'Period: ${dateFormat.format(startDate)} to ${dateFormat.format(endDate)}',
      ),
    ]);
    sheet.appendRow([
      TextCellValue('Date & Time'),
      TextCellValue('Type'),
      TextCellValue('Category'),
      TextCellValue('Amount'),
      TextCellValue('Notes'),
    ]);
    for (final movement in movements) {
      sheet.appendRow([
        TextCellValue(timeFormat.format(movement.createdAt)),
        TextCellValue(movement.movementType),
        TextCellValue(movement.category),
        TextCellValue(currencyFormat.format(movement.amount)),
        TextCellValue(movement.notes ?? '-'),
      ]);
    }
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('Total Cash In'),
      TextCellValue(currencyFormat.format(totalCashIn))
    ]);
    sheet.appendRow([
      TextCellValue('Total Cash Out'),
      TextCellValue(currencyFormat.format(totalCashOut))
    ]);
    sheet.appendRow([
      TextCellValue('Owner Draw'),
      TextCellValue(currencyFormat.format(totalOwnerDraw))
    ]);

    return excel.save() ?? [];
  }

  Future<File> exportAndSaveCashMovementReport({
    required List<CashMovement> movements,
    required DateTime startDate,
    required DateTime endDate,
    Directory? baseDirectoryOverride,
  }) async {
    final bytes = generateCashMovementReport(
      movements: movements,
      startDate: startDate,
      endDate: endDate,
    );
    final baseDir =
        baseDirectoryOverride ?? await getApplicationDocumentsDirectory();
    final file = File(
      p.join(
        baseDir.path,
        'pharmacy_cash_movement_report_${DateFormat('yyyy-MM-dd').format(startDate)}_'
        '${DateFormat('yyyy-MM-dd').format(endDate)}_'
        '${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx',
      ),
    );
    await file.writeAsBytes(bytes);
    return file;
  }
}
