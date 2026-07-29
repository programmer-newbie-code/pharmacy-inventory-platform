import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/google_drive_backup_service.dart';
import 'package:pharmacy_inventory_platform/features/backup/backup_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets('renders BackupScreen with localized title and buttons', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final driveService = GoogleDriveBackupService(db);
    await driveService.signInWithGoogle(isMock: true);
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      googleDriveBackupServiceProvider.overrideWithValue(driveService),
    ]);
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

    expect(find.textContaining('Backup uploaded to Google Drive'), findsOneWidget);
  });
}
