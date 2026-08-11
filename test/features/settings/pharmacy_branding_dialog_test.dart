import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/features/settings/pharmacy_branding_dialog.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders PharmacyBrandingDialog and saves branding', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: Scaffold(
            body: PharmacyBrandingDialog(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pharmacy Branding & Logo'), findsOneWidget);
    expect(find.byKey(const Key('brandingNameInput')), findsOneWidget);
    expect(find.byKey(const Key('receiptDirInput')), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('brandingNameInput')), 'Apotek Utama Express');
    await tester.enterText(
        find.byKey(const Key('receiptDirInput')), 'C:/Pharmacy Receipts');
    await tester.tap(find.byKey(const Key('saveBrandingBtn')));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('pharmacy_name'), 'Apotek Utama Express');
    expect(prefs.getString('receipt_custom_base_dir'), 'C:/Pharmacy Receipts');
  });
}
