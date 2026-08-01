import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../domain/alert_priority.dart';

final _allAlertsProvider = FutureProvider<List<AlertItem>>((ref) async {
  final repo = ref.read(alertRepositoryProvider);
  final expiring = await repo.listExpiringBatches();
  final lowStock = await repo.listLowStockProducts();

  final items = <AlertItem>[
    for (final e in expiring)
      AlertItem(
        priority: e.daysUntilExpiry <= 0
            ? AlertPriority.expired
            : e.daysUntilExpiry <= 30
                ? AlertPriority.expiring
                : AlertPriority.lowStock,
        message: '${e.product.name} - Batch #${e.batch.batchNo} expires in ${e.daysUntilExpiry} days',
        details:
            'Exp: ${e.batch.expiryDate.toIso8601String().split('T').first} | Remaining: ${e.batch.qtyRemaining} ${e.product.baseUnit}s',
      ),
    for (final l in lowStock)
      AlertItem(
        priority: AlertPriority.lowStock,
        message: '${l.product.name} - Stock: ${l.currentTotalStock} / Threshold: ${l.product.reorderThreshold}',
        details: 'Barcode: ${l.product.barcode}',
      ),
  ];
  items.sort((a, b) => a.priority.priority.compareTo(b.priority.priority));
  return items;
});

class AlertItem {
  final AlertPriority priority;
  final String message;
  final String details;
  const AlertItem({
    required this.priority,
    required this.message,
    required this.details,
  });
}

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(_allAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy Alerts'),
      ),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load alerts: $e')),
        data: (alerts) {
          if (alerts.isEmpty) {
            return const Center(child: Text('No active alerts.'));
          }
          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (ctx, idx) {
              final item = alerts[idx];
              Color color;
              IconData icon;
              switch (item.priority) {
                case AlertPriority.expired:
                  color = Colors.red;
                  icon = Icons.gavel;
                case AlertPriority.expiring:
                  color = Colors.orange;
                  icon = Icons.access_time;
                case AlertPriority.failedBackup:
                  color = Colors.deepOrange;
                  icon = Icons.cloud_off;
                case AlertPriority.lowStock:
                  color = Colors.amber;
                  icon = Icons.inventory_2;
                case AlertPriority.openShift:
                  color = Colors.blueGrey;
                  icon = Icons.logout;
              }
              return ListTile(
                leading: CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
                title: Text(item.message, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(item.details),
                trailing: Chip(
                  label: Text(
                    item.priority.name,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: color.withAlpha(30),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
