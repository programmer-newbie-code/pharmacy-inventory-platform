import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result from a BPOM (Badan Pengawas Obat dan Makanan) drug search.
class BpomDrugItem {
  BpomDrugItem({
    required this.name,
    required this.registrationNumber,
    required this.manufacturer,
    required this.category,
    required this.activeIngredient,
  });

  final String name;
  final String registrationNumber;
  final String manufacturer;
  final String category;
  final String activeIngredient;

  factory BpomDrugItem.fromJson(Map<String, dynamic> json) {
    return BpomDrugItem(
      name: json['nama_produk'] as String? ?? json['nama'] as String? ?? '',
      registrationNumber: json['nomor_registrasi'] as String? ?? json['reg_number'] as String? ?? '',
      manufacturer: json['nama_produsen'] as String? ?? json['produsen'] as String? ?? '',
      category: json['jenis'] as String? ?? json['kategori'] as String? ?? 'Obat Bebas',
      activeIngredient: json['komposisi'] as String? ?? json['zat_aktif'] as String? ?? '',
    );
  }

  /// Maps BPOM drug category codes to Indonesian pharmacy category names.
  static String mapCategory(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('keras') || lower.contains('k')) return 'Obat Keras';
    if (lower.contains('psikotropika')) return 'Psikotropika';
    if (lower.contains('narkotika')) return 'Narkotika';
    if (lower.contains('herbal') || lower.contains('jamu')) return 'Herbal / Jamu';
    if (lower.contains('bebas terbatas') || lower.contains('bt')) return 'Obat Bebas Terbatas';
    return 'Obat Bebas';
  }

  String get categoryFormatted => mapCategory(category);
  bool get requiresPrescription =>
      categoryFormatted == 'Obat Keras' ||
      categoryFormatted == 'Psikotropika' ||
      categoryFormatted == 'Narkotika';
}

/// Queries the BPOM public API for Indonesian registered drug products.
///
/// Primary endpoint: https://api.pom.go.id/v1/produk
/// Fallback: https://cekbpom.pom.go.id/home/produk/{keyword}
class BpomDrugService {
  BpomDrugService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://api.pom.go.id/v1';
  static const _fallbackUrl = 'https://cekbpom.pom.go.id';

  /// Searches BPOM for drugs matching [query] (by name or Nomor Registrasi).
  Future<List<BpomDrugItem>> searchDrugs(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    // Try primary BPOM API first
    try {
      final results = await _searchViaApi(q);
      if (results.isNotEmpty) return results;
    } catch (_) {
      // Fall through to fallback
    }

    // Try fallback endpoint
    try {
      return await _searchViaFallback(q);
    } catch (_) {
      return [];
    }
  }

  Future<List<BpomDrugItem>> _searchViaApi(String query) async {
    final uri = Uri.parse('$_baseUrl/produk?search=${Uri.encodeComponent(query)}&limit=10');
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'PharmacyInventoryApp/1.0',
      },
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);
    final results = data['data'] as List<dynamic>? ?? data['results'] as List<dynamic>? ?? [];
    return results.map((e) => BpomDrugItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<BpomDrugItem>> _searchViaFallback(String query) async {
    final uri = Uri.parse('$_fallbackUrl/home/produk/${Uri.encodeComponent(query)}');
    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'PharmacyInventoryApp/1.0',
      },
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return [];

    // Parse JSON response if available
    try {
      final data = jsonDecode(response.body);
      final list = data is List
          ? data
          : data['data'] as List<dynamic>? ?? [];
      return list.map((e) => BpomDrugItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
