import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:pharmacy_inventory_platform/data/app_update_service.dart';

void main() {
  group('AppUpdateService', () {
    test('returns null when currentVersion is empty', () async {
      final service = AppUpdateService();
      final result = await service.checkForUpdates(currentVersion: '');
      expect(result, isNull);
    });

    test('parses latest release and sets hasUpdate to true when newer release exists',
        () async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/releases/latest')) {
          return http.Response(
            jsonEncode({
              'tag_name': 'v1.4.0',
              'html_url': 'https://github.com/owner/repo/releases/tag/v1.4.0',
              'body': 'Release notes for 1.4.0',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = AppUpdateService(client: client);
      final result = await service.checkForUpdates(currentVersion: '1.3.5');

      expect(result, isNotNull);
      expect(result!.latestVersion, equals('1.4.0'));
      expect(result.hasUpdate, isTrue);
      expect(result.releaseUrl, equals('https://github.com/owner/repo/releases/tag/v1.4.0'));
    });

    test('sets hasUpdate to false when running current or newer release', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'tag_name': 'v1.3.5',
            'html_url': 'https://github.com/owner/repo/releases/tag/v1.3.5',
            'body': 'Notes',
          }),
          200,
        );
      });

      final service = AppUpdateService(client: client);
      final result = await service.checkForUpdates(currentVersion: '1.3.5');

      expect(result, isNotNull);
      expect(result!.hasUpdate, isFalse);
    });

    test('returns null gracefully on HTTP error response', () async {
      final client = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final service = AppUpdateService(client: client);
      final result = await service.checkForUpdates(currentVersion: '1.3.5');

      expect(result, isNull);
    });
  });
}
