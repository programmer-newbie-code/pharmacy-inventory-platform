import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/domain/unit_conversion.dart';

void main() {
  test('converts purchase-unit quantity to base-unit quantity', () {
    final result = convertToBaseUnit(
      quantityInPurchaseUnit: 3,
      unitsPerPurchaseUnit: 10,
    );
    expect(result, 30);
  });

  test('throws when unitsPerPurchaseUnit is zero or negative', () {
    expect(
      () => convertToBaseUnit(quantityInPurchaseUnit: 1, unitsPerPurchaseUnit: 0),
      throwsArgumentError,
    );
    expect(
      () => convertToBaseUnit(quantityInPurchaseUnit: 1, unitsPerPurchaseUnit: -5),
      throwsArgumentError,
    );
  });
}
