import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/reports/cash_movement_report_screen.dart';

import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets(
      'renders CashMovementReportScreen with metric cards and movements list',
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
          home: CashMovementReportScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Laporan Arus Kas & Prive Owner'), findsOneWidget);
    expect(find.text('AMBIL UNTUNG OWNER (PRIVE)'), findsOneWidget);
    expect(find.text('TOTAL TARIK KAS (OUT)'), findsOneWidget);
    expect(find.text('TOTAL TAMBAH KAS (IN)'), findsOneWidget);
    expect(find.text('Riwayat Mutasi Arus Kas'), findsOneWidget);
    expect(
      find.byKey(const Key('exportCashMovementReportBtn')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('exportCashMovementReportBtn')),
          )
          .onPressed,
      isNull,
    );
  });
}
