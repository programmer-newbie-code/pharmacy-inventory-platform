import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/patients/patient_list_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets('renders PatientListScreen, adds patient, and views details',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PatientListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Patient Directory'), findsOneWidget);
    expect(find.byKey(const Key('addPatientBtn')), findsOneWidget);

    // Open Add Patient screen
    await tester.tap(find.byKey(const Key('addPatientBtn')));
    await tester.pumpAndSettle();

    expect(find.text('Add New Patient'), findsOneWidget);
    await tester.enterText(
        find.byKey(const Key('patientNameInput')), 'Budi Santoso');
    await tester.enterText(
        find.byKey(const Key('patientPhoneInput')), '081234567890');
    await tester.enterText(
        find.byKey(const Key('patientAllergiesInput')), 'Penicillin');

    await tester.tap(find.byKey(const Key('savePatientBtn')));
    await tester.pumpAndSettle();

    // Verify patient listed
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.textContaining('081234567890'), findsOneWidget);

    // Tap patient item to view detail
    await tester.tap(find.text('Budi Santoso'));
    await tester.pumpAndSettle();

    expect(find.text('Penicillin'), findsOneWidget);
  });

  testWidgets('patient screens render from ARB in both locales',
      (tester) async {
    Future<void> pumpIn(Locale locale) async {
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
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const PatientListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpIn(const Locale('en'));
    expect(find.text('Patient Directory'), findsOneWidget);
    await tester.tap(find.byKey(const Key('addPatientBtn')));
    await tester.pumpAndSettle();
    expect(find.text('Add New Patient'), findsOneWidget);

    await pumpIn(const Locale('id'));
    // A regression to hard-coded English would fail here.
    expect(find.text('Patient Directory'), findsNothing);
    expect(find.text('Direktori Pasien'), findsOneWidget);
    await tester.tap(find.byKey(const Key('addPatientBtn')));
    await tester.pumpAndSettle();
    expect(find.text('Add New Patient'), findsNothing);
    expect(find.text('Tambah Pasien Baru'), findsOneWidget);
  });
}
