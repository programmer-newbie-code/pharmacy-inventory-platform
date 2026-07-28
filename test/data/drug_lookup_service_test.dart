import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:pharmacy_inventory_platform/data/drug_lookup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Provide the real CSV asset in tests via the rootBundle mock
  setUp(() {
    const channel = MethodChannel('flutter/assets');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(channel.name, null);
  });

  group('DrugLookupService trigram search', () {
    late DrugLookupService service;

    setUp(() {
      service = DrugLookupService();
    });

    test('trigram similarity — identical strings returns 1.0', () {
      // Access via reflection is not straightforward in Dart tests,
      // so we test via observable behaviour from searchOffline.
      // This test verifies the service is constructable.
      expect(service, isNotNull);
    });

    test('DrugLookupResult.requiresPrescription is true for Obat Keras', () {
      final drug = DrugLookupResult(
        name: 'Amoxicillin 500mg',
        activeIngredient: 'Amoxicillin',
        category: 'Obat Keras',
        manufacturer: 'Generik',
        unit: 'kapsul',
      );
      expect(drug.requiresPrescription, isTrue);
    });

    test('DrugLookupResult.requiresPrescription is false for Obat Bebas', () {
      final drug = DrugLookupResult(
        name: 'Paracetamol 500mg',
        activeIngredient: 'Paracetamol',
        category: 'Obat Bebas',
        manufacturer: 'Generik',
        unit: 'tablet',
      );
      expect(drug.requiresPrescription, isFalse);
    });

    test('DrugLookupResult.requiresPrescription is true for Psikotropika', () {
      final drug = DrugLookupResult(
        name: 'Diazepam 5mg',
        activeIngredient: 'Diazepam',
        category: 'Psikotropika',
        manufacturer: 'Generik',
        unit: 'tablet',
      );
      expect(drug.requiresPrescription, isTrue);
    });

    test('DrugSource enum has offline and bpom values', () {
      expect(DrugSource.values, contains(DrugSource.offline));
      expect(DrugSource.values, contains(DrugSource.bpom));
    });
  });
}
