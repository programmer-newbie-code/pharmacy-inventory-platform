import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/csv_import_service.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/product_repository.dart';

void main() {
  late AppDatabase db;
  late ProductRepository productRepo;
  late CsvImportService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    productRepo = ProductRepository(db);
    service = CsvImportService(productRepo);
  });

  tearDown(() async {
    await db.close();
  });

  test('importProductsFromCsv parses valid CSV and creates product records',
      () async {
    const csvData =
        'Barcode,InternalCode,ProductName,ActiveIngredient,BaseUnit,PurchaseUnit,UnitsPerPurchaseUnit,CostPrice,MarginPct,ReorderThreshold,Category,IsControlled\n'
        '899123456701,P001,Amoxicillin 500mg,Amoxicillin,tablet,box,100,500,20,50,Obat Keras,true\n'
        '899123456702,P002,Paracetamol 500mg,Paracetamol,tablet,box,100,200,25,30,Obat Bebas,false';

    final result = await service.importProductsFromCsv(csvData);

    expect(result.successCount, equals(2));
    expect(result.failedCount, equals(0));

    final products = await productRepo.listProducts();
    expect(products, hasLength(2));
    expect(products.first.name, equals('Amoxicillin 500mg'));
    expect(products.first.isControlled, isTrue);
    expect(products.last.name, equals('Paracetamol 500mg'));
    expect(products.last.isControlled, isFalse);

    final logs = await productRepo.listCsvImportLogs();
    expect(logs, hasLength(1));
    expect(logs.single.sourceName, equals('unknown.csv'));
    expect(logs.single.importedRows, equals(2));
    expect(logs.single.rejectedRows, equals(0));
    expect(logs.single.status, equals('success'));
  });

  test('importProductsFromCsv handles empty CSV gracefully', () async {
    final result = await service.importProductsFromCsv('');
    expect(result.successCount, equals(0));
    expect(result.errors, contains('CSV file is empty.'));
  });

  test('preview validates rows without writing products', () async {
    const csvData = 'Barcode,InternalCode,ProductName\n'
        '899123456701,P001,Paracetamol\n'
        '899123456701,P002,Duplicate barcode\n'
        ',P003,Missing barcode';

    final preview = await service.previewProductsFromCsv(csvData);

    expect(preview.rows, hasLength(3));
    expect(preview.validRows, hasLength(1));
    expect(preview.rows[1].errors, contains('Duplicate barcode in this CSV.'));
    expect(preview.rows[2].errors, contains('Barcode is required.'));
    expect(await productRepo.listProducts(), isEmpty);
  });

  test('preview identifies a barcode already stored in inventory', () async {
    await productRepo.createProduct(
      barcode: '899123456701',
      internalCode: 'EXISTING',
      name: 'Existing product',
      activeIngredient: '',
      ingredientPct: 100,
      baseUnit: 'tablet',
      purchaseUnit: 'box',
      unitsPerPurchaseUnit: 1,
      costPricePerBaseUnit: 100,
      marginPct: 20,
      reorderThreshold: 1,
      category: 'Obat Bebas',
      createdBy: 'admin',
    );

    final preview = await service.previewProductsFromCsv(
      'Barcode,InternalCode,ProductName\n899123456701,P001,Paracetamol',
    );

    expect(preview.validRows, isEmpty);
    expect(preview.rows.single.errors,
        contains('Barcode already exists in inventory.'));
  });

  test('preview identifies an internal code already stored in inventory',
      () async {
    await productRepo.createProduct(
      barcode: '899123456701',
      internalCode: 'EXISTING',
      name: 'Existing product',
      activeIngredient: '',
      ingredientPct: 100,
      baseUnit: 'tablet',
      purchaseUnit: 'box',
      unitsPerPurchaseUnit: 1,
      costPricePerBaseUnit: 100,
      marginPct: 20,
      reorderThreshold: 1,
      category: 'Obat Bebas',
      createdBy: 'admin',
    );

    final preview = await service.previewProductsFromCsv(
      'Barcode,InternalCode,ProductName\n899123456702,EXISTING,Paracetamol',
    );

    expect(preview.validRows, isEmpty);
    expect(
      preview.rows.single.errors,
      contains('Internal code already exists in inventory.'),
    );
  });

  test('preview rejects malformed and non-positive numeric values', () async {
    final preview = await service.previewProductsFromCsv(
      'Barcode,InternalCode,ProductName,UnitsPerPurchaseUnit,CostPrice,MarginPct,ReorderThreshold\n'
      '899123456701,P001,Paracetamol,zero,0,nope,-1',
    );

    expect(preview.validRows, isEmpty);
    expect(preview.rows.single.errors,
        contains('Units per purchase unit must be a positive integer.'));
    expect(preview.rows.single.errors,
        contains('Cost price must be a positive number.'));
    expect(preview.rows.single.errors,
        contains('Margin percentage must be a valid number.'));
    expect(preview.rows.single.errors,
        contains('Reorder threshold must be zero or greater.'));
  });

  test('importPreview writes only validated rows and reports rejected rows',
      () async {
    final preview = await service.previewProductsFromCsv(
      'Barcode,InternalCode,ProductName\n899123456701,P001,Paracetamol\n,P002,Missing barcode',
    );

    final result = await service.importPreview(preview);

    expect(result.successCount, 1);
    expect(result.failedCount, 1);
    expect(await productRepo.listProducts(), hasLength(1));
  });

  test('importPreview preserves source and initiating user metadata', () async {
    final preview = await service.previewProductsFromCsv(
      'Barcode,InternalCode,ProductName\n899123456701,P001,Paracetamol',
    );

    await service.importPreview(
      preview,
      sourceName: 'stock-take.csv',
      createdBy: 'davit',
    );

    final product = (await productRepo.listProducts()).single;
    expect(product.createdBy, equals('davit'));
    final log = (await productRepo.listCsvImportLogs()).single;
    expect(log.sourceName, equals('stock-take.csv'));
    expect(log.createdBy, equals('davit'));
  });

  test('importPreview rolls back valid rows when a write fails unexpectedly',
      () async {
    const row = CsvProductImportRow(
      rowNumber: 2,
      barcode: '899123456701',
      internalCode: 'P001',
      name: 'Paracetamol',
      activeIngredient: 'Paracetamol',
      baseUnit: 'tablet',
      purchaseUnit: 'box',
      unitsPerPurchaseUnit: 100,
      costPrice: 100,
      marginPct: 20,
      reorderThreshold: 10,
      category: 'Obat Bebas',
      isControlled: false,
      errors: [],
    );
    const conflictingRow = CsvProductImportRow(
      rowNumber: 3,
      barcode: '899123456701',
      internalCode: 'P002',
      name: 'Duplicate barcode',
      activeIngredient: '',
      baseUnit: 'tablet',
      purchaseUnit: 'box',
      unitsPerPurchaseUnit: 100,
      costPrice: 100,
      marginPct: 20,
      reorderThreshold: 10,
      category: 'Obat Bebas',
      isControlled: false,
      errors: [],
    );

    final result = await service.importPreview(
      const CsvImportPreview(rows: [row, conflictingRow], errors: []),
    );

    expect(result.successCount, 0);
    expect(result.failedCount, 2);
    expect(await productRepo.listProducts(), isEmpty);
    final logs = await productRepo.listCsvImportLogs();
    expect(logs, hasLength(1));
    expect(logs.single.status, equals('failed'));
    expect(logs.single.importedRows, equals(0));
    expect(logs.single.rejectedRows, equals(2));
  });

  test('import history is newest first', () async {
    final preview = await service.previewProductsFromCsv(
      'Barcode,InternalCode,ProductName\n899123456701,P001,Paracetamol',
    );
    await service.importPreview(
      preview,
      sourceName: 'older.csv',
      createdBy: 'inventory',
    );
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final secondPreview = await service.previewProductsFromCsv(
      'Barcode,InternalCode,ProductName\n899123456702,P002,Ibuprofen',
    );
    await service.importPreview(secondPreview, sourceName: 'newer.csv');

    final logs = await productRepo.listCsvImportLogs();
    expect(logs.map((log) => log.sourceName), ['newer.csv', 'older.csv']);
    expect(logs.last.createdBy, equals('inventory'));
  });

  test('rejects CSV missing required columns without importing products',
      () async {
    const csvData = 'Barcode,ProductName\n899123456701,Paracetamol';

    final result = await service.importProductsFromCsv(csvData);

    expect(result.successCount, 0);
    expect(result.errors.single, contains('internalcode'));
    expect(await productRepo.listProducts(), isEmpty);
  });
}
