import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pharmacy_inventory_platform/data/drug_catalog_updater.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('catalog_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('DrugCatalogUpdater', () {
    test('getActiveCatalogInfo returns bundled info when no downloaded file', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final updater = DrugCatalogUpdater(
        prefs: prefs,
        documentsDirectory: tempDir,
      );

      final active = await updater.getActiveCatalogInfo();

      expect(active.version, isNotEmpty);
      expect(active.drugCount, greaterThan(0));
      expect(active.isDownloaded, isFalse);
    });

    test('checkCatalogUpdate parses manifest and detects updates', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'version': '2026.09.1',
            'url': 'https://example.com/drugs.csv',
            'drugCount': 300,
          }),
          200,
        );
      });

      final updater = DrugCatalogUpdater(
        client: client,
        prefs: prefs,
        documentsDirectory: tempDir,
      );
      final info = await updater.checkCatalogUpdate();

      expect(info, isNotNull);
      expect(info!.version, equals('2026.09.1'));
      expect(info.drugCount, equals(300));
      expect(info.isUpdateAvailable, isTrue);
    });

    test('downloadAndUpdateCatalog saves file and records active version', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      const csvData = 'Name,ActiveIngredient,Category,Manufacturer,Unit\n'
          'Paracetamol,Paracetamol 500mg,Obat Bebas,Kimia Farma,tablet\n'
          'Amoxicillin,Amoxicillin 500mg,Obat Keras,Kalbe Farma,kaplet\n';

      final client = MockClient((request) async {
        return http.Response(csvData, 200);
      });

      final updater = DrugCatalogUpdater(
        client: client,
        prefs: prefs,
        documentsDirectory: tempDir,
      );

      const target = CatalogManifestInfo(
        version: '2026.09.1',
        url: 'https://example.com/drugs.csv',
        drugCount: 2,
        isUpdateAvailable: true,
      );

      final success = await updater.downloadAndUpdateCatalog(target);
      expect(success, isTrue);

      final active = await updater.getActiveCatalogInfo();
      expect(active.isDownloaded, isTrue);
      expect(active.version, equals('2026.09.1'));
      expect(active.drugCount, equals(2));

      final downloadedFile = await updater.getDownloadedCatalogFile();
      expect(downloadedFile, isNotNull);
      expect(await downloadedFile!.exists(), isTrue);
    });
  });
}
