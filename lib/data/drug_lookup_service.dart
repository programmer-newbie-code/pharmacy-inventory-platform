import 'dart:math';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'drug_catalog_updater.dart';

/// A single drug record returned by any lookup source.
class DrugLookupResult {
  DrugLookupResult({
    required this.name,
    required this.activeIngredient,
    required this.category,
    required this.manufacturer,
    required this.unit,
    this.registrationNumber = '',
    this.source = DrugSource.offline,
  });

  final String name;
  final String activeIngredient;
  final String category;
  final String manufacturer;
  final String unit;
  final String registrationNumber;
  final DrugSource source;

  /// Whether this drug likely requires a prescription.
  bool get requiresPrescription =>
      category == 'Obat Keras' ||
      category == 'Psikotropika' ||
      category == 'Narkotika';

  @override
  String toString() => '$name ($category)';
}

enum DrugSource { offline, bpom }

/// Indonesian drug lookup service.
///
/// Strategy (offline-first):
///  1. Search bundled CSV asset with trigram similarity for instant, fuzzy results.
///  2. Attempt live BPOM search as a secondary source.
///
/// N-gram / Trigram rationale:
///   Indonesian pharmacists often spell drug names inconsistently,
///   e.g. "parasetamol" vs "paracetamol", "amoxisilin" vs "amoxicillin".
///   Trigram (3-char n-gram) similarity handles these variants gracefully
///   without needing a full NLP library, making it ideal for on-device search.

/// Indonesian drug lookup service.
///
/// Strategy (offline-first):
///  1. Search downloaded catalog (or bundled CSV asset) with trigram similarity for instant, fuzzy results.
///  2. Attempt live BPOM search as a secondary source.
class DrugLookupService {
  DrugLookupService({
    http.Client? client,
    DrugCatalogUpdater? catalogUpdater,
  })  : _client = client ?? http.Client(),
        _catalogUpdater = catalogUpdater ?? DrugCatalogUpdater();

  final http.Client _client;
  final DrugCatalogUpdater _catalogUpdater;
  List<DrugLookupResult>? _offlineCache;

  /// Clears the cached drug list so subsequent lookups re-read the file.
  void clearCache() {
    _offlineCache = null;
  }

  // ─── Offline search (trigram) ─────────────────────────────────────────────

  Future<List<DrugLookupResult>> searchOffline(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final db = await _loadOfflineDb();
    final scoredResults = <(double, DrugLookupResult)>[];

    for (final drug in db) {
      final nameLower = drug.name.toLowerCase();
      final ingredientLower = drug.activeIngredient.toLowerCase();

      // Prefix match gets highest priority (very fast)
      if (nameLower.startsWith(q) || ingredientLower.startsWith(q)) {
        scoredResults.add((1.0, drug));
        continue;
      }

      // Contains match (medium priority)
      if (nameLower.contains(q) || ingredientLower.contains(q)) {
        scoredResults.add((0.85, drug));
        continue;
      }

      // Trigram fuzzy match (handles typos like parasetamol → paracetamol)
      final nameSim = _trigramSimilarity(q, nameLower);
      final ingredientSim = _trigramSimilarity(q, ingredientLower);
      final bestSim = max(nameSim, ingredientSim);

      if (bestSim >= 0.45) {
        scoredResults.add((bestSim, drug));
      }
    }

    // Sort by score descending, take top 12
    scoredResults.sort((a, b) => b.$1.compareTo(a.$1));
    return scoredResults.take(12).map((e) => e.$2).toList();
  }

  /// Computes trigram (3-char n-gram) Jaccard similarity between two strings.
  /// Returns 0.0 (no match) to 1.0 (identical).
  double _trigramSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    if (a == b) return 1.0;
    if (a.length < 3 || b.length < 3) {
      // For short strings, fall back to character overlap
      final setA = a.split('').toSet();
      final setB = b.split('').toSet();
      final intersection = setA.intersection(setB).length;
      final union = setA.union(setB).length;
      return union == 0 ? 0.0 : intersection / union;
    }

