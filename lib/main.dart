import 'package:flutter/material.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: PharmacyInventoryApp()));
}

class PharmacyInventoryApp extends StatelessWidget {
  const PharmacyInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Pharmacy Inventory Platform',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('id'),
      home: HomeScreen(),
    );
  }
}
