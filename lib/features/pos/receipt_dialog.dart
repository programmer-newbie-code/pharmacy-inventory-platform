import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/providers.dart';
import '../../data/database.dart';
import '../../data/receipt_storage_service.dart';
import '../../l10n/app_localizations.dart';

class ReceiptDialog extends ConsumerWidget {
  const ReceiptDialog({
    super.key,
    required this.transaction,
    required this.items,
    required this.productsMap,
  });

  final SaleTransaction transaction;
  final List<SaleItem> items;
  final Map<int, Product> productsMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: const Text('Transaction Receipt'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Apotek Inventory Platform',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            Text('Txn No: ${transaction.txnNo}'),
            Text('Date: ${transaction.createdAt.toIso8601String().replaceAll('T', ' ').substring(0, 16)}'),
            Text('Payment Method: ${transaction.paymentMethod}'),
            if (transaction.patientName != null) Text('Patient: ${transaction.patientName}'),
            if (transaction.doctorName != null) Text('Doctor: ${transaction.doctorName}'),
            const SizedBox(height: 12),
            const Text(
              'Items:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...items.map((item) {
              final prod = productsMap[item.productId];
              final name = prod?.name ?? 'Product #${item.productId}';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('$name x${item.qtySold} ${prod?.baseUnit ?? ''}'),
                    ),
                    Text('Rp ${item.subtotal.toStringAsFixed(0)}'),
                  ],
                ),
              );
            }),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL PAID:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Rp ${transaction.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton.icon(
          key: const Key('saveReceiptPdfBtn'),
          icon: const Icon(Icons.picture_as_pdf),
          label: Text(l10n.saveReceiptPdf),
          onPressed: () async {
            final pdfService = ref.read(receiptPdfServiceProvider);
            final pdfBytes = await pdfService.generateReceiptPdf(
              transaction: transaction,
              items: items,
              productsMap: productsMap,
            );
            final storageService = ref.read(receiptStorageServiceProvider);
            final savedFile = await storageService.saveReceiptPdf(
              txnNo: transaction.txnNo,
              createdAt: transaction.createdAt,
              pdfBytes: pdfBytes,
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.receiptSavedSuccess(savedFile.path)),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
        ),
        OutlinedButton.icon(
          key: const Key('printReceiptBtn'),
          icon: const Icon(Icons.print),
          label: const Text('Print Receipt'),
          onPressed: () async {
            final pdfService = ref.read(receiptPdfServiceProvider);
            final pdfBytes = await pdfService.generateReceiptPdf(
              transaction: transaction,
              items: items,
              productsMap: productsMap,
            );
            await Printing.layoutPdf(
              onLayout: (_) => pdfBytes,
              name: 'receipt_${transaction.txnNo}',
            );
          },
        ),
        ElevatedButton.icon(
          key: const Key('closeReceiptButton'),
          icon: const Icon(Icons.check),
          label: const Text('Done'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
