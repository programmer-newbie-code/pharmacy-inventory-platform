import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/main.dart';

import 'support/user_repository_test_seed.dart';

void main() {
  testWidgets('shows setup screen when there are no users yet', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const PharmacyInventoryApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('setupAdminUsername')), findsOneWidget);
  });

  testWidgets('shows login screen when a user already exists', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await UserRepositoryTestSeed(db).seedOneUser();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const PharmacyInventoryApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loginUsername')), findsOneWidget);
  });
}
