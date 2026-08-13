import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/product_repository.dart';
import 'package:pharmacy_inventory_platform/features/inventory/product_list_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

import '../../support/layout_harness.dart';

// The longest name in the bundled catalog
// (assets/data/indonesian_drugs.csv) is 'Polymyxin B + Neomycin Tetes Mata'
// at 33 characters, so that is the realistic worst case for this app rather
// than an invented longer string.
const _longProductName = 'Polymyxin B + Neomycin Tetes Mata';

void main() {
  testWidgets('renders product list screen and opens add product dialog', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final productRepo = ProductRepository(db);
    await productRepo.createProduct(
      barcode: '8990000000001',
      internalCode: 'PCT-100',
      name: 'Paracetamol Syrup',
      activeIngredient: 'Paracetamol',
      ingredientPct: 100.0,
      baseUnit: 'botol',
      purchaseUnit: 'dus',
      unitsPerPurchaseUnit: 24,
      costPricePerBaseUnit: 12000.0,
      marginPct: 15.0,
      reorderThreshold: 10,
      category: 'Obat Bebas',
      createdBy: 'admin',
    );
    final product = (await productRepo.listProducts()).single;

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('id'),
          home: ProductListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Katalog Inventaris'), findsOneWidget);
    expect(find.text('Paracetamol Syrup'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addProductFab')));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Produk Baru'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('editProdBtn_${product.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Edit Detail Produk'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('addBatchBtn_${product.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Receive Stock: Paracetamol Syrup'), findsOneWidget);
  });

  testWidgets('debounces search and offers recovery from no results', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final productRepo = ProductRepository(db);
    await productRepo.createProduct(
      barcode: '8990000000001',
      internalCode: 'PCT-100',
      name: 'Paracetamol Syrup',
      activeIngredient: 'Paracetamol',
      ingredientPct: 100.0,
      baseUnit: 'botol',
      purchaseUnit: 'dus',
      unitsPerPurchaseUnit: 24,
      costPricePerBaseUnit: 12000.0,
      marginPct: 15.0,
      reorderThreshold: 10,
      category: 'Obat Bebas',
      createdBy: 'admin',
    );
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('id'),
          home: ProductListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('productSearchInput')), 'xyz');
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Paracetamol Syrup'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada produk untuk "xyz".'), findsOneWidget);
    expect(find.byKey(const Key('clearSearchEmptyStateBtn')), findsOneWidget);
    await tester.tap(find.byKey(const Key('clearSearchEmptyStateBtn')));
    await tester.pumpAndSettle();
    expect(find.text('Paracetamol Syrup'), findsOneWidget);
  });

  testWidgets(
      'a long controlled-drug name wraps instead of truncating on the owner phone',
      (tester) async {
    useSurface(tester, kOwnerPhone);

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final productRepo = ProductRepository(db);
    // Long enough to have needed ~175dp+ against the ~179dp the row used to
    // leave once the 'Obat Keras' badge and edit icon took their share.
    await productRepo.createProduct(
      barcode: '8990000000099',
      internalCode: 'AMX-500',
      name: _longProductName,
      activeIngredient: 'Amoxicillin',
      ingredientPct: 100.0,
      baseUnit: 'kapsul',
      purchaseUnit: 'strip',
      unitsPerPurchaseUnit: 10,
      costPricePerBaseUnit: 1500.0,
      marginPct: 20.0,
      reorderThreshold: 20,
      isControlled: true,
      category: 'Obat Keras',
      createdBy: 'admin',
    );

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProductListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expectNoOverflow(tester);

    final nameFinder = find.text(_longProductName);
    expect(nameFinder, findsOneWidget);
    expectNotTruncated(tester, nameFinder);
  });

  testWidgets('survives 2.0 text scale with a long name on the owner phone',
      (tester) async {
    useSurface(tester, kOwnerPhone);

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final productRepo = ProductRepository(db);
    await productRepo.createProduct(
      barcode: '8990000000098',
      internalCode: 'AMX-501',
      name: _longProductName,
      activeIngredient: 'Amoxicillin',
      ingredientPct: 100.0,
      baseUnit: 'kapsul',
      purchaseUnit: 'strip',
      unitsPerPurchaseUnit: 10,
      costPricePerBaseUnit: 1500.0,
      marginPct: 20.0,
      reorderThreshold: 20,
      isControlled: true,
      category: 'Obat Keras',
      createdBy: 'admin',
    );

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: textScaleBuilder(2.0),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProductListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expectNoOverflow(tester);
  });
}
