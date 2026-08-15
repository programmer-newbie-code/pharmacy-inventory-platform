import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/drive_upload_client.dart';
import 'package:pharmacy_inventory_platform/data/google_drive_backup_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:pharmacy_inventory_platform/data/drive_credential_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late GoogleDriveBackupService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = DriveCredentialStore(prefs: prefs);

    db = AppDatabase(NativeDatabase.memory());
    service = GoogleDriveBackupService(
      db,
      driveUploadClient: _SuccessfulDriveUploadClient(),
      accountAuthorizer: _AccountAuthorizer(),
      credentialStore: store,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
      'uploadBackupToDrive delegates to the injected upload client and logs event',
      () async {
    final result = await service.uploadBackupToDrive(
      accessToken: 'access-token',
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

  test('signInWithGoogle stores the account returned by the authorizer',
      () async {
    final user = await service.signInWithGoogle();
    expect(user, isNotNull);
    expect(user?.email, equals('owner@example.com'));
    expect(service.currentUser, isNotNull);

    await service.signOut();
    expect(service.currentUser, isNull);
  });

  test('records a failed Drive attempt when no account is active', () async {
    final result = await service.uploadCurrentUserBackupToDrive();

    expect(result.success, isFalse);
    expect(result.errorMessage, isNull);

    final logs = await db.select(db.backupLogs).get();
    expect(logs, hasLength(1));
    expect(logs.single.destination, equals('drive'));
    expect(logs.single.status, equals('Failed'));
  });

  test('uploads with the active account when one is available', () async {
    await service.signInWithGoogle();

    final result = await service.uploadCurrentUserBackupToDrive();

    expect(result.success, isTrue);
    final logs = await db.select(db.backupLogs).get();
    expect(logs.single.status, equals('Success'));
  });

  test('selects desktop OAuth instead of google_sign_in on Windows', () {
    expect(
      createGoogleAccountAuthorizer(isWindows: true),
      isA<DesktopGoogleAccountAuthorizer>(),
    );
  });

  test(
      'desktop OAuth reports missing build configuration without a plugin error',
      () async {
    await expectLater(
      const DesktopGoogleAccountAuthorizer(
        clientId: '',
        clientSecret: '',
      ).signIn(),
      throwsA(isA<GoogleDriveConfigurationException>()),
    );
  });

  test(
      'uploadBackupToDrive passes configured folderName to upload client',
      () async {
    final uploadClient = _SuccessfulDriveUploadClient();
    final customService = GoogleDriveBackupService(
      db,
      driveUploadClient: uploadClient,
      accountAuthorizer: _AccountAuthorizer(),
    );

    final result = await customService.uploadBackupToDrive(
      accessToken: 'access-token',
      customFolderName: 'My_Custom_Folder',
    );

    expect(result.success, isTrue);
    expect(uploadClient.lastFolderName, equals('My_Custom_Folder'));
  });

  test('DesktopGoogleAccountAuthorizer.openBrowser does not throw on valid uri', () {
    expect(
      () => DesktopGoogleAccountAuthorizer.openBrowser('https://accounts.google.com/o/oauth2/auth'),
      returnsNormally,
    );
    expect(
      () => DesktopGoogleAccountAuthorizer.openBrowser('invalid uri'),
      returnsNormally,
    );
  });
}

class _SuccessfulDriveUploadClient implements DriveUploadClient {
  String? lastFolderName;

  @override
  Future<String> upload({
    required String accessToken,
    required String fileName,
    required List<int> bytes,
    String? folderName,
  }) async {
    lastFolderName = folderName;
    return 'drive-file-id';
  }
}

class _AccountAuthorizer implements GoogleAccountAuthorizer {
  @override
  Future<GoogleAccountUser?> signIn() async => GoogleAccountUser(
        email: 'owner@example.com',
        displayName: 'Owner',
        accessToken: 'access-token',
      );

  @override
  Future<void> signOut() async {}
}
