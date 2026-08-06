/// Utility for comparing Semantic Version strings (e.g. "1.3.5", "v1.4.0", "1.3.5+6").
class VersionComparator {
  /// Returns `true` if [latestVersion] is strictly newer than [currentVersion].
  static bool isNewer({
    required String currentVersion,
    required String latestVersion,
  }) {
    final currentNums = _parseVersionNumbers(currentVersion);
    final latestNums = _parseVersionNumbers(latestVersion);

    if (currentNums.isEmpty || latestNums.isEmpty) return false;

    final maxLen = currentNums.length > latestNums.length
        ? currentNums.length
        : latestNums.length;

    for (var i = 0; i < maxLen; i++) {
      final cur = i < currentNums.length ? currentNums[i] : 0;
      final lat = i < latestNums.length ? latestNums[i] : 0;

      if (lat > cur) return true;
      if (lat < cur) return false;
    }

    return false;
  }

  static List<int> _parseVersionNumbers(String raw) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('v') || cleaned.startsWith('V')) {
      cleaned = cleaned.substring(1);
    }
    // Remove build metadata e.g. "+6"
    if (cleaned.contains('+')) {
      cleaned = cleaned.split('+').first;
    }
    // Remove pre-release tags e.g. "-beta.1"
    if (cleaned.contains('-')) {
      cleaned = cleaned.split('-').first;
    }

    final parts = cleaned.split('.');
    final result = <int>[];
    for (final part in parts) {
      final parsed = int.tryParse(part);
      if (parsed != null) {
        result.add(parsed);
      } else {
        break;
      }
    }
    return result;
  }
}
