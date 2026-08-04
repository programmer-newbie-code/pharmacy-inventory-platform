import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';

void main() {
  test('schema version 4 includes stock adjustments and import history',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    expect(database.schemaVersion, 4);
    final tables = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();

    expect(tables.map((row) => row.read<String>('name')),
        contains('stock_adjustments'));
    expect(tables.map((row) => row.read<String>('name')),
        contains('csv_import_logs'));
    final columns =
        await database.customSelect('PRAGMA table_info(cashier_shifts)').get();
    expect(columns.map((row) => row.read<String>('name')),
        contains('discrepancy_reason'));
  });
}
