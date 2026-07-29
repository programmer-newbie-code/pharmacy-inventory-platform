import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pharmacy_inventory_platform/features/help/quick_guide_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Pharmacy Inventory',
      packageName: 'com.programmernewbiecode.pharmacy_inventory_platform',
      version: '1.2.0',
      buildNumber: '3',
      buildSignature: '',
    );
  });

  testWidgets('QuickGuideDialog displays onboarding manual and closes on button tap', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuickGuideDialog(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Quick Start & User Guide'), findsOneWidget);
    expect(find.text('Welcome to Pharmacy Inventory Platform v1.2.0!'), findsOneWidget);
    expect(find.text('POS Sales Counter'), findsOneWidget);
    expect(find.text('Inventory Catalog'), findsOneWidget);

    await tester.tap(find.byKey(const Key('closeGuideButton')));
    await tester.pump();
  });
}
