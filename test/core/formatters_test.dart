import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/formatters.dart';

void main() {
  test('formats rupiah without decimal fractions', () {
    expect(formatIdr(12500), 'Rp 12.500');
    expect(formatIdr(0), 'Rp 0');
  });
}
