import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:pharmacy_inventory_platform/data/drug_lookup_service.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DrugLookupResult properties and requiresPrescription check', () {
    final drug1 = DrugLookupResult(
      name: 'Amoxicillin 500mg',
      activeIngredient: 'Amoxicillin',
      category: 'Obat Keras',
      manufacturer: 'Kalbe',
      unit: 'kaplet',
    );

    expect(drug1.requiresPrescription, isTrue);
    expect(drug1.toString(), 'Amoxicillin 500mg (Obat Keras)');

    final drug2 = DrugLookupResult(
      name: 'Paracetamol 500mg',
      activeIngredient: 'Paracetamol',
      category: 'Obat Bebas',
      manufacturer: 'Sanbe',
      unit: 'tablet',
    );

    expect(drug2.requiresPrescription, isFalse);
    expect(drug2.source, DrugSource.offline);
  });

  test('DrugLookupService offline search with bundled asset', () async {
    final service = DrugLookupService();
    final results = await service.searchOffline('amox');
    expect(results, isNotEmpty);
    expect(results.first.name.toLowerCase(), contains('amox'));

    // Test clearCache
    service.clearCache();
  });

  test('DrugLookupService BPOM live search mock', () async {
    final mockClient = http_testing.MockClient((request) async {
      if (request.url.host.contains('satudata.pom.go.id')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'result': {
              'records': [
                {
                  'nama_produk': 'Sanmol Paracetamol',
                  'komposisi': 'Paracetamol 500mg',
                  'jenis': 'Obat Bebas',
                  'nama_produsen': 'Sanbe',
                  'nomor_registrasi': 'DBL12345',
                },
                {
                  'nama_produk': 'Cefadroxil Keras',
                  'komposisi': 'Cefadroxil 500mg',
                  'jenis': 'Obat Keras',
                  'nama_produsen': 'Dexa',
                  'nomor_registrasi': 'DKL54321',
                }
              ]
            }
          }),
          200,
        );
      }
      return http.Response('Not found', 404);
    });

    final service = DrugLookupService(client: mockClient);
    final results = await service.searchBpom('paracetamol');
    expect(results, hasLength(2));
    expect(results.first.name, 'Sanmol Paracetamol');
    expect(results.first.source, DrugSource.bpom);
    expect(results.last.category, 'Obat Keras');
  });

  test('DrugLookupService empty query returns empty list', () async {
    final service = DrugLookupService();
    final results = await service.searchOffline('   ');
    expect(results, isEmpty);

    final bpomResults = await service.searchBpom('   ');
    expect(bpomResults, isEmpty);
  });
}
