import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/audit_logger.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/product_repository.dart';

void main() {
  late AppDatabase db;
  late AuditLogger auditLogger;
  late ProductRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    auditLogger = AuditLogger(db);
    repository = ProductRepository(db, auditLogger: auditLogger);
  });

  tearDown(() async {
    await db.close();
  });

  test('creates storage location successfully', () async {
    final id = await repository.createStorageLocation(
      code: 'RAK-A1',
      name: 'Shelf A1',
      description: 'Main medicine shelf',
    );
    expect(id, isPositive);

    final locations = await repository.listStorageLocations();
    expect(locations, hasLength(1));
    expect(locations.first.code, equals('RAK-A1'));
  });

  test('creates and retrieves product by barcode and search query', () async {
    final locId = await repository.createStorageLocation(
      code: 'RAK-B1',
      name: 'Shelf B1',
    );

    final prodId = await repository.createProduct(
      barcode: '8991234567890',
      internalCode: 'PCT-500',
      name: 'Paracetamol 500mg',
      activeIngredient: 'Paracetamol',
      ingredientPct: 100.0,
      baseUnit: 'tablet',
      purchaseUnit: 'box',
      unitsPerPurchaseUnit: 100,
      costPricePerBaseUnit: 250.0,
      marginPct: 20.0,
      reorderThreshold: 50,
      isControlled: false,
      storageLocationId: locId,
      category: 'Analgesik',
      createdBy: 'admin',
    );

    expect(prodId, isPositive);

    final found = await repository.findProductByBarcode('8991234567890');
    expect(found, isNotNull);
    expect(found!.name, equals('Paracetamol 500mg'));

    final searchResult = await repository.listProducts(searchQuery: 'Paracetamol');
    expect(searchResult, hasLength(1));

    final controlledOnly =
        await repository.listProducts(isControlledOnly: true);
    expect(controlledOnly, isEmpty);
  });
}
