import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/inventory/add_product_dialog.dart';

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
          home: Scaffold(
            body: AddProductDialog(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Add New Product'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('productNameInput')), 'Ibuprofen 400mg');
    await tester.enterText(find.byKey(const Key('productBarcodeInput')), '8998888777666');
    await tester.enterText(find.byKey(const Key('productInternalCodeInput')), 'IBU-400');
    await tester.enterText(find.byKey(const Key('activeIngredientInput')), 'Ibuprofen');
    await tester.tap(find.byKey(const Key('isControlledCheckbox')));

    await tester.tap(find.byKey(const Key('saveProductButton')));
    await tester.pumpAndSettle();

    final productRepo = container.read(productRepositoryProvider);
    final products = await productRepo.listProducts();
    expect(products, hasLength(1));
    expect(products.first.name, equals('Ibuprofen 400mg'));
    expect(products.first.isControlled, isTrue);
  });
}
