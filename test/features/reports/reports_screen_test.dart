import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/reports/reports_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('renders ReportsScreen and exports Excel report on button tap',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('id'),
          home: ReportsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Laporan Penjualan & Keuangan'), findsOneWidget);
    expect(find.text('Ringkasan Bulan Ini'), findsOneWidget);
    expect(find.byKey(const Key('exportExcelBtn')), findsOneWidget);

    await tester.dragUntilVisible(
      find.byKey(const Key('exportExcelBtn')),
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    await tester.tap(find.byKey(const Key('exportExcelBtn')));
    await tester.pump();

    expect(find.text('Mengekspor laporan...'), findsOneWidget);
    expect(find.textContaining('Export error:'), findsNothing);
  });
}
