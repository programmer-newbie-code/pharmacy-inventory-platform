import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:pharmacy_inventory_platform/data/drug_catalog_updater.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('CatalogManifestInfo properties', () {
    const info = CatalogManifestInfo(
      version: '2026.08.01',
      url: 'https://example.com/catalog.csv',
      drugCount: 1500,
      isUpdateAvailable: true,
      isDownloaded: false,
    );

    expect(info.version, '2026.08.01');
    expect(info.drugCount, 1500);
    expect(info.isUpdateAvailable, isTrue);
  });

  test('DrugCatalogUpdater checkUpdate returns manifest info', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final mockClient = http_testing.MockClient((request) async {
      if (request.url.path.contains('catalog_manifest.json')) {
        return http.Response(
          jsonEncode({
            'version': '2026.09.01',
            'url': 'https://example.com/catalog.csv',
            'drugCount': 2000,
          }),
          200,
        );
      }
      return http.Response('Not found', 404);
    });

    final tempDir = Directory.systemTemp.createTempSync();
    addTearDown(() => tempDir.deleteSync(recursive: true));

    final updater = DrugCatalogUpdater(
      client: mockClient,
      prefs: prefs,
      documentsDirectory: tempDir,
    );

    final info = (await updater.checkCatalogUpdate())!;
    expect(info.version, '2026.09.01');
    expect(info.drugCount, 2000);
    expect(info.isUpdateAvailable, isTrue);
  });
}
