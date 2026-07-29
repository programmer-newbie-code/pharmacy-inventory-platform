import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'backup_service.dart';
import 'database.dart';
import 'drive_upload_client.dart';

class GoogleAccountUser {
  GoogleAccountUser({
    required this.email,
    required this.displayName,
    required this.accessToken,
  });

  final String email;
  final String displayName;
  final String accessToken;
}

class GoogleDriveBackupResult {
  GoogleDriveBackupResult({
    required this.success,
    required this.fileId,
    required this.fileName,
    required this.fileSize,
    this.errorMessage,
  });

  final bool success;
  final String? fileId;
  final String fileName;
  final int fileSize;
  final String? errorMessage;
}

abstract interface class GoogleAccountAuthorizer {
  Future<GoogleAccountUser?> signIn();
  Future<void> signOut();
}

class GoogleSignInAuthorizer implements GoogleAccountAuthorizer {
  GoogleSignInAuthorizer({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const [
          'email',
          'https://www.googleapis.com/auth/drive.file',
        ]);

  final GoogleSignIn _googleSignIn;

  @override
  Future<GoogleAccountUser?> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    final accessToken = (await account.authentication).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Google did not provide a Drive access token.');
    }
    return GoogleAccountUser(
      email: account.email,
      displayName: account.displayName ?? account.email,
      accessToken: accessToken,
    );
  }

  @override
  Future<void> signOut() => _googleSignIn.signOut();
}

class GoogleDriveBackupService {
  GoogleDriveBackupService(
    this._db, {
    DriveUploadClient? driveUploadClient,
    GoogleAccountAuthorizer? accountAuthorizer,
  })  : _driveUploadClient = driveUploadClient ?? HttpDriveUploadClient(),
        _accountAuthorizer = accountAuthorizer ?? GoogleSignInAuthorizer();

  final AppDatabase _db;
  final DriveUploadClient _driveUploadClient;
  final GoogleAccountAuthorizer _accountAuthorizer;

  GoogleAccountUser? _currentUser;
  GoogleAccountUser? get currentUser => _currentUser;

  /// Signs in user with Google Account OAuth.
  Future<GoogleAccountUser?> signInWithGoogle() async {
    _currentUser = await _accountAuthorizer.signIn();
    return _currentUser;
  }

  /// Signs user out of Google Account.
  Future<void> signOut() async {
    try {
      await _accountAuthorizer.signOut();
    } catch (_) {}
    _currentUser = null;
  }

  /// Uploads a JSON backup payload to Google Drive.
  Future<GoogleDriveBackupResult> uploadBackupToDrive({
    required String accessToken,
    String? customFileName,
  }) async {
    try {
      final backupService = BackupService(_db);
      final jsonPayload = await backupService.exportDatabaseToJson();
      final bytes = utf8.encode(jsonPayload);
      final fileName = customFileName ??
          'pharmacy_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';

      final fileId = await _driveUploadClient.upload(
        accessToken: accessToken,
        fileName: fileName,
        bytes: bytes,
      );

      await _db.into(_db.backupLogs).insert(
              BackupLogsCompanion.insert(
                timestamp: Value(DateTime.now()),
                destination: 'drive',
                status: 'Success',
                fileSize: Value(bytes.length),
              ),
            );

      return GoogleDriveBackupResult(
          success: true,
          fileId: fileId,
          fileName: fileName,
          fileSize: bytes.length,
      );
    } catch (e) {
      await _db.into(_db.backupLogs).insert(
            BackupLogsCompanion.insert(
              timestamp: Value(DateTime.now()),
              destination: 'drive',
              status: 'Failed',
              fileSize: const Value(0),
            ),
          );

      return GoogleDriveBackupResult(
        success: false,
        fileId: null,
        fileName: customFileName ?? 'pharmacy_backup.json',
        fileSize: 0,
        errorMessage: e.toString(),
      );
    }
  }

  /// Downloads and restores a JSON database backup from Google Drive payload string.
  Future<bool> restoreFromCloudJson(String jsonContent) async {
    final backupService = BackupService(_db);
    return backupService.restoreFromBackupData(jsonContent);
  }
}
