import 'package:flutter/material.dart';

class QuickGuideDialog extends StatelessWidget {
  const QuickGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.help_outline, color: Colors.blue),
          SizedBox(width: 8),
          Text('Quick Start & User Guide'),
        ],
      ),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Welcome to Pharmacy Inventory Platform!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.point_of_sale, color: Colors.green),
              title: Text('POS Sales Counter'),
              subtitle: Text('Scan barcodes, FEFO automatic stock deduction, prescription verification for controlled drugs, and receipts.'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.inventory, color: Colors.blue),
              title: Text('Inventory Catalog'),
              subtitle: Text('Manage products, unit conversions (box to tablet), cost margins, and incoming stock batch entry.'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.warning_amber, color: Colors.orange),
              title: Text('Expiry & Low-Stock Alerts'),
              subtitle: Text('Real-time alerts for batches expiring in 30/60/90 days and products below reorder thresholds.'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.security, color: Colors.purple),
              title: Text('Compliance & Backup'),
              subtitle: Text('Export BPOM prescription logs to CSV and create local database JSON backups.'),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          key: const Key('closeGuideButton'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it!'),
        ),
      ],
    );
  }
}
