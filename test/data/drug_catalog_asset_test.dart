import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled Indonesian drug catalog has a valid lookup schema', () async {
    final file = File('assets/data/indonesian_drugs.csv');
    expect(file.existsSync(), isTrue);

    final csvContent = (await file.readAsString()).replaceAll('\r\n', '\n');
    final rows = const CsvToListConverter().convert(csvContent, eol: '\n');
    expect(rows, isNotEmpty);
    expect(rows.first, <Object?>[
      'name',
      'active_ingredient',
      'category',
      'manufacturer',
      'unit',
    ]);
    expect(rows.length, greaterThan(400));

    final identities = <String>{};
    for (final row in rows.skip(1)) {
      expect(row, hasLength(5));
      final values = row.map((value) => value.toString().trim()).toList();
      expect(values.every((value) => value.isNotEmpty), isTrue);
      expect(
        identities.add('${values[0]}|${values[1]}|${values[4]}'),
        isTrue,
        reason: 'duplicate catalog identity: ${values[0]}',
      );
    }
  });
}
