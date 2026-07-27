import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/features/help/quick_guide_dialog.dart';

void main() {
  testWidgets('QuickGuideDialog displays onboarding manual and closes on button tap', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuickGuideDialog(),
        ),
      ),
    );

    expect(find.text('Quick Start & User Guide'), findsOneWidget);
    expect(find.text('POS Sales Counter'), findsOneWidget);
    expect(find.text('Inventory Catalog'), findsOneWidget);

    await tester.tap(find.byKey(const Key('closeGuideButton')));
    await tester.pump();
  });
}
