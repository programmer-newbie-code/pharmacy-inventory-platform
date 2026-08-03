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
}
