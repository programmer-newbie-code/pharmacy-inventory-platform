import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/drive_credential_store.dart';
import 'package:pharmacy_inventory_platform/features/settings/drive_setup_dialog.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({DriveCredentialStore? store}) {
    return ProviderScope(
      overrides: [
        if (store != null)
          driveCredentialStoreProvider.overrideWithValue(store),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DriveSetupDialog(),
        ),
      ),
    );
  }

  group('DriveSetupDialog', () {
    testWidgets('renders title, inputs, and buttons', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = DriveCredentialStore(prefs: prefs);

      await tester.pumpWidget(buildTestWidget(store: store));
      await tester.pumpAndSettle();

      expect(find.text('Google Drive OAuth Setup'), findsOneWidget);
      expect(find.byKey(const Key('driveClientIdInput')), findsOneWidget);
      expect(find.byKey(const Key('driveClientSecretInput')), findsOneWidget);
      expect(find.byKey(const Key('driveFolderNameInput')), findsOneWidget);
      expect(find.byKey(const Key('saveDriveCredentialsBtn')), findsOneWidget);
    });

    testWidgets('saves entered credentials and folder name when save is tapped', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = DriveCredentialStore(prefs: prefs);

      await tester.pumpWidget(buildTestWidget(store: store));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('driveClientIdInput')),
        'test_client_id.apps.googleusercontent.com',
      );
      await tester.enterText(
        find.byKey(const Key('driveClientSecretInput')),
        'test_secret_123',
      );
      await tester.enterText(
        find.byKey(const Key('driveFolderNameInput')),
        'Custom_Pharmacy_Backups',
      );
      await tester.tap(find.byKey(const Key('saveDriveCredentialsBtn')));
      await tester.pumpAndSettle();

      expect(
        await store.getClientId(),
        equals('test_client_id.apps.googleusercontent.com'),
      );
      expect(await store.getClientSecret(), equals('test_secret_123'));
      expect(await store.getBackupFolderName(), equals('Custom_Pharmacy_Backups'));
      expect(find.text('Google Drive configuration saved successfully.'), findsOneWidget);
    });

    testWidgets('clears saved credentials when clear button is tapped', (tester) async {
      SharedPreferences.setMockInitialValues({
        'google_drive_client_id': 'old_id',
        'google_drive_client_secret': 'old_secret',
        'google_drive_backup_folder_name': 'Old_Folder',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = DriveCredentialStore(prefs: prefs);

      await tester.pumpWidget(buildTestWidget(store: store));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clearDriveCredentialsBtn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('clearDriveCredentialsBtn')));
      await tester.pumpAndSettle();

      expect(await store.hasCredentials(), isFalse);
      expect(await store.getBackupFolderName(), equals(DriveCredentialStore.defaultBackupFolderName));
      expect(find.text('Google Drive configuration cleared.'), findsOneWidget);
    });
  });
}
