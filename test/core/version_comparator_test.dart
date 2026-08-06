import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/version_comparator.dart';

void main() {
  group('VersionComparator', () {
    test('returns true when latest major is higher', () {
      expect(
        VersionComparator.isNewer(
          currentVersion: '1.3.5',
          latestVersion: '2.0.0',
        ),
        isTrue,
      );
    });

    test('returns true when latest minor is higher', () {
      expect(
        VersionComparator.isNewer(
          currentVersion: '1.3.5',
          latestVersion: '1.4.0',
        ),
        isTrue,
      );
    });

    test('returns true when latest patch is higher', () {
      expect(
        VersionComparator.isNewer(
          currentVersion: '1.3.5',
          latestVersion: '1.3.6',
        ),
        isTrue,
      );
    });

    test('handles v prefix and build metadata + tag gracefully', () {
      expect(
        VersionComparator.isNewer(
          currentVersion: '1.3.5+6',
          latestVersion: 'v1.4.0',
        ),
        isTrue,
      );
    });

    test('returns false when current version is equal to latest version', () {
      expect(
        VersionComparator.isNewer(
          currentVersion: '1.3.5',
          latestVersion: 'v1.3.5',
        ),
        isFalse,
      );
    });

    test('returns false when current version is newer than latest version', () {
      expect(
        VersionComparator.isNewer(
          currentVersion: '1.4.0',
          latestVersion: 'v1.3.5',
        ),
        isFalse,
      );
    });

    test('returns false for empty or invalid version strings', () {
      expect(
        VersionComparator.isNewer(
          currentVersion: '',
          latestVersion: '1.0.0',
        ),
        isFalse,
      );
      expect(
        VersionComparator.isNewer(
          currentVersion: '1.0.0',
          latestVersion: '',
        ),
        isFalse,
      );
    });
  });
}
