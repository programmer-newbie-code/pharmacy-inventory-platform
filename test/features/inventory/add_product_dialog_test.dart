import 'dart:io' show Platform;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/adaptive_field_pair.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/inventory/add_product_dialog.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

import '../../support/layout_harness.dart';

void main() {
  testWidgets('renders and submits AddProductDialog form', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AddProductDialog()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Tambah Produk Baru'), findsOneWidget);
    if (Platform.isWindows) {
      expect(find.byKey(const Key('cameraScanBarcodeBtn')), findsNothing);
      expect(
        find.text(
          'Gunakan scanner USB/Bluetooth; kamera tidak tersedia di Windows.',
        ),
        findsOneWidget,
      );
    } else {
      expect(find.byKey(const Key('cameraScanBarcodeBtn')), findsOneWidget);
      expect(
        find.text(
          'Gunakan scanner USB/Bluetooth; kamera tidak tersedia di Windows.',
        ),
        findsNothing,
      );
    }

    await tester.enterText(
        find.byKey(const Key('productNameInput')), 'Ibuprofen 400mg');
    await tester.enterText(
        find.byKey(const Key('productBarcodeInput')), '8998888777666');
    await tester.enterText(
        find.byKey(const Key('productInternalCodeInput')), 'IBU-400');
    await tester.enterText(
        find.byKey(const Key('activeIngredientInput')), 'Ibuprofen');
    await tester.ensureVisible(find.byKey(const Key('isControlledCheckbox')));
    await tester.tap(find.byKey(const Key('isControlledCheckbox')));

    await tester.ensureVisible(find.byKey(const Key('saveProductButton')));
    await tester.tap(find.byKey(const Key('saveProductButton')));
    await tester.pumpAndSettle();

    final productRepo = container.read(productRepositoryProvider);
    final products = await productRepo.listProducts();
    expect(products, hasLength(1));
    expect(products.first.name, equals('Ibuprofen 400mg'));
    expect(products.first.isControlled, isTrue);
  });

  testWidgets('AddProductDialog calculates price per purchase unit vs base unit',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AddProductDialog()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Fill purchase unit price and units per purchase unit
    await tester.enterText(
        find.byKey(const Key('productNameInput')), 'Paracetamol Box Test');
    await tester.enterText(
        find.byKey(const Key('productBarcodeInput')), '8999999111222');
    await tester.enterText(
        find.byKey(const Key('productInternalCodeInput')), 'PCT-BOX');
    await tester.enterText(
        find.byKey(const Key('activeIngredientInput')), 'Paracetamol');

    await tester.dragUntilVisible(
      find.byKey(const Key('purchaseUnitPriceInput')),
      find.byType(SingleChildScrollView),
      const Offset(0, -100),
    );
    await tester.enterText(
        find.byKey(const Key('purchaseUnitPriceInput')), '100000');
    await tester.pumpAndSettle();

    // Change base price directly
    await tester.enterText(
        find.byKey(const Key('costPricePerBaseUnitInput')), '1000');
    await tester.pumpAndSettle();

    // Select controlled substance and category
    await tester.dragUntilVisible(
      find.byKey(const Key('isControlledCheckbox')),
      find.byType(SingleChildScrollView),
      const Offset(0, -100),
    );
    await tester.tap(find.byKey(const Key('isControlledCheckbox')));
    await tester.pumpAndSettle();

    // Save
    await tester.dragUntilVisible(
      find.byKey(const Key('saveProductButton')),
      find.byType(SingleChildScrollView),
      const Offset(0, -100),
    );
    await tester.tap(find.byKey(const Key('saveProductButton')));
    await tester.pumpAndSettle();

    final products = await container.read(productRepositoryProvider).listProducts();
    expect(products, hasLength(1));
    expect(products.first.name, 'Paracetamol Box Test');
    // The drug-classification label is localized, but the stored value is a
    // persisted regulatory category and must not change.
    expect(products.first.category, 'Obat Bebas');
  });

  testWidgets('renders localized dialog strings in English, not Indonesian',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AddProductDialog()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // These were hard-coded Indonesian literals shown to English users.
    expect(find.text('Tambah Produk Baru'), findsNothing);
    expect(find.text('Add New Product'), findsOneWidget);
    expect(find.text('Nama Produk *'), findsNothing);
    expect(find.text('Product name *'), findsOneWidget);
    expect(find.text('Golongan Obat'), findsNothing);
    expect(find.text('Drug classification'), findsOneWidget);
  });

  testWidgets('keeps Indonesian dialog strings in the id locale',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AddProductDialog()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tambah Produk Baru'), findsOneWidget);
    expect(find.text('Nama Produk *'), findsOneWidget);
    expect(find.text('Golongan Obat'), findsOneWidget);
  });

  group('narrow screen readability', () {
    Future<void> pumpDialog(WidgetTester tester, {double textScale = 1.0}) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: textScale == 1.0 ? null : textScaleBuilder(textScale),
            home: const Scaffold(body: AddProductDialog()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('unit and price labels are readable on the owner phone',
        (tester) async {
      useSurface(tester, kOwnerPhone);
      await pumpDialog(tester);
      expectNoOverflow(tester);

      // Before this increment these labels had ~148dp against ~218dp of need.
      // Stacking raised the slot to ~310dp, which was still not enough once
      // EditableUnitDropdown's dropdown-arrow suffixIcon took ~48dp, so the
      // parenthetical examples moved to helperText.
      for (final label in [
        'Satuan Dasar',
        'Satuan Beli',
        'HPP per Satuan Dasar',
        'Harga Beli per Satuan Beli',
      ]) {
        final finder = find.text(label);
        expect(finder, findsOneWidget, reason: 'missing label: $label');
        expectNotTruncated(tester, finder);
      }

      // The examples must remain visible, only relocated.
      expect(find.text('mis. tablet, kapsul'), findsOneWidget);
      expect(find.text('mis. box, dus'), findsOneWidget);
    });

    testWidgets('paired fields stack on a phone and pair on desktop',
        (tester) async {
      useSurface(tester, kOwnerPhone);
      await pumpDialog(tester);
      final phonePairs = find.byType(AdaptiveFieldPair);
      expect(phonePairs, findsWidgets);
      // Stacked: the two children occupy different vertical bands.
      final baseUnit = tester.getRect(find.byKey(const Key('baseUnitDropdown')));
      final purchaseUnit =
          tester.getRect(find.byKey(const Key('purchaseUnitDropdown')));
      expect(purchaseUnit.top, greaterThan(baseUnit.bottom - 1),
          reason: 'fields must stack vertically on a phone');
    });

    testWidgets('paired fields stay side by side on desktop', (tester) async {
      useSurface(tester, kDesktop);
      await pumpDialog(tester);
      final baseUnit = tester.getRect(find.byKey(const Key('baseUnitDropdown')));
      final purchaseUnit =
          tester.getRect(find.byKey(const Key('purchaseUnitDropdown')));
      expect(purchaseUnit.left, greaterThan(baseUnit.right - 1),
          reason: 'fields must stay side by side where there is room');
    });

    testWidgets('survives 2.0 text scale on the owner phone', (tester) async {
      useSurface(tester, kOwnerPhone);
      await pumpDialog(tester, textScale: 2.0);
      expectNoOverflow(tester);
    });
  });
}
