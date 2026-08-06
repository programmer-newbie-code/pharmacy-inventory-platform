import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CatalogManifestInfo {
  const CatalogManifestInfo({
    required this.version,
    required this.url,
    required this.drugCount,
    required this.isUpdateAvailable,
    this.isDownloaded = false,
  });

  final String version;
  final String url;
  final int drugCount;
  final bool isUpdateAvailable;
  final bool isDownloaded;
}

class DrugCatalogUpdater {
  DrugCatalogUpdater({
    http.Client? client,
    SharedPreferences? prefs,
    Directory? documentsDirectory,
    this.manifestUrl =
        'https://raw.githubusercontent.com/programmer-newbie-code/pharmacy-inventory-platform/main/assets/data/catalog_manifest.json',
  })  : _client = client ?? http.Client(),
        _prefsOverride = prefs,
        _documentsDirOverride = documentsDirectory;

  final http.Client _client;
  final SharedPreferences? _prefsOverride;
  final Directory? _documentsDirOverride;
  final String manifestUrl;

  static const _catalogVersionKey = 'drug_catalog_active_version';
  static const _catalogDrugCountKey = 'drug_catalog_active_count';
  static const _catalogSubdir = 'drug_catalog';
  static const _downloadedFileName = 'downloaded_drugs.csv';

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? await SharedPreferences.getInstance();

  Future<Directory> _getDocsDir() async {
    return _documentsDirOverride ?? await getApplicationDocumentsDirectory();
  }

  /// Gets the path to the downloaded CSV file, if it exists.
  Future<File?> getDownloadedCatalogFile() async {
    try {
      final docsDir = await _getDocsDir();
      final file = File(p.join(docsDir.path, _catalogSubdir, _downloadedFileName));
      if (await file.exists()) {
        return file;
      }
    } catch (_) {}
    return null;
  }

  /// Gets active catalog info (version, count, whether using downloaded file).
  Future<CatalogManifestInfo> getActiveCatalogInfo() async {
    final prefs = await _prefs;
    final downloadedFile = await getDownloadedCatalogFile();

    if (downloadedFile != null) {
      final version = prefs.getString(_catalogVersionKey) ?? 'Downloaded';
      final count = prefs.getInt(_catalogDrugCountKey) ?? 0;
      return CatalogManifestInfo(
        version: version,
        url: '',
        drugCount: count,
        isUpdateAvailable: false,
        isDownloaded: true,
      );
    }

    // Fallback to bundled asset manifest
    try {
      final raw = await rootBundle.loadString('assets/data/catalog_manifest.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return CatalogManifestInfo(
        version: json['version'] as String? ?? '2026.08.1',
        url: json['url'] as String? ?? '',
        drugCount: json['drugCount'] as int? ?? 204,
        isUpdateAvailable: false,
        isDownloaded: false,
      );
    } catch (_) {
      return const CatalogManifestInfo(
        version: '2026.08.1',
        url: '',
        drugCount: 204,
        isUpdateAvailable: false,
        isDownloaded: false,
      );
    }
  }

  /// Checks online manifest for a newer catalog version.
  Future<CatalogManifestInfo?> checkCatalogUpdate() async {
    try {
      final response = await _client
          .get(Uri.parse(manifestUrl))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final onlineVersion = json['version'] as String? ?? '';
      final onlineUrl = json['url'] as String? ?? '';
      final onlineCount = json['drugCount'] as int? ?? 0;

      if (onlineVersion.isEmpty || onlineUrl.isEmpty) return null;

      final active = await getActiveCatalogInfo();
      final isNewer = onlineVersion != active.version;

      return CatalogManifestInfo(
        version: onlineVersion,
        url: onlineUrl,
        drugCount: onlineCount,
        isUpdateAvailable: isNewer,
      );
    } catch (_) {
      return null;
    }
  }

  /// Downloads CSV from [info.url], validates structure, and saves to app documents directory.
  Future<bool> downloadAndUpdateCatalog(CatalogManifestInfo info) async {
    if (info.url.isEmpty) return false;

    try {
      final response = await _client
          .get(Uri.parse(info.url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return false;

      final csvContent = response.body;
      final cleanCsv = csvContent.replaceAll('\r\n', '\n');
      final rows = const CsvToListConverter(eol: '\n').convert(cleanCsv);

      if (rows.length < 2) return false; // Needs header + at least 1 row

      final docsDir = await _getDocsDir();
      final dir = Directory(p.join(docsDir.path, _catalogSubdir));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File(p.join(dir.path, _downloadedFileName));
      await file.writeAsString(cleanCsv);

      final prefs = await _prefs;
      await prefs.setString(_catalogVersionKey, info.version);
      await prefs.setInt(_catalogDrugCountKey, rows.length - 1);

      return true;
    } catch (_) {
      return false;
    }
  }
}
