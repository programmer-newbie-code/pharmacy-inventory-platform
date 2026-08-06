import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pharmacy_inventory_platform/data/auto_backup_scheduler.dart';
import 'package:pharmacy_inventory_platform/data/backup_service.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/google_drive_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late BackupService backupService;
  late GoogleDriveBackupService driveBackupService;

  setUp(() {
    db = AppDatabase.defaultConnection();
    backupService = BackupService(db);
    driveBackupService = GoogleDriveBackupService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AutoBackupScheduler preferences', () {
    test('defaults to enabled with Drive disabled', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final scheduler = AutoBackupScheduler(
        backupService: backupService,
        driveBackupService: driveBackupService,
        prefs: prefs,
      );

      expect(await scheduler.isEnabled(), isTrue);
      expect(await scheduler.isDriveEnabled(), isFalse);
    });

    test('setEnabled persists preference and controls timer', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final scheduler = AutoBackupScheduler(
        backupService: backupService,
        driveBackupService: driveBackupService,
        prefs: prefs,
      );

      await scheduler.setEnabled(false);
      expect(await scheduler.isEnabled(), isFalse);
      expect(scheduler.isActive, isFalse);

      // Re-enabling starts the timer (backup may fail silently due to
      // path_provider in test, but the timer itself should activate).
      await scheduler.setEnabled(true);
      expect(await scheduler.isEnabled(), isTrue);

      scheduler.stop();
    });

    test('setDriveEnabled persists preference', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final scheduler = AutoBackupScheduler(
        backupService: backupService,
        driveBackupService: driveBackupService,
        prefs: prefs,
      );

      expect(await scheduler.isDriveEnabled(), isFalse);
      await scheduler.setDriveEnabled(true);
      expect(await scheduler.isDriveEnabled(), isTrue);
    });

    test('getLastBackupTime returns null when never run', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final scheduler = AutoBackupScheduler(
        backupService: backupService,
        driveBackupService: driveBackupService,
        prefs: prefs,
      );

      expect(await scheduler.getLastBackupTime(), isNull);
    });

    test('getNextBackupTime returns null when not active', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final scheduler = AutoBackupScheduler(
        backupService: backupService,
        driveBackupService: driveBackupService,
        prefs: prefs,
      );

      expect(await scheduler.getNextBackupTime(), isNull);
    });
  });

  group('AutoBackupScheduler timer lifecycle', () {
    test('start does not run when disabled', () async {
      SharedPreferences.setMockInitialValues({'autoBackupEnabled': false});
      final prefs = await SharedPreferences.getInstance();

      final scheduler = AutoBackupScheduler(
        backupService: backupService,
        driveBackupService: driveBackupService,
        prefs: prefs,
      );

      await scheduler.start();
      expect(scheduler.isActive, isFalse);
    });

    test('start activates timer when enabled', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final scheduler = AutoBackupScheduler(
        backupService: backupService,
        driveBackupService: driveBackupService,
        prefs: prefs,
      );

      // start() triggers an immediate backup attempt which may fail in test
      // (path_provider), but the periodic timer should still be scheduled.
      await scheduler.start();
      expect(scheduler.isActive, isTrue);

      scheduler.stop();
      expect(scheduler.isActive, isFalse);
    });

    test('stop cancels timer', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final scheduler = AutoBackupScheduler(
        backupService: backupService,
        driveBackupService: driveBackupService,
        prefs: prefs,
      );

      await scheduler.start();
      expect(scheduler.isActive, isTrue);

      scheduler.stop();
      expect(scheduler.isActive, isFalse);
    });

    test('getNextBackupTime returns future time when active and last run is set',
        () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        'autoBackupLastRunAt': now.millisecondsSinceEpoch,
      });
      final prefs = await SharedPreferences.getInstance();

      final scheduler = AutoBackupScheduler(
        backupService: backupService,
        driveBackupService: driveBackupService,
        intervalHours: 24,
        prefs: prefs,
      );

      // Start scheduler — won't be overdue since we just set lastRun to now
      await scheduler.start();
      expect(scheduler.isActive, isTrue);

      final next = await scheduler.getNextBackupTime();
      expect(next, isNotNull);
      expect(next!.isAfter(now), isTrue);

      scheduler.stop();
    });

    test('skips immediate backup when last run is recent', () async {
      final recentRun = DateTime.now();
      SharedPreferences.setMockInitialValues({
        'autoBackupLastRunAt': recentRun.millisecondsSinceEpoch,
      });
      final prefs = await SharedPreferences.getInstance();

      final scheduler = AutoBackupScheduler(
        backupService: backupService,
        driveBackupService: driveBackupService,
        intervalHours: 24,
        prefs: prefs,
      );

      await scheduler.start();
      expect(scheduler.isActive, isTrue);

      // Last run should still be the same (no new backup ran)
      final lastRun = await scheduler.getLastBackupTime();
      expect(lastRun, isNotNull);
      expect(
        lastRun!.millisecondsSinceEpoch,
        equals(recentRun.millisecondsSinceEpoch),
      );

      scheduler.stop();
    });
  });
}
