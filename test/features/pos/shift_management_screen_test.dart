import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/pos/shift_management_screen.dart';

void main() {
  testWidgets('renders ShiftManagementScreen and opens shift', (tester) async {
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
          home: ShiftManagementScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Cash Shift Reconciliation'), findsOneWidget);
    expect(find.byKey(const Key('openShiftBtn')), findsOneWidget);

    await tester.tap(find.byKey(const Key('openShiftBtn')));
    await tester.pumpAndSettle();

    expect(find.text('Open Cashier Shift'), findsOneWidget);
    expect(find.byKey(const Key('confirmOpenShiftBtn')), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirmOpenShiftBtn')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Shift Active (Open)'), findsOneWidget);
    expect(find.byKey(const Key('closeShiftBtn')), findsOneWidget);

    await tester.tap(find.byKey(const Key('closeShiftBtn')));
    await tester.pumpAndSettle();

    expect(find.text('Close Shift & Reconcile Cash'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('actualCashInput')), '100000');
    await tester.tap(find.byKey(const Key('confirmCloseShiftBtn')));
    await tester.pumpAndSettle();

    expect(find.textContaining('No Active Shift'), findsOneWidget);
    expect(find.textContaining('BALANCED'), findsOneWidget);
  });
}
