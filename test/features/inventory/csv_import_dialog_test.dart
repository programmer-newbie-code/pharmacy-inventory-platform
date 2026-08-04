import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/inventory/csv_import_dialog.dart';
import 'package:pharmacy_inventory_platform/features/inventory/csv_import_history_dialog.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

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
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
    expect(find.textContaining('Paracetamol'), findsOneWidget);
    expect(find.byKey(const Key('confirmCsvImportBtn')), findsOneWidget);
  });

  testWidgets('uses localized CSV workflow labels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: CsvImportDialog()),
      ),
    );

    expect(find.text('Import Inventory CSV'), findsOneWidget);
    expect(find.text('Choose CSV file'), findsOneWidget);
  });

  testWidgets('renders newest import history with source and user',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.csvImportLogs).insert(
          CsvImportLogsCompanion.insert(
            sourceName: 'stock-take.csv',
            createdBy: 'davit',
            totalRows: 3,
            importedRows: 2,
            rejectedRows: 1,
            status: 'success',
          ),
        );
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CsvImportHistoryDialog()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CSV import history'), findsOneWidget);
    expect(find.text('stock-take.csv'), findsOneWidget);
    expect(find.textContaining('davit'), findsOneWidget);
    expect(find.textContaining('2 imported'), findsOneWidget);
  });
}
