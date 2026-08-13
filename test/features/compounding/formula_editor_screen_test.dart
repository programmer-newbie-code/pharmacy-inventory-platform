import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/compounding/formula_editor_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets('renders FormulaEditorScreen, adds ingredient, and saves formula',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: const Value(1),
            barcode: '899123',
            internalCode: 'P-001',
            name: 'Paracetamol 500mg',
            activeIngredient: 'Paracetamol',
            ingredientPct: 100,
            baseUnit: 'tablet',
            purchaseUnit: 'box',
            unitsPerPurchaseUnit: 100,
            costPricePerBaseUnit: 200,
            marginPct: 20,
            reorderThreshold: 10,
            category: 'Analgesik',
            createdBy: 'admin',
          ),
        );

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
          home: FormulaEditorScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('New Compounding Formula'), findsOneWidget);

    // Enter formula name
    await tester.enterText(find.byType(TextField).first, 'Puyer Demam Anak');
    await tester.pumpAndSettle();

    // Select ingredient product from DropdownButtonFormField
    await tester.tap(find.byType(DropdownButtonFormField<Product>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paracetamol 500mg (tablet)').last);
    await tester.pumpAndSettle();

    expect(find.text('Ingredients'), findsOneWidget);

    // Save formula
    await tester.tap(find.byKey(const Key('saveFormulaBtn')));
    await tester.pumpAndSettle();

    final formulas = await container.read(compoundingRepositoryProvider).listFormulas();
    expect(formulas, hasLength(1));
    expect(formulas.first.name, 'Puyer Demam Anak');
  });
}
