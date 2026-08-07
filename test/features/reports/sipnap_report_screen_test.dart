import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/sipnap_export_service.dart';
import 'package:pharmacy_inventory_platform/features/reports/sipnap_report_screen.dart';

void main() {
  testWidgets('renders SipnapReportScreen, displays data, and triggers export',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // Insert controlled drug product
    await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: const Value(20),
            barcode: '8999990001',
            internalCode: 'NAR-01',
            name: 'Codeine 10mg',
            activeIngredient: 'Codeine Phosphate',
            ingredientPct: 100,
            baseUnit: 'tablet',
            purchaseUnit: 'box',
            unitsPerPurchaseUnit: 100,
            costPricePerBaseUnit: 1000,
            marginPct: 30,
            reorderThreshold: 50,
            isControlled: const Value(true),
            controlledCategory: const Value('Narkotika'),
            category: 'Narcotic',
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
          home: SipnapReportScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('SIPNAP Monthly Report (Kemenkes RI)'), findsOneWidget);
    expect(find.text('Codeine 10mg'), findsOneWidget);
    expect(find.text('Narkotika'), findsOneWidget);

    // Refresh report
    await tester.tap(find.byKey(const Key('refreshSipnapReportBtn')));
    await tester.pumpAndSettle();

    // Export Excel
    await tester.tap(find.byKey(const Key('exportSipnapExcelBtn')));
    await tester.pumpAndSettle();

    expect(find.text('SIPNAP Excel report generated!'), findsOneWidget);
  });
}
