import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/version_comparator.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.releaseNotes,
    required this.hasUpdate,
  });

  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final String releaseNotes;
  final bool hasUpdate;
}

class AppUpdateService {
  AppUpdateService({
    http.Client? client,
    this.repoOwner = 'programmer-newbie-code',
    this.repoName = 'pharmacy-inventory-platform',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String repoOwner;
  final String repoName;

  /// Checks GitHub Releases API for the latest version and compares against [currentVersion].
  Future<AppUpdateInfo?> checkForUpdates({
    required String currentVersion,
  }) async {
    if (currentVersion.isEmpty) return null;

    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/$repoOwner/$repoName/releases/latest',
      );

      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'PharmacyInventoryApp/$currentVersion',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = body['tag_name'] as String? ?? '';
      final htmlUrl = body['html_url'] as String? ?? '';
      final releaseNotes = body['body'] as String? ?? '';

      if (tagName.isEmpty) return null;

      final hasUpdate = VersionComparator.isNewer(
        currentVersion: currentVersion,
        latestVersion: tagName,
      );

      return AppUpdateInfo(
        currentVersion: currentVersion,
        latestVersion: tagName.startsWith('v') ? tagName.substring(1) : tagName,
        releaseUrl: htmlUrl,
        releaseNotes: releaseNotes,
        hasUpdate: hasUpdate,
      );
    } catch (_) {
      // Network unavailable or rate limited — return null silently
      return null;
    }
  }
}
