import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/inventory/csv_import_dialog.dart';

void main() {
  testWidgets('previews a selected CSV before enabling import', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: CsvImportDialog(
              pickCsvText: () async =>
                  'Barcode,InternalCode,ProductName\n899123456701,P001,Paracetamol',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Pilih file CSV'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chooseCsvFileBtn')));
    await tester.pumpAndSettle();

    expect(find.text('1 valid, 0 dilewati'), findsOneWidget);
    expect(find.text('Paracetamol'), findsOneWidget);
    expect(find.byKey(const Key('confirmCsvImportBtn')), findsOneWidget);
  });
}
