import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/unit_constants.dart';

void main() {
  test('getCombinedUnits combines default and custom units', () {
    customUserUnits.clear();
    final combined = getCombinedUnits(defaultBaseUnits);
    expect(combined.contains('tablet'), isTrue);

    customUserUnits.add('botol_khusus');
    final combined2 = getCombinedUnits(defaultBaseUnits);
    expect(combined2.contains('botol_khusus'), isTrue);
  });

  testWidgets('renders EditableUnitDropdown and selects from popup menu',
      (tester) async {
    final controller = TextEditingController();
    String? changedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditableUnitDropdown(
            controller: controller,
            labelText: 'Satuan Test',
            defaultOptions: defaultBaseUnits,
            onChanged: (val) => changedValue = val,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Satuan Test'), findsOneWidget);

    // Open popup menu
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    // Select 'kapsul' from popup menu
    await tester.tap(find.text('kapsul').last);
    await tester.pumpAndSettle();

    expect(controller.text, 'kapsul');
    expect(changedValue, 'kapsul');
  });

  testWidgets('EditableUnitDropdown adds custom text to customUserUnits',
      (tester) async {
    customUserUnits.clear();
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditableUnitDropdown(
            controller: controller,
            labelText: 'Custom Unit Test',
            defaultOptions: defaultBaseUnits,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'custom_unit_xyz');
    await tester.pumpAndSettle();

    expect(customUserUnits.contains('custom_unit_xyz'), isTrue);
  });
}
