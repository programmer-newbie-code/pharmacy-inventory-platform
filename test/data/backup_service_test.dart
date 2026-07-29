import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/backup_service.dart';
import 'package:pharmacy_inventory_platform/data/backup_document.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';

void main() {
  late AppDatabase db;
  late BackupService backupService;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    backupService = BackupService(db);
    tempDir = await Directory.systemTemp.createTemp('pharmacy_backup_test_');
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('creates local JSON backup file and logs event', () async {
    final filePath = await backupService.createBackupJson(tempDir.path);
    final file = File(filePath);

    expect(await file.exists(), isTrue);

    final logs = await backupService.listBackupLogs();
    expect(logs, hasLength(1));
    expect(logs.first.destination, equals('local'));
    expect(logs.first.status, equals('Success'));
  });

  test('restores database records atomically from backup JSON file', () async {
    // 1. Populate initial data
    await db.into(db.users).insert(
          UsersCompanion.insert(
            username: 'test_admin',
            passwordHash: 'hash',
            role: 'admin',
          ),
        );
    await db.into(db.products).insert(
          ProductsCompanion.insert(
            barcode: '12345',
            internalCode: 'P01',
            name: 'Paracetamol 500mg',
            activeIngredient: 'Paracetamol',
            ingredientPct: 100,
            baseUnit: 'tablet',
            purchaseUnit: 'box',
            unitsPerPurchaseUnit: 100,
            costPricePerBaseUnit: 500,
            marginPct: 0.2,
            reorderThreshold: 50,
            category: 'Analgesics',
            createdBy: 'admin',
          ),
        );

    // 2. Export backup
    final backupFilePath = await backupService.createBackupJson(tempDir.path);

    // 3. Clear database tables
    await db.delete(db.products).go();
    await db.delete(db.users).go();
    expect(await db.select(db.products).get(), isEmpty);
    expect(await db.select(db.users).get(), isEmpty);

    // 4. Restore from backup JSON
    final success = await backupService.restoreFromBackupJson(backupFilePath);
    expect(success, isTrue);

    // 5. Verify restored data
    final restoredProducts = await db.select(db.products).get();
    final restoredUsers = await db.select(db.users).get();
    expect(restoredProducts, hasLength(1));
    expect(restoredProducts.first.name, equals('Paracetamol 500mg'));
    expect(restoredUsers, hasLength(1));
    expect(restoredUsers.first.username, equals('test_admin'));

    final logs = await backupService.listBackupLogs();
    expect(logs.first.destination, equals('restore'));
    expect(logs.first.status, equals('Success'));
  });

  test('exports and restores every persisted business table', () async {
    await _seedEveryTable(db);

    final source = await backupService.exportDatabaseToJson();
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    final document = BackupDocument.parseAndValidate(source);

    expect(decoded['schemaVersion'], BackupDocument.currentSchemaVersion);
    for (final collection in BackupDocument.requiredCollections) {
      expect(decoded['counts'][collection], 1);
      expect(document.data[collection], hasLength(1));
    }

    await backupService.restoreFromBackupData(source);

    expect(await db.select(db.users).get(), hasLength(1));
    expect(await db.select(db.storageLocations).get(), hasLength(1));
    expect(await db.select(db.products).get(), hasLength(1));
    expect(await db.select(db.stockBatches).get(), hasLength(1));
    expect(await db.select(db.saleTransactions).get(), hasLength(1));
    expect(await db.select(db.saleItems).get(), hasLength(1));
    expect(await db.select(db.auditLogs).get(), hasLength(1));
    expect(await db.select(db.cashierShifts).get(), hasLength(1));
    expect(await db.select(db.returnTransactions).get(), hasLength(1));
    expect(await db.select(db.returnItems).get(), hasLength(1));
    expect(await db.select(db.suppliers).get(), hasLength(1));
    expect(await db.select(db.purchaseOrders).get(), hasLength(1));
    expect(await db.select(db.purchaseOrderItems).get(), hasLength(1));
    expect(await db.select(db.backupLogs).get(), hasLength(2));
  });

  test('keeps existing data when a restore violates a database constraint', () async {
    await _seedEveryTable(db);
    final backup = jsonDecode(await backupService.exportDatabaseToJson())
        as Map<String, dynamic>;
    final data = backup['data'] as Map<String, dynamic>;
    final products = data['products'] as List<dynamic>;
    final duplicateBarcode = Map<String, dynamic>.from(products.single as Map)
      ..['id'] = 2
      ..['internalCode'] = 'PCM500-DUP';
    products.add(duplicateBarcode);
    (backup['counts'] as Map<String, dynamic>)['products'] = 2;

    await expectLater(
      backupService.restoreFromBackupData(jsonEncode(backup)),
      throwsA(isA<Object>()),
    );

    final restored = await db.select(db.products).get();
    expect(restored, hasLength(1));
    expect(restored.single.barcode, '8990001');
  });
}

