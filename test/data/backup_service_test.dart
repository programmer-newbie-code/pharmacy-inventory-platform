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
    expect(logs.first.backupType, equals('Local JSON'));
    expect(logs.first.status, equals('Success'));
  });
}
