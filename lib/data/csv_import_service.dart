import 'package:csv/csv.dart';

import 'product_repository.dart';

class CsvImportResult {
  CsvImportResult({
    required this.successCount,
    required this.failedCount,
    required this.errors,
  });

  final int successCount;
  final int failedCount;
  final List<String> errors;
}

class CsvImportPreview {
  const CsvImportPreview({required this.rows, required this.errors});

  final List<CsvProductImportRow> rows;
  final List<String> errors;

  List<CsvProductImportRow> get validRows =>
      rows.where((row) => row.errors.isEmpty).toList();

  int get invalidRowCount => rows.length - validRows.length;
}

class CsvProductImportRow {
  const CsvProductImportRow({
    required this.rowNumber,
    required this.barcode,
    required this.internalCode,
    required this.name,
    required this.activeIngredient,
    required this.baseUnit,
    required this.purchaseUnit,
    required this.unitsPerPurchaseUnit,
    required this.costPrice,
    required this.marginPct,
    required this.reorderThreshold,
    required this.category,
    required this.isControlled,
    required this.errors,
  });

  final int rowNumber;
  final String barcode;
  final String internalCode;
  final String name;
  final String activeIngredient;
  final String baseUnit;
  final String purchaseUnit;
  final int unitsPerPurchaseUnit;
  final double costPrice;
  final double marginPct;
  final int reorderThreshold;
  final String category;
  final bool isControlled;
  final List<String> errors;
}

class CsvImportService {
  CsvImportService(this._productRepository);

  final ProductRepository _productRepository;

  /// Parses and validates CSV data without writing any products to the database.
  Future<CsvImportPreview> previewProductsFromCsv(String csvContent) async {
    final rows = const CsvToListConverter().convert(
      csvContent,
      eol: '\n',
      shouldParseNumbers: true,
    );

    if (rows.isEmpty) {
      return const CsvImportPreview(rows: [], errors: ['CSV file is empty.']);
    }

    final headerRow =
        rows.first.map((value) => value.toString().trim().toLowerCase()).toList();
    int indexOf(String header) => headerRow.indexOf(header.toLowerCase());

    const requiredHeaders = ['barcode', 'internalcode', 'productname'];
    final missingHeaders =
        requiredHeaders.where((header) => indexOf(header) < 0).toList();
    if (missingHeaders.isNotEmpty) {
      return CsvImportPreview(
        rows: const [],
        errors: ['Missing required CSV columns: ${missingHeaders.join(', ')}.'],
      );
    }

    final barcodeIdx = indexOf('barcode');
    final internalCodeIdx = indexOf('internalcode');
    final productNameIdx = indexOf('productname');
    final activeIngredientIdx = indexOf('activeingredient');
    final baseUnitIdx = indexOf('baseunit');
    final purchaseUnitIdx = indexOf('purchaseunit');
    final unitsPerPurchaseUnitIdx = indexOf('unitsperpurchaseunit');
    final costPriceIdx = indexOf('costprice');
    final marginPctIdx = indexOf('marginpct');
    final reorderThresholdIdx = indexOf('reorderthreshold');
    final categoryIdx = indexOf('category');
    final isControlledIdx = indexOf('iscontrolled');

    String valueAt(List<dynamic> row, int index, [String fallback = '']) =>
        index >= 0 && index < row.length ? row[index].toString().trim() : fallback;

    final previewRows = <CsvProductImportRow>[];
    final seenBarcodes = <String>{};
    final seenInternalCodes = <String>{};
    for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      if (row.isEmpty || row.every((value) => value.toString().trim().isEmpty)) {
        continue;
      }

      final barcode = valueAt(row, barcodeIdx);
      final internalCode = valueAt(row, internalCodeIdx);
      final name = valueAt(row, productNameIdx);
      final errors = <String>[];
      if (barcode.isEmpty) errors.add('Barcode is required.');
      if (internalCode.isEmpty) errors.add('Internal code is required.');
      if (name.isEmpty) errors.add('Product name is required.');
      if (barcode.isNotEmpty && !seenBarcodes.add(barcode)) {
        errors.add('Duplicate barcode in this CSV.');
      }
      if (internalCode.isNotEmpty && !seenInternalCodes.add(internalCode)) {
        errors.add('Duplicate internal code in this CSV.');
      }
      if (barcode.isNotEmpty && await _productRepository.findProductByBarcode(barcode) != null) {
        errors.add('Barcode already exists in inventory.');
      }

      previewRows.add(CsvProductImportRow(
        rowNumber: rowIndex + 1,
        barcode: barcode,
        internalCode: internalCode,
        name: name,
        activeIngredient: valueAt(row, activeIngredientIdx),
        baseUnit: valueAt(row, baseUnitIdx, 'tablet').isEmpty
            ? 'tablet'
            : valueAt(row, baseUnitIdx),
        purchaseUnit: valueAt(row, purchaseUnitIdx, 'box').isEmpty
            ? 'box'
            : valueAt(row, purchaseUnitIdx),
        unitsPerPurchaseUnit:
            int.tryParse(valueAt(row, unitsPerPurchaseUnitIdx, '100')) ?? 100,
        costPrice: double.tryParse(valueAt(row, costPriceIdx, '100')) ?? 100,
        marginPct: double.tryParse(valueAt(row, marginPctIdx, '20')) ?? 20,
        reorderThreshold:
            int.tryParse(valueAt(row, reorderThresholdIdx, '50')) ?? 50,
        category: valueAt(row, categoryIdx, 'Obat Bebas').isEmpty
            ? 'Obat Bebas'
            : valueAt(row, categoryIdx),
        isControlled: const ['true', '1', 'yes']
            .contains(valueAt(row, isControlledIdx, 'false').toLowerCase()),
        errors: errors,
      ));
    }

    return CsvImportPreview(rows: previewRows, errors: const []);
  }

  /// Writes only rows that passed [previewProductsFromCsv] validation.
  Future<CsvImportResult> importPreview(CsvImportPreview preview) async {
    var successCount = 0;
    var failedCount = preview.invalidRowCount;
    final errors = [...preview.errors];
    for (final row in preview.rows) {
      if (row.errors.isNotEmpty) {
        errors.add('Row ${row.rowNumber}: ${row.errors.join(' ')}');
        continue;
      }
      try {
        await _productRepository.createProduct(
          barcode: row.barcode,
          internalCode: row.internalCode,
          name: row.name,
          activeIngredient: row.activeIngredient,
          ingredientPct: 100,
          baseUnit: row.baseUnit,
          purchaseUnit: row.purchaseUnit,
          unitsPerPurchaseUnit: row.unitsPerPurchaseUnit > 0 ? row.unitsPerPurchaseUnit : 100,
          costPricePerBaseUnit: row.costPrice,
          marginPct: row.marginPct,
          reorderThreshold: row.reorderThreshold,
          isControlled: row.isControlled,
          category: row.category,
          createdBy: 'admin',
        );
        successCount++;
      } catch (error) {
        failedCount++;
        errors.add('Row ${row.rowNumber}: $error');
      }
    }
    return CsvImportResult(
      successCount: successCount,
      failedCount: failedCount,
      errors: errors,
    );
  }

  /// Legacy convenience method. New UI should preview before committing.
  Future<CsvImportResult> importProductsFromCsv(String csvContent) async {
    final preview = await previewProductsFromCsv(csvContent);
    return importPreview(preview);
  }
}
