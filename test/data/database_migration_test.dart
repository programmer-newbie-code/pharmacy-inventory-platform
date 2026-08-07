import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';

void main() {
  test('schema version 7 includes compounding tables, patients, and prescriptions',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    expect(database.schemaVersion, 7);
    final tables = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();

    final tableNames = tables.map((row) => row.read<String>('name')).toList();

    expect(tableNames, contains('stock_adjustments'));
    expect(tableNames, contains('csv_import_logs'));
    expect(tableNames, contains('purchase_receiving_items'));
    expect(tableNames, contains('patients'));
    expect(tableNames, contains('prescriptions'));
    expect(tableNames, contains('compounding_formulas'));
    expect(tableNames, contains('compounding_ingredients'));
    expect(tableNames, contains('compounding_transactions'));
    expect(tableNames, contains('compounding_transaction_items'));
  });
}
