import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/compounding/formula_list_screen.dart';

void main() {
  testWidgets('renders FormulaListScreen and shows empty state / search',
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
    expect(find.text('No compounding formulas created yet.'), findsOneWidget);
    expect(find.byKey(const Key('addFirstFormulaBtn')), findsOneWidget);

    // Insert a formula and refresh
    await db.into(db.compoundingFormulas).insert(
          CompoundingFormulasCompanion.insert(
            id: const Value(1),
            name: 'Salep 2-4 Gatal',
            dosageForm: 'salep',
            yieldQuantity: 10,
            yieldUnit: 'pot',
          ),
        );

    container.invalidate(formulaListFutureProvider);
    await tester.pumpAndSettle();

    expect(find.text('Salep 2-4 Gatal'), findsOneWidget);

    // Test search filter
    await tester.enterText(find.byKey(const Key('formulaSearchInput')), 'Pulveres');
    await tester.pumpAndSettle();

    expect(find.text('No formulas match your search.'), findsOneWidget);
  });
}
