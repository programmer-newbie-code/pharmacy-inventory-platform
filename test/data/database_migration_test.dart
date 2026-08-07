import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';

void main() {
  test('schema version 5 includes stock adjustments, import history, and purchase receiving items',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    expect(database.schemaVersion, 5);
    final tables = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();

    expect(tables.map((row) => row.read<String>('name')),
        contains('stock_adjustments'));
    expect(tables.map((row) => row.read<String>('name')),
        contains('csv_import_logs'));
    expect(tables.map((row) => row.read<String>('name')),
        contains('purchase_receiving_items'));

    final cashierShiftColumns =
        await database.customSelect('PRAGMA table_info(cashier_shifts)').get();
    expect(cashierShiftColumns.map((row) => row.read<String>('name')),
        contains('discrepancy_reason'));

    final supplierColumns =
        await database.customSelect('PRAGMA table_info(suppliers)').get();
    expect(supplierColumns.map((row) => row.read<String>('name')),
        contains('payment_terms'));
    expect(supplierColumns.map((row) => row.read<String>('name')),
        contains('lead_time_days'));
    expect(supplierColumns.map((row) => row.read<String>('name')),
        contains('is_active'));
  });
}
