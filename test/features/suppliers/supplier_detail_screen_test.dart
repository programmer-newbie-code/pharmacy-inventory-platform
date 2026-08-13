import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/supplier_repository.dart';
import 'package:pharmacy_inventory_platform/features/suppliers/supplier_detail_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets('renders SupplierDetailScreen, edits details, and toggles active status',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final supplierRepo = SupplierRepository(db);
    final supplier = await supplierRepo.createSupplier(
      name: 'PT Kalbe Farma',
      contactPerson: 'Budi',
      phone: '081234567890',
      email: 'budi@kalbe.co.id',
      address: 'Jakarta',
      paymentTerms: 'Net 30',
      leadTimeDays: 7,
    );

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SupplierDetailScreen(supplierId: supplier.id),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify detail elements
    expect(find.text('PT Kalbe Farma'), findsNWidgets(2));
    expect(find.textContaining('Budi'), findsOneWidget);
    expect(find.textContaining('081234567890'), findsOneWidget);
    expect(find.textContaining('Net 30'), findsOneWidget);
    expect(find.textContaining('7 days'), findsOneWidget);

    // Tap edit button
    await tester.tap(find.byKey(const Key('editSupplierBtn')));
    await tester.pumpAndSettle();

    // Edit fields
    await tester.enterText(
        find.widgetWithText(TextField, 'Supplier Name *'), 'PT Kalbe Tbk');
    await tester.tap(find.byKey(const Key('saveSupplierBtn')));
    await tester.pumpAndSettle();

    expect(find.text('PT Kalbe Tbk'), findsNWidgets(2));

    // Deactivate supplier
    await tester.tap(find.byKey(const Key('toggleActiveBtn')));
    await tester.pumpAndSettle();

    expect(find.text('Inactive'), findsOneWidget);
  });
}
