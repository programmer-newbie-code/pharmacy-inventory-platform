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

  test('importProductsFromCsv parses valid CSV and creates product records', () async {
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
  });

  test('importProductsFromCsv handles empty CSV gracefully', () async {
    final result = await service.importProductsFromCsv('');
    expect(result.successCount, equals(0));
    expect(result.errors, contains('CSV file is empty.'));
  });
}
