import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/pos/receipt_dialog.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  final transaction = SaleTransaction(
    id: 1,
    txnNo: 'TXN-001',
    cashierId: 1,
    totalAmount: 10000,
    paymentMethod: 'cash',
    hasPrescription: false,
    createdAt: DateTime(2026, 8, 12),
  );
  final items = [
    SaleItem(
      id: 1,
      transactionId: transaction.id,
      productId: 1,
      batchId: 1,
      qtySold: 1,
      unitPrice: 10000,
      subtotal: 10000,
    ),
  ];

  Future<void> pumpReceipt(
    WidgetTester tester, {
    Future<String> Function()? saveReceipt,
    Future<void> Function()? printReceipt,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: ReceiptDialog(
              transaction: transaction,
              items: items,
              productsMap: const {},
              saveReceipt: saveReceipt,
              printReceipt: printReceipt,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('recovers a failed receipt save and retries it', (tester) async {
    var attempts = 0;
    await pumpReceipt(
      tester,
      saveReceipt: () async {
        attempts++;
        if (attempts == 1) throw StateError('storage unavailable');
        return '/receipts/TXN-001.pdf';
      },
    );

    await tester.tap(find.byKey(const Key('saveReceiptPdfBtn')));
    await tester.pumpAndSettle();

    expect(
      find.text(
          'Could not save the receipt. Check storage access and try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(
        find.text('Receipt saved to: /receipts/TXN-001.pdf'), findsOneWidget);
  });

  testWidgets('recovers a failed receipt print and retries it', (tester) async {
    var attempts = 0;
    await pumpReceipt(
      tester,
      printReceipt: () async {
        attempts++;
        if (attempts == 1) throw StateError('printer unavailable');
      },
    );

    await tester.tap(find.byKey(const Key('printReceiptBtn')));
    await tester.pumpAndSettle();

    expect(
      find.text(
          'Could not print the receipt. Check the printer and try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
  });

  testWidgets('disables only the running receipt action', (tester) async {
    final saveCompleter = Completer<String>();
    await pumpReceipt(tester, saveReceipt: () => saveCompleter.future);

    await tester.tap(find.byKey(const Key('saveReceiptPdfBtn')));
    await tester.pump();

    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('saveReceiptPdfBtn')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('printReceiptBtn')))
          .onPressed,
      isNotNull,
    );

    saveCompleter.complete('/receipts/TXN-001.pdf');
    await tester.pumpAndSettle();
  });
}
