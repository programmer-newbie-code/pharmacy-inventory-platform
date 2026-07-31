import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pharmacy_inventory_platform/core/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id');
    await initializeDateFormatting('en');
  });

  group('formatLocalDate', () {
    test('formats date in Indonesian locale', () {
      final date = DateTime(2026, 7, 31);
      expect(formatLocalDate(date), '31 Juli 2026');
    });

    test('formats date in English locale', () {
      final date = DateTime(2026, 7, 31);
      expect(formatLocalDate(date, 'en'), 'July 31, 2026');
    });
  });
}
