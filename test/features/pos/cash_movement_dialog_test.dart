import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/pos/cash_movement_dialog.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets('renders CashMovementDialog and submits cash withdrawal (owner draw)',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    // Open a shift first
    final shift = await container
        .read(cashierShiftRepositoryProvider)
        .openShift(cashierId: 1, openingBalance: 100000);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('id'),
          home: Scaffold(
            body: CashMovementDialog(shiftId: shift.id),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Catat Arus Kas / Prive Owner'), findsOneWidget);
    expect(find.byKey(const Key('movementAmountInput')), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('movementAmountInput')), '500000');
    await tester.enterText(
        find.byKey(const Key('movementNotesInput')), 'Tarik untung harian owner');

    await tester.tap(find.byKey(const Key('submitCashMovementBtn')));
    await tester.pumpAndSettle();

    final movements = await container
        .read(cashierShiftRepositoryProvider)
        .getCashMovementsForShift(shift.id);

    expect(movements.length, 1);
    expect(movements.first.amount, 500000);
    expect(movements.first.category, 'owner_draw');
    expect(movements.first.notes, 'Tarik untung harian owner');
  });
}
