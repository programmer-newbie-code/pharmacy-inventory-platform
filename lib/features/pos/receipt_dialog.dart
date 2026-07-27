import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/sale_repository.dart';

class ReceiptDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