    final trigramsA = _trigrams(a);
    final trigramsB = _trigrams(b);
    final intersection = trigramsA.intersection(trigramsB).length;
    final union = trigramsA.union(trigramsB).length;
    return union == 0 ? 0.0 : intersection / union;
  }

  Set<String> _trigrams(String s) {
    final result = <String>{};
    for (var i = 0; i <= s.length - 3; i++) {
      result.add(s.substring(i, i + 3));
    }
    return result;
  }

  Future<List<DrugLookupResult>> _loadOfflineDb() async {
    if (_offlineCache != null) return _offlineCache!;

    String raw = '';
    final downloadedFile = await _catalogUpdater.getDownloadedCatalogFile();

    if (downloadedFile != null) {
      try {
        raw = await downloadedFile.readAsString();
      } catch (_) {}
    }

    if (raw.trim().isEmpty) {
      raw = await rootBundle.loadString('assets/data/indonesian_drugs.csv');
    }

    final rows = const CsvToListConverter(eol: '\n').convert(raw);

    // Skip header row
    _offlineCache = rows.skip(1).where((row) => row.length >= 5).map((row) {
      return DrugLookupResult(
        name: row[0].toString().trim(),
        activeIngredient: row[1].toString().trim(),
        category: row[2].toString().trim(),
        manufacturer: row[3].toString().trim(),
        unit: row[4].toString().trim(),
        source: DrugSource.offline,
      );
    }).toList();

    return _offlineCache!;
  }

  // ─── Live BPOM search ─────────────────────────────────────────────────────

  /// Attempts a live search against the BPOM public portal.
  /// Returns empty list gracefully if the network is unavailable.
  Future<List<DrugLookupResult>> searchBpom(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    try {
      // Primary: BPOM Satu Data API (when available)
      final results = await _bpomApiSearch(q);
      if (results.isNotEmpty) return results;
    } catch (_) {
      // Swallow — network unavailable or API changed
    }
    return [];
  }

  Future<List<DrugLookupResult>> _bpomApiSearch(String query) async {
    // BPOM does not expose an official public JSON API.
    // We attempt the Satu Data BPOM CKAN-compatible API endpoint.
    final uri = Uri.parse(
      'https://satudata.pom.go.id/api/3/action/datastore_search'
      '?resource_id=master-produk-obat&q=${Uri.encodeComponent(query)}&limit=10',
    );

    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'PharmacyInventoryApp/1.0 (satudata@pom.go.id contact)',
      },
    ).timeout(const Duration(seconds: 6));

    if (response.statusCode != 200) return [];

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final success = body['success'] as bool? ?? false;
    if (!success) return [];

    final records = (body['result']?['records'] as List<dynamic>?) ?? [];
    return records.map((r) {
      final m = r as Map<String, dynamic>;
      return DrugLookupResult(
        name: m['nama_produk'] as String? ?? m['name'] as String? ?? '',
        activeIngredient: m['komposisi'] as String? ?? '',
        category: _mapBpomCategory(m['jenis'] as String? ?? ''),
        manufacturer: m['nama_produsen'] as String? ?? '',
        unit: 'tablet',
        registrationNumber: m['nomor_registrasi'] as String? ?? '',
        source: DrugSource.bpom,
      );
    }).where((d) => d.name.isNotEmpty).toList();
  }

  String _mapBpomCategory(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('keras')) return 'Obat Keras';
    if (lower.contains('psikotropika')) return 'Psikotropika';
    if (lower.contains('narkotika')) return 'Narkotika';
    if (lower.contains('herbal') || lower.contains('jamu')) return 'Herbal / Jamu';
    if (lower.contains('bebas terbatas')) return 'Obat Bebas Terbatas';
    if (lower.contains('bebas')) return 'Obat Bebas';
    return raw.isNotEmpty ? raw : 'Obat Bebas';
  }

  // ─── Combined search ──────────────────────────────────────────────────────

  /// Searches offline database first (instant), then enriches with live BPOM
  /// results if network is available. Deduplicates by name.
  Future<List<DrugLookupResult>> search(String query) async {
    // Always run offline search (instant, no network required)
    final offlineResults = await searchOffline(query);

    // Try live BPOM search in parallel — results merged if available
    List<DrugLookupResult> bpomResults = [];
    try {
      bpomResults = await searchBpom(query).timeout(
        const Duration(seconds: 5),
        onTimeout: () => [],
      );
    } catch (_) {
      // Network unavailable — offline results are sufficient
    }

    // Merge: BPOM results first (authoritative), then offline not already present
    final seen = <String>{};
    final merged = <DrugLookupResult>[];

    for (final d in [...bpomResults, ...offlineResults]) {
      final key = d.name.toLowerCase().trim();
      if (seen.add(key)) merged.add(d);
    }

    return merged.take(15).toList();
  }
}
