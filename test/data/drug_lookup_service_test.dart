import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/drug_lookup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DrugLookupService', () {
    late DrugLookupService service;

    setUp(() {
      service = DrugLookupService();
    });

    test('searchOffline returns empty list for empty query', () async {
      final results = await service.searchOffline('');
      expect(results, isEmpty);
    });

    test('searchBpom returns empty list for empty query', () async {
      final results = await service.searchBpom('');
      expect(results, isEmpty);
    });

    test('search returns offline results for valid query', () async {
      final results = await service.search('paracetamol');
      expect(results, isNotEmpty);
      expect(results.first.name.toLowerCase(), contains('paracetamol'));
    });

    test('DrugLookupResult toString formatting', () {
      final drug = DrugLookupResult(
        name: 'Paracetamol 500mg',
        activeIngredient: 'Paracetamol',
        category: 'Obat Bebas',
        manufacturer: 'Generik',
        unit: 'tablet',
      );
      expect(drug.toString(), equals('Paracetamol 500mg (Obat Bebas)'));
    });

    test('DrugLookupResult.requiresPrescription is true for Obat Keras & Psikotropika', () {
      final drugKeras = DrugLookupResult(
        name: 'Amoxicillin 500mg',
        activeIngredient: 'Amoxicillin',
        category: 'Obat Keras',
        manufacturer: 'Generik',
        unit: 'kapsul',
      );
      expect(drugKeras.requiresPrescription, isTrue);

      final drugBebas = DrugLookupResult(
        name: 'Paracetamol 500mg',
        activeIngredient: 'Paracetamol',
        category: 'Obat Bebas',
        manufacturer: 'Generik',
        unit: 'tablet',
      );
      expect(drugBebas.requiresPrescription, isFalse);

      final drugPsiko = DrugLookupResult(
        name: 'Diazepam 5mg',
        activeIngredient: 'Diazepam',
        category: 'Psikotropika',
        manufacturer: 'Generik',
        unit: 'tablet',
      );
      expect(drugPsiko.requiresPrescription, isTrue);
    });

    test('DrugSource enum has offline and bpom values', () {
      expect(DrugSource.values, contains(DrugSource.offline));
      expect(DrugSource.values, contains(DrugSource.bpom));
    });
  });
}
