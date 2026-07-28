import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/google_drive_backup_service.dart';

void main() {
  late AppDatabase db;
  late GoogleDriveBackupService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = GoogleDriveBackupService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('uploadBackupToDrive succeeds with test token and logs event', () async {
    final result = await service.uploadBackupToDrive(
      accessToken: 'test_token',
      customFileName: 'test_backup.json',
    );

    expect(result.success, isTrue);
    expect(result.fileName, equals('test_backup.json'));
    expect(result.fileId, isNotNull);

    final logs = await db.select(db.backupLogs).get();
    expect(logs, hasLength(1));
    expect(logs.first.destination, equals('drive'));
    expect(logs.first.status, equals('Success'));
  });

  test('restoreFromCloudJson imports database JSON payload successfully', () async {
    const payload = '{"users":[],"products":[],"stock_batches":[]}';
    final success = await service.restoreFromCloudJson(payload);
    expect(success, isTrue);
  });
}
