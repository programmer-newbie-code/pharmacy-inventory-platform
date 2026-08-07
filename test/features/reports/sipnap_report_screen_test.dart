import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/reports/sipnap_report_screen.dart';

void main() {
  testWidgets('renders SipnapReportScreen and exports Excel on button tap',
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
          home: SipnapReportScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('SIPNAP Monthly Report (Kemenkes RI)'), findsOneWidget);
    expect(find.byKey(const Key('exportSipnapExcelBtn')), findsOneWidget);
  });
}
