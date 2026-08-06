import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'backup_service.dart';
import 'database.dart';
import 'drive_credential_store.dart';
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

class GoogleDriveConfigurationException implements Exception {
  const GoogleDriveConfigurationException();
}

GoogleAccountAuthorizer createGoogleAccountAuthorizer({
  bool? isWindows,
  DriveCredentialStore? credentialStore,
}) =>
    (isWindows ?? Platform.isWindows)
        ? DesktopGoogleAccountAuthorizer(credentialStore: credentialStore)
        : GoogleSignInAuthorizer();

class GoogleSignInAuthorizer implements GoogleAccountAuthorizer {
  GoogleSignInAuthorizer({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(scopes: const [
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

class DesktopGoogleAccountAuthorizer implements GoogleAccountAuthorizer {
  const DesktopGoogleAccountAuthorizer({
    this.clientId =
        const String.fromEnvironment('GOOGLE_DRIVE_DESKTOP_CLIENT_ID'),
    this.clientSecret =
        const String.fromEnvironment('GOOGLE_DRIVE_DESKTOP_CLIENT_SECRET'),
    this.credentialStore,
  });

  final String clientId;
  final String clientSecret;
  final DriveCredentialStore? credentialStore;

  @override
  Future<GoogleAccountUser?> signIn() async {
    String activeId = clientId;
    String activeSecret = clientSecret;

    if (credentialStore != null) {
      final storedId = await credentialStore!.getClientId();
      final storedSecret = await credentialStore!.getClientSecret();
      if (storedId != null && storedSecret != null) {
        activeId = storedId;
        activeSecret = storedSecret;
      }
    }

    if (activeId.isEmpty || activeSecret.isEmpty) {
      throw const GoogleDriveConfigurationException();
    }

    final client = http.Client();
    try {
      final credentials = await obtainAccessCredentialsViaUserConsent(
        ClientId(activeId, activeSecret),
        const ['email', 'https://www.googleapis.com/auth/drive.file'],
        client,
        _openBrowser,
      );
      return GoogleAccountUser(
        email: 'Google Drive desktop account',
        displayName: 'Google Drive',
        accessToken: credentials.accessToken.data,
      );
    } finally {
      client.close();
    }
  }

  static void _openBrowser(String uri) {
    unawaited(Process.start('cmd', ['/c', 'start', '', uri]));
  }

  @override
  Future<void> signOut() async {}
}

class GoogleDriveBackupService {
  GoogleDriveBackupService(
    this._db, {
    DriveUploadClient? driveUploadClient,
    GoogleAccountAuthorizer? accountAuthorizer,
    DriveCredentialStore? credentialStore,
  })  : _driveUploadClient = driveUploadClient ?? HttpDriveUploadClient(),
        _accountAuthorizer = accountAuthorizer ??
            createGoogleAccountAuthorizer(credentialStore: credentialStore);

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
