import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/suppliers/supplier_list_screen.dart';

void main() {
  testWidgets('renders SupplierListScreen and adds a new supplier', (tester) async {
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
          home: SupplierListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Suppliers Directory'), findsOneWidget);
    expect(find.byKey(const Key('addSupplierBtn')), findsOneWidget);

    await tester.tap(find.byKey(const Key('addSupplierBtn')));
    await tester.pumpAndSettle();

    expect(find.text('Add New Supplier'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('supplierNameInput')), 'PT Kimia Farma');
    await tester.tap(find.byKey(const Key('confirmAddSupplierBtn')));
    await tester.pumpAndSettle();

    expect(find.text('PT Kimia Farma'), findsOneWidget);
  });
}
