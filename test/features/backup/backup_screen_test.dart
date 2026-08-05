import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/drive_upload_client.dart';
import 'package:pharmacy_inventory_platform/data/google_drive_backup_service.dart';
import 'package:pharmacy_inventory_platform/features/backup/backup_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets('renders BackupScreen with localized title and buttons', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final driveService = GoogleDriveBackupService(
      db,
      accountAuthorizer: _AccountAuthorizer(),
      driveUploadClient: _DriveUploadClient(),
    );
    await driveService.signInWithGoogle();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        googleDriveBackupServiceProvider.overrideWithValue(driveService),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('id'),
          home: BackupScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pencadangan & Pemulihan Data'), findsOneWidget);
    expect(find.byKey(const Key('createBackupBtn')), findsOneWidget);
    expect(find.byKey(const Key('googleDriveBackupBtn')), findsOneWidget);
    expect(find.text('Riwayat Log Cadangan'), findsOneWidget);

    await tester.tap(find.byKey(const Key('googleDriveBackupBtn')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Cadangan berhasil diunggah ke Google Drive'),
      findsOneWidget,
    );
  });

  testWidgets('shows Windows setup guidance instead of a plugin exception', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final driveService = GoogleDriveBackupService(
      db,
      accountAuthorizer: _AccountAuthorizer(),
      driveUploadClient: _FailingDriveUploadClient(),
    );
    await driveService.signInWithGoogle();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        googleDriveBackupServiceProvider.overrideWithValue(driveService),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('id'),
          home: BackupScreen(),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('googleDriveBackupBtn')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('belum dikonfigurasi di Windows'),
      findsOneWidget,
    );
    expect(find.textContaining('MissingPluginException'), findsNothing);
  });
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

class _DriveUploadClient implements DriveUploadClient {
  @override
  Future<String> upload({
    required String accessToken,
    required String fileName,
    required List<int> bytes,
  }) async =>
      'drive-file-id';
}

class _FailingDriveUploadClient implements DriveUploadClient {
  @override
  Future<String> upload({
    required String accessToken,
    required String fileName,
    required List<int> bytes,
  }) {
    throw StateError(
      'MissingPluginException(No implementation found for init)',
    );
  }
}
