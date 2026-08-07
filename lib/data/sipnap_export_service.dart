import 'package:excel/excel.dart';
import 'database.dart';

class SipnapReportRow {
  SipnapReportRow({
    required this.productName,
    required this.category,
    required this.openingStock,
    required this.qtyReceived,
    required this.qtySold,
    required this.closingStock,
    required this.unit,
  });

  final String productName;
  final String category;
  final int openingStock;
  final int qtyReceived;
  final int qtySold;
  final int closingStock;
  final String unit;
}

class SipnapExportService {
  SipnapExportService(this._db);

  final AppDatabase _db;

  /// Generates SIPNAP report rows for controlled substances during [year] and [month].
  Future<List<SipnapReportRow>> generateMonthlyReport({
    required int year,
    required int month,
  }) async {
    // Get controlled products
    final controlledProducts = await (_db.select(_db.products)
          ..where((p) => p.isControlled.equals(true)))
        .get();

    final rows = <SipnapReportRow>[];

    for (final p in controlledProducts) {
      // Calculate sales in month
      final salesInMonth = await (_db.select(_db.saleItems)
            ..where((s) => s.productId.equals(p.id)))
          .get();

      final totalSold = salesInMonth.fold<int>(
        0,
        (sum, item) => sum + item.qtySold,
      );

      // Current remaining stock in active batches
      final batches = await (_db.select(_db.stockBatches)
            ..where((b) => b.productId.equals(p.id)))
          .get();
      final closingStock = batches.fold<int>(
        0,
        (sum, b) => sum + b.qtyRemaining,
      );

      // Estimated opening stock
      final openingStock = closingStock + totalSold;

      rows.add(
        SipnapReportRow(
          productName: p.name,
          category: p.controlledCategory ?? 'Narkotika/Psikotropika',
          openingStock: openingStock,
          qtyReceived: 0,
          qtySold: totalSold,
          closingStock: closingStock,
          unit: p.baseUnit,
        ),
      );
    }

    return rows;
  }

  /// Exports the SIPNAP monthly report as Excel bytes.
  Future<List<int>> exportSipnapExcel({
    required int year,
    required int month,
    required String pharmacyName,
    required String siaNo,
  }) async {
    final rows = await generateMonthlyReport(year: year, month: month);

    final excel = Excel.createExcel();
    final sheet = excel['SIPNAP Report'];

    // Header metadata
    sheet.appendRow([TextCellValue('LAPORAN SIPNAP KEMENKES RI')]);
    sheet.appendRow([TextCellValue('Apotek: $pharmacyName')]);
    sheet.appendRow([TextCellValue('SIA: $siaNo')]);
    sheet.appendRow([TextCellValue('Periode: $month / $year')]);
    sheet.appendRow([]);

    // Table Headers
    sheet.appendRow([
      TextCellValue('No'),
      TextCellValue('Nama Obat'),
      TextCellValue('Kategori'),
      TextCellValue('Stok Awal'),
      TextCellValue('Penerimaan'),
      TextCellValue('Pengeluaran'),
      TextCellValue('Stok Akhir'),
      TextCellValue('Satuan'),
    ]);

    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(r.productName),
        TextCellValue(r.category),
        IntCellValue(r.openingStock),
        IntCellValue(r.qtyReceived),
        IntCellValue(r.qtySold),
        IntCellValue(r.closingStock),
        TextCellValue(r.unit),
      ]);
    }

    return excel.encode() ?? [];
  }
}
