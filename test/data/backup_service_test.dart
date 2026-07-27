import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/backup_service.dart';
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
}
