import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFdaDrugItem {
  OpenFdaDrugItem({
    required this.brandName,
    required this.genericName,
    required this.activeIngredient,
    required this.ndc,
    required this.dosageForm,
  });

  final String brandName;
  final String genericName;
  final String activeIngredient;
  final String ndc;
  final String dosageForm;

  factory OpenFdaDrugItem.fromJson(Map<String, dynamic> json) {
    final activeIngredients = json['active_ingredients'] as List<dynamic>?;
    String ingredientStr = '';
    if (activeIngredients != null && activeIngredients.isNotEmpty) {
      ingredientStr = activeIngredients
          .map((i) => '${i["name"] ?? ""} ${i["strength"] ?? ""}')
          .join(', ');
    }

    return OpenFdaDrugItem(
      brandName: json['brand_name'] ?? json['generic_name'] ?? 'Unknown Drug',
      genericName: json['generic_name'] ?? '',
      activeIngredient: ingredientStr.isNotEmpty ? ingredientStr : (json['generic_name'] ?? ''),
      ndc: json['product_ndc'] ?? '',
      dosageForm: json['dosage_form_name'] ?? 'tablet',
    );
  }
}

class OpenFdaDrugService {
  OpenFdaDrugService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Searches OpenFDA national drug database for matching brand/generic names.
  Future<List<OpenFdaDrugItem>> searchOnlineDrugs(String query) async {
    final cleanQuery = Uri.encodeComponent(query.trim());
    if (cleanQuery.isEmpty) return [];

    final url = Uri.parse(
        'https://api.fda.gov/drug/ndc.json?search=brand_name:"$cleanQuery"+generic_name:"$cleanQuery"&limit=10');

    try {
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>?;
        if (results == null) return [];
        return results.map((item) => OpenFdaDrugItem.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
