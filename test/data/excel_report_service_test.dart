import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/excel_report_service.dart';
import 'package:pharmacy_inventory_platform/data/report_repository.dart';

void main() {
  late ExcelReportService service;

  setUp(() {
    service = ExcelReportService();
  });

  test('generateSalesReport creates non-empty Excel bytes for summary and detailed rows', () {
    const summary = SalesSummary(
      totalTransactions: 1,
      totalRevenue: 55000,
      totalCostOfGoods: 35000,
      grossProfit: 20000,
      totalRefunds: 0,
      netRevenue: 55000,
    );

    final rows = [
      DetailedSaleRow(
        txnNo: 'TXN-20260727-001',
        createdAt: DateTime.now(),
        hasPrescription: false,
        doctorName: null,
        productName: 'Paracetamol 500mg',
        qtySold: 10,
        unitPrice: 5500,
        subtotal: 55000,
      ),
    ];

    final bytes = service.generateSalesReport(
      summary: summary,
      rows: rows,
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 31),
    );

    expect(bytes, isNotEmpty);
  });

  group('generateBestSellingMedicinesReport', () {
    final filter = BestSellingMedicinesFilter(
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 11),
      rankMode: BestSellingRankMode.netRevenue,
    );

    const rows = [
      BestSellingMedicineRow(
        productId: 1,
        productName: 'Paracetamol 500mg',
        grossQuantity: 20,
        returnedQuantity: 2,
        grossRevenue: 100000,
        refundedRevenue: 10000,
        netQuantity: 18,
        netRevenue: 90000,
      ),
      BestSellingMedicineRow(
        productId: 2,
        productName: 'Amoxicillin 500mg',
        grossQuantity: 15,
        returnedQuantity: 0,
        grossRevenue: 150000,
        refundedRevenue: 0,
        netQuantity: 15,
        netRevenue: 150000,
      ),
    ];

    test('includes period, rank mode, headers, and rows in the exact order given', () {
      final bytes = service.generateBestSellingMedicinesReport(
        filter: filter,
        rows: rows,
      );

      expect(bytes, isNotEmpty);

      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Best-Selling Medicines'];

      final metadataRow =
          sheet.row(1).map((cell) => cell?.value?.toString() ?? '').join(' ');
      expect(metadataRow, contains('2026-08-01'));
      expect(metadataRow, contains('2026-08-11'));
      expect(metadataRow, contains('Net Revenue'));

      final headerRow =
          sheet.row(3).map((cell) => cell?.value?.toString() ?? '').toList();
      expect(headerRow, [
        'Rank',
        'Product Name',
        'Gross Qty',
        'Returned Qty',
        'Net Qty',
        'Gross Revenue',
        'Refunded Revenue',
        'Net Revenue',
      ]);

      final firstDataRow = sheet.row(4);
      expect(firstDataRow[0]?.value?.toString(), '1');
      expect(firstDataRow[1]?.value?.toString(), 'Paracetamol 500mg');

      final secondDataRow = sheet.row(5);
      expect(secondDataRow[0]?.value?.toString(), '2');
      expect(secondDataRow[1]?.value?.toString(), 'Amoxicillin 500mg');
    });

    test('generates a header-only sheet when there are no rows', () {
      final bytes = service.generateBestSellingMedicinesReport(
        filter: filter,
        rows: const [],
      );

      final excel = Excel.decodeBytes(bytes);
      final sheet = excel['Best-Selling Medicines'];
      expect(sheet.maxRows, 4);
    });
  });

  group('exportAndSaveBestSellingMedicinesReport', () {
    late Directory tempDir;

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('best_selling_export_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('writes a deterministic, descriptive filename into the target directory', () async {
      final filter = BestSellingMedicinesFilter(
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 11),
        rankMode: BestSellingRankMode.netQuantity,
      );

      final file = await service.exportAndSaveBestSellingMedicinesReport(
        filter: filter,
        rows: const [],
        baseDirectoryOverride: tempDir,
      );

      expect(await file.exists(), isTrue);
      expect(file.path, contains('pharmacy_best_selling_medicines'));
      expect(file.path, contains('2026-08-01'));
      expect(file.path, contains('2026-08-11'));
      expect(file.path, contains('netQuantity'));
      expect(file.path, endsWith('.xlsx'));
      expect(await file.readAsBytes(), isNotEmpty);
    });
  });
}
