import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/features/home/home_screen.dart';

void main() {
  testWidgets('renders the app title from localized strings, default locale id',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('id'),
        home: HomeScreen(),
      ),
    );

    expect(find.text('Platform Inventaris Apotek'), findsWidgets);
  });
}
