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

class CsvImportService {
  CsvImportService(this._productRepository);

  final ProductRepository _productRepository;

  /// Parses CSV content string and bulk imports products into the database.
  Future<CsvImportResult> importProductsFromCsv(String csvContent) async {
    final List<List<dynamic>> rows = const CsvToListConverter().convert(
      csvContent,
      eol: '\n',
      shouldParseNumbers: true,
    );

    if (rows.isEmpty) {
      return CsvImportResult(
        successCount: 0,
        failedCount: 0,
        errors: ['CSV file is empty.'],
      );
    }

    int successCount = 0;
    int failedCount = 0;
    final errors = <String>[];

    // Find header index map
    final headerRow = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    
    int getIndex(String name) {
      return headerRow.indexWhere((h) => h == name.toLowerCase());
    }

    final barcodeIdx = getIndex('barcode');
    final internalCodeIdx = getIndex('internalcode');
    final productNameIdx = getIndex('productname');
    final activeIngredientIdx = getIndex('activeingredient');
    final baseUnitIdx = getIndex('baseunit');
    final purchaseUnitIdx = getIndex('purchaseunit');
    final unitsPerPurchaseUnitIdx = getIndex('unitsperpurchaseunit');
    final costPriceIdx = getIndex('costprice');
    final marginPctIdx = getIndex('marginpct');
    final reorderThresholdIdx = getIndex('reorderthreshold');
    final categoryIdx = getIndex('category');
    final isControlledIdx = getIndex('iscontrolled');

    const requiredHeaders = ['barcode', 'internalcode', 'productname'];
    final missingHeaders = requiredHeaders.where((header) => getIndex(header) < 0);
    if (missingHeaders.isNotEmpty) {
      return CsvImportResult(
        successCount: 0,
        failedCount: rows.length - 1,
        errors: ['Missing required CSV columns: ${missingHeaders.join(', ')}.'],
      );
    }

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((element) => element.toString().trim().isEmpty)) {
        continue;
      }

      try {
        final barcode = barcodeIdx >= 0 && barcodeIdx < row.length ? row[barcodeIdx].toString().trim() : '';
        final internalCode = internalCodeIdx >= 0 && internalCodeIdx < row.length ? row[internalCodeIdx].toString().trim() : '';
        final name = productNameIdx >= 0 && productNameIdx < row.length ? row[productNameIdx].toString().trim() : '';
        
        if (name.isEmpty || barcode.isEmpty) {
          failedCount++;
          errors.add('Row $i: Product Name and Barcode are required.');
          continue;
        }

        final activeIngredient = activeIngredientIdx >= 0 && activeIngredientIdx < row.length ? row[activeIngredientIdx].toString().trim() : '';
        final baseUnit = baseUnitIdx >= 0 && baseUnitIdx < row.length ? row[baseUnitIdx].toString().trim() : 'tablet';
        final purchaseUnit = purchaseUnitIdx >= 0 && purchaseUnitIdx < row.length ? row[purchaseUnitIdx].toString().trim() : 'box';
        final unitsPerPurchase = unitsPerPurchaseUnitIdx >= 0 && unitsPerPurchaseUnitIdx < row.length 
            ? (int.tryParse(row[unitsPerPurchaseUnitIdx].toString()) ?? 100)
            : 100;
        final costPrice = costPriceIdx >= 0 && costPriceIdx < row.length 
            ? (double.tryParse(row[costPriceIdx].toString()) ?? 100.0)
            : 100.0;
        final marginPct = marginPctIdx >= 0 && marginPctIdx < row.length 
            ? (double.tryParse(row[marginPctIdx].toString()) ?? 20.0)
            : 20.0;
        final reorderThreshold = reorderThresholdIdx >= 0 && reorderThresholdIdx < row.length 
            ? (int.tryParse(row[reorderThresholdIdx].toString()) ?? 50)
            : 50;
        final category = categoryIdx >= 0 && categoryIdx < row.length ? row[categoryIdx].toString().trim() : 'Obat Bebas';
        final isControlledStr = isControlledIdx >= 0 && isControlledIdx < row.length ? row[isControlledIdx].toString().trim().toLowerCase() : 'false';
        final isControlled = isControlledStr == 'true' || isControlledStr == '1' || isControlledStr == 'yes';

        await _productRepository.createProduct(
          barcode: barcode,
          internalCode: internalCode.isNotEmpty ? internalCode : 'P${DateTime.now().millisecondsSinceEpoch % 10000}',
          name: name,
          activeIngredient: activeIngredient,
          ingredientPct: 100.0,
          baseUnit: baseUnit.isNotEmpty ? baseUnit : 'tablet',
          purchaseUnit: purchaseUnit.isNotEmpty ? purchaseUnit : 'box',
          unitsPerPurchaseUnit: unitsPerPurchase > 0 ? unitsPerPurchase : 100,
          costPricePerBaseUnit: costPrice,
          marginPct: marginPct,
          reorderThreshold: reorderThreshold,
          isControlled: isControlled,
          category: category.isNotEmpty ? category : 'Obat Bebas',
          createdBy: 'admin',
        );

        successCount++;
      } catch (err) {
        failedCount++;
        errors.add('Row $i: $err');
      }
    }

    return CsvImportResult(
      successCount: successCount,
      failedCount: failedCount,
      errors: errors,
    );
  }
}
