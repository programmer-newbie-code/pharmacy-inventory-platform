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

  testWidgets('renders receipt body copy from ARB in English', (tester) async {
    final txnWithPrescription = SaleTransaction(
      id: 2,
      txnNo: 'TXN-002',
      cashierId: 1,
      totalAmount: 25000,
      paymentMethod: 'cash',
      hasPrescription: true,
      patientName: 'Jane Doe',
      doctorName: 'Dr. Smith',
      createdAt: DateTime(2026, 8, 12, 10, 30),
    );
    final itemsWithoutProduct = [
      SaleItem(
        id: 2,
        transactionId: txnWithPrescription.id,
        productId: 999,
        batchId: 1,
        qtySold: 1,
        unitPrice: 25000,
        subtotal: 25000,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: ReceiptDialog(
              transaction: txnWithPrescription,
              items: itemsWithoutProduct,
              productsMap: const {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Apotek Inventory Platform'), findsOneWidget);
    expect(find.text('Txn No: TXN-002'), findsOneWidget);
    expect(find.text('Date: 2026-08-12 10:30'), findsOneWidget);
    expect(find.text('Payment Method: cash'), findsOneWidget);
    expect(find.text('Patient: Jane Doe'), findsOneWidget);
    expect(find.text('Doctor: Dr. Smith'), findsOneWidget);
    expect(find.text('Items:'), findsOneWidget);
    expect(find.text('TOTAL PAID:'), findsOneWidget);
    expect(find.textContaining('Product #999 x1'), findsOneWidget);
  });

  testWidgets('renders receipt body copy from ARB in Indonesian',
      (tester) async {
    final txnWithPrescription = SaleTransaction(
      id: 3,
      txnNo: 'TXN-003',
      cashierId: 1,
      totalAmount: 25000,
      paymentMethod: 'tunai',
      hasPrescription: true,
      patientName: 'Jane Doe',
      doctorName: 'Dr. Smith',
      createdAt: DateTime(2026, 8, 12, 10, 30),
    );
    final itemsWithoutProduct = [
      SaleItem(
        id: 3,
        transactionId: txnWithPrescription.id,
        productId: 998,
        batchId: 1,
        qtySold: 1,
        unitPrice: 25000,
        subtotal: 25000,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('id'),
          home: Scaffold(
            body: ReceiptDialog(
              transaction: txnWithPrescription,
              items: itemsWithoutProduct,
              productsMap: const {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // These strings must render from ARB in the Indonesian locale, not the
    // English literals ('Apotek Inventory Platform' happens to be the same
    // string in both locales, so it is not a useful distinguishing check
    // here — the label/prefix strings are).
    expect(find.text('No. Transaksi: TXN-003'), findsOneWidget);
    expect(find.text('Txn No: TXN-003'), findsNothing);
    expect(find.text('Tanggal: 2026-08-12 10:30'), findsOneWidget);
    expect(find.text('Metode Pembayaran: tunai'), findsOneWidget);
    expect(find.text('Pasien: Jane Doe'), findsOneWidget);
    expect(find.text('Dokter: Dr. Smith'), findsOneWidget);
    expect(find.text('Item:'), findsOneWidget);
    expect(find.text('TOTAL DIBAYAR:'), findsOneWidget);
    expect(find.textContaining('Produk #998 x1'), findsOneWidget);
  });
}