Future<void> _seedEveryTable(AppDatabase db) async {
  final userId = await db.into(db.users).insert(
        UsersCompanion.insert(
          username: 'admin',
          passwordHash: 'hash',
          role: 'admin',
        ),
      );
  final locationId = await db.into(db.storageLocations).insert(
        StorageLocationsCompanion.insert(code: 'A1', name: 'Shelf A1'),
      );
  final productId = await db.into(db.products).insert(
        ProductsCompanion.insert(
          barcode: '8990001',
          internalCode: 'PCM500',
          name: 'Paracetamol',
          activeIngredient: 'Paracetamol',
          ingredientPct: 100,
          baseUnit: 'tablet',
          purchaseUnit: 'box',
          unitsPerPurchaseUnit: 100,
          costPricePerBaseUnit: 1000,
          marginPct: 0.2,
          reorderThreshold: 10,
          storageLocationId: Value(locationId),
          category: 'Analgesic',
          createdBy: 'admin',
        ),
      );
  final batchId = await db.into(db.stockBatches).insert(
        StockBatchesCompanion.insert(
          productId: productId,
          batchNo: 'B-001',
          receivedDate: DateTime(2026, 1, 1),
          expiryDate: DateTime(2027, 1, 1),
          qtyReceived: 100,
          qtyRemaining: 99,
          costPricePerBaseUnit: 1000,
          supplier: 'PT Farma',
          createdBy: 'admin',
        ),
      );
  final saleId = await db.into(db.saleTransactions).insert(
        SaleTransactionsCompanion.insert(
          txnNo: 'SALE-001',
          cashierId: userId,
          totalAmount: 1500,
          paymentMethod: 'cash',
        ),
      );
  final saleItemId = await db.into(db.saleItems).insert(
        SaleItemsCompanion.insert(
          transactionId: saleId,
          productId: productId,
          batchId: batchId,
          qtySold: 1,
          unitPrice: 1500,
          subtotal: 1500,
        ),
      );
  await db.into(db.auditLogs).insert(
        AuditLogsCompanion.insert(
          entityTable: 'products',
          recordId: productId,
          action: 'create',
          userId: userId,
        ),
      );
  await db.into(db.backupLogs).insert(
        BackupLogsCompanion.insert(destination: 'local', status: 'Success'),
      );
  await db.into(db.cashierShifts).insert(
        CashierShiftsCompanion.insert(
          cashierId: userId,
          openingBalance: 100000,
          status: 'open',
        ),
      );
  final returnId = await db.into(db.returnTransactions).insert(
        ReturnTransactionsCompanion.insert(
          returnNo: 'RETURN-001',
          originalTxnId: saleId,
          processedBy: userId,
          reason: 'defective',
          refundAmount: 1500,
          refundMethod: 'Cash',
        ),
      );
  await db.into(db.returnItems).insert(
        ReturnItemsCompanion.insert(
          returnTxnId: returnId,
          saleItemId: saleItemId,
          qtyReturned: 1,
        ),
      );
  final supplierId = await db.into(db.suppliers).insert(
        SuppliersCompanion.insert(name: 'PT Farma'),
      );
  final orderId = await db.into(db.purchaseOrders).insert(
        PurchaseOrdersCompanion.insert(
          poNumber: 'PO-001',
          supplierId: supplierId,
          status: 'received',
          totalAmount: 100000,
          createdBy: 'admin',
        ),
      );
  await db.into(db.purchaseOrderItems).insert(
        PurchaseOrderItemsCompanion.insert(
          purchaseOrderId: orderId,
          productId: productId,
          qtyOrdered: 100,
          unitCost: 1000,
        ),
      );
}
