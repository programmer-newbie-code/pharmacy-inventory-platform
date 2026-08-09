import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/reports/procurement_report_screen.dart';

import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets('renders ProcurementReportScreen with metric cards and supplier table',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('id'),
          home: ProcurementReportScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Laporan Pembelian & Stok (Procurement)'), findsOneWidget);
    expect(find.text('TOTAL PURCHASES'), findsOneWidget);
    expect(find.text('PURCHASE ORDERS'), findsOneWidget);
    expect(find.text('BATCHES RECEIVED'), findsOneWidget);
    expect(find.text('Purchases by Supplier'), findsOneWidget);
  });
}
