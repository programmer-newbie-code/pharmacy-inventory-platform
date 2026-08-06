import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_service.dart';
import 'google_drive_backup_service.dart';

/// Background scheduler that performs automatic local backups every 24 hours
/// while the app is running.
///
/// On startup, if more than [intervalHours] have elapsed since the last
/// auto-backup, a backup runs immediately. Old local backup files are rotated
/// to keep only the most recent [maxLocalBackups].
class AutoBackupScheduler {
  AutoBackupScheduler({
    required BackupService backupService,
    required GoogleDriveBackupService driveBackupService,
    this.intervalHours = 24,
    this.maxLocalBackups = 7,
    SharedPreferences? prefs,
  })  : _backupService = backupService,
        _driveBackupService = driveBackupService,
        _prefsOverride = prefs;

  final BackupService _backupService;
  final GoogleDriveBackupService _driveBackupService;
  final int intervalHours;
  final int maxLocalBackups;
  final SharedPreferences? _prefsOverride;

  Timer? _timer;
  bool _running = false;

  static const _lastAutoBackupKey = 'autoBackupLastRunAt';
  static const _enabledKey = 'autoBackupEnabled';
  static const _driveEnabledKey = 'autoBackupDriveEnabled';
  static const _backupSubdir = 'auto_backups';

  /// Whether auto-backup is currently scheduled.
  bool get isActive => _timer?.isActive ?? false;

  /// Initializes the scheduler. Call once after the database is ready.
  ///
  /// If auto-backup is enabled and the interval has elapsed, an immediate
  /// backup is triggered. Then a periodic timer is started.
  Future<void> start() async {
    final prefs = _prefsOverride ?? await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? true;
    if (!enabled) return;

    // Check if overdue
    final lastRun = await getLastBackupTime();
    if (lastRun == null ||
        DateTime.now().difference(lastRun).inHours >= intervalHours) {
      await _performBackup();
    }

    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(hours: intervalHours),
      (_) => _performBackup(),
    );
  }

  /// Stops the periodic timer.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Returns the last auto-backup timestamp, or null if never run.
  Future<DateTime?> getLastBackupTime() async {
    final prefs = _prefsOverride ?? await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastAutoBackupKey);
    return millis != null
        ? DateTime.fromMillisecondsSinceEpoch(millis)
        : null;
  }

  /// Returns the next scheduled backup time, or null if not active.
  Future<DateTime?> getNextBackupTime() async {
    final last = await getLastBackupTime();
    if (last == null || !isActive) return null;
    return last.add(Duration(hours: intervalHours));
  }

  /// Whether auto-backup is enabled in user preferences.
  Future<bool> isEnabled() async {
    final prefs = _prefsOverride ?? await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  /// Toggles auto-backup on/off and persists the preference.
  Future<void> setEnabled(bool enabled) async {
    final prefs = _prefsOverride ?? await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    if (enabled) {
      await start();
    } else {
      stop();
    }
  }

  /// Whether Google Drive upload is included in auto-backup.
  Future<bool> isDriveEnabled() async {
    final prefs = _prefsOverride ?? await SharedPreferences.getInstance();
    return prefs.getBool(_driveEnabledKey) ?? false;
  }

  /// Toggles Drive upload during auto-backup.
  Future<void> setDriveEnabled(bool enabled) async {
    final prefs = _prefsOverride ?? await SharedPreferences.getInstance();
    await prefs.setBool(_driveEnabledKey, enabled);
  }

  /// Returns the directory used for auto-backup files.
  Future<Directory> getBackupDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, _backupSubdir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Core backup logic. Creates a local backup and optionally uploads to Drive.
  Future<void> _performBackup() async {
    if (_running) return; // Prevent concurrent runs
    _running = true;

    try {
      final dir = await getBackupDirectory();
      await _backupService.createBackupJson(dir.path);
      await _rotateOldBackups(dir);

      // Record timestamp
      final prefs = _prefsOverride ?? await SharedPreferences.getInstance();
      await prefs.setInt(
        _lastAutoBackupKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      // Optional Drive upload
      final driveEnabled = await isDriveEnabled();
      if (driveEnabled) {
        final user = _driveBackupService.currentUser;
        if (user != null) {
          await _driveBackupService.uploadBackupToDrive(
            accessToken: user.accessToken,
          );
        }
      }
    } catch (_) {
      // Auto-backup should never crash the app. Failures are visible
      // in the backup logs table via BackupService.
    } finally {
      _running = false;
    }
  }

  /// Keeps only the [maxLocalBackups] most recent files in [dir].
  Future<void> _rotateOldBackups(Directory dir) async {
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();

    if (files.length <= maxLocalBackups) return;

    // Sort by modified time descending (newest first)
    files.sort((a, b) =>
        b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    for (final old in files.skip(maxLocalBackups)) {
      try {
        await old.delete();
      } catch (_) {}
    }
  }
}
