import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pharmacy_inventory_platform/data/openfda_drug_service.dart';

void main() {
  test('searchOnlineDrugs returns parsed OpenFdaDrugItem list on 200 OK', () async {
    final mockClient = MockClient((request) async {
      return http.Response(
        '''{
          "results": [
            {
              "brand_name": "Paracetamol Extra",
              "generic_name": "Paracetamol",
              "product_ndc": "555-1234",
              "dosage_form_name": "TABLET",
              "active_ingredients": [{"name": "Paracetamol", "strength": "500 mg"}]
            }
          ]
        }''',
        200,
      );
    });

    final service = OpenFdaDrugService(client: mockClient);
    final results = await service.searchOnlineDrugs('paracetamol');

    expect(results.length, 1);
    expect(results.first.brandName, 'Paracetamol Extra');
    expect(results.first.genericName, 'Paracetamol');
    expect(results.first.activeIngredient, contains('Paracetamol 500 mg'));
    expect(results.first.ndc, '555-1234');
  });

  test('searchOnlineDrugs returns empty list when query is empty or 404', () async {
    final mockClient = MockClient((request) async {
      return http.Response('{"error": "not_found"}', 404);
    });

    final service = OpenFdaDrugService(client: mockClient);
    final results = await service.searchOnlineDrugs('nonexistentdrug12345');
    expect(results, isEmpty);
  });
}
