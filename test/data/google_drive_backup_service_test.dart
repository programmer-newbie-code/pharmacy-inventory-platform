import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/drive_upload_client.dart';
import 'package:pharmacy_inventory_platform/data/google_drive_backup_service.dart';

void main() {
  late AppDatabase db;
  late GoogleDriveBackupService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = GoogleDriveBackupService(
      db,
      driveUploadClient: _SuccessfulDriveUploadClient(),
      accountAuthorizer: _AccountAuthorizer(),
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
}

class _SuccessfulDriveUploadClient implements DriveUploadClient {
  @override
  Future<String> upload({
    required String accessToken,
    required String fileName,
    required List<int> bytes,
  }) async =>
      'drive-file-id';
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
