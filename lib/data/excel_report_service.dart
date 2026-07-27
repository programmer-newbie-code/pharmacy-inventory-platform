import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'report_repository.dart';

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

    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    // Header Title
    summarySheet.appendRow([
      TextCellValue('Pharmacy Inventory Platform — Sales & Financial Report'),
    ]);
    summarySheet.appendRow([
      TextCellValue('Period: ${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}'),
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
  }) async {
    final bytes = generateSalesReport(
      summary: summary,
      rows: rows,
      startDate: startDate,
      endDate: endDate,
    );
    final docsDir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(p.join(docsDir.path, 'pharmacy_sales_report_$timestamp.xlsx'));
    await file.writeAsBytes(bytes);
    return file;
  }
}
