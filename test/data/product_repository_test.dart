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

  test('creates, retrieves, updates, and searches products', () async {
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
      userIdForAudit: 1,
    );

    expect(prodId, isPositive);

    final found = await repository.findProductByBarcode('8991234567890');
    expect(found, isNotNull);
    expect(found!.name, equals('Paracetamol 500mg'));

    final byId = await repository.getProductById(prodId);
    expect(byId, isNotNull);
    expect(byId!.id, equals(prodId));

    // Test update
    final updated = byId.copyWith(name: 'Paracetamol Extra 500mg');
    final success = await repository.updateProduct(
      updated,
      updatedBy: 'admin',
      userIdForAudit: 1,
    );
    expect(success, isTrue);

    final reFetched = await repository.getProductById(prodId);
    expect(reFetched!.name, equals('Paracetamol Extra 500mg'));

    // Test list & search filters
    final searchResult = await repository.listProducts(
      searchQuery: 'Paracetamol',
      category: 'Analgesik',
    );
    expect(searchResult, hasLength(1));

    final controlledOnly =
        await repository.listProducts(isControlledOnly: true);
    expect(controlledOnly, isEmpty);
  });
}
