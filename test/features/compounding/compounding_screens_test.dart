import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/compounding/formula_list_screen.dart';

void main() {
  testWidgets('renders FormulaListScreen and opens editor dialog',
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
          home: FormulaListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Compounding Formulas (Racikan)'), findsOneWidget);
    expect(find.byKey(const Key('addFormulaBtn')), findsOneWidget);

    await tester.tap(find.byKey(const Key('addFormulaBtn')));
    await tester.pumpAndSettle();

    expect(find.text('New Compounding Formula'), findsOneWidget);
  });
}
