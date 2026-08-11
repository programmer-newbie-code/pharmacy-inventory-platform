import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';

void main() {
  test('schema version 11 includes image_path, photo_path, and shift review metadata',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    expect(database.schemaVersion, 11);
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
    expect(tableNames, contains('cash_movements'));

    final productColumns =
        await database.customSelect('PRAGMA table_info(products)').get();
    expect(productColumns.map((row) => row.read<String>('name')),
        contains('image_path'));

    final userColumns =
        await database.customSelect('PRAGMA table_info(users)').get();
    expect(userColumns.map((row) => row.read<String>('name')),
        contains('photo_path'));
    final shiftColumns = await database.customSelect('PRAGMA table_info(cashier_shifts)').get();
    expect(shiftColumns.map((row) => row.read<String>('name')), containsAll(['reviewed_by', 'reviewed_at', 'review_note']));
  });
}
