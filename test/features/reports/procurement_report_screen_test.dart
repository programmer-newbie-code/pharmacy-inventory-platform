import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/reports/procurement_report_screen.dart';

import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets(
      'renders ProcurementReportScreen with metric cards and supplier table',
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
    expect(find.text('Total pembelian'), findsOneWidget);
    expect(find.text('Pesanan pembelian'), findsOneWidget);
    expect(find.text('Batch diterima'), findsOneWidget);
    expect(find.text('Pembelian per pemasok'), findsOneWidget);
    expect(find.byKey(const Key('exportProcurementReportBtn')), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('exportProcurementReportBtn')),
          )
          .onPressed,
      isNull,
    );
  });
}
