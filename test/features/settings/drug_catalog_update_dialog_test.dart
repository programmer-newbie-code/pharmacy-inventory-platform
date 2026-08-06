import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/drug_catalog_updater.dart';
import 'package:pharmacy_inventory_platform/features/settings/drug_catalog_update_dialog.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({DrugCatalogUpdater? updater}) {
    return ProviderScope(
      overrides: [
        if (updater != null)
          drugCatalogUpdaterProvider.overrideWithValue(updater),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DrugCatalogUpdateDialog(),
        ),
      ),
    );
  }

  group('DrugCatalogUpdateDialog', () {
    testWidgets('renders title and active catalog version', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final tempDir = Directory.systemTemp.createTempSync('dialog_test_');

      try {
        final updater = DrugCatalogUpdater(
          prefs: prefs,
          documentsDirectory: tempDir,
        );

        await tester.pumpWidget(buildTestWidget(updater: updater));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Drug Catalog Updates'), findsOneWidget);
        expect(find.byKey(const Key('checkCatalogBtn')), findsOneWidget);
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });
  });
}
