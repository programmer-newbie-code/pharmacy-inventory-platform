import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/alert_repository.dart';
import '../suppliers/purchase_order_screen.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  int _daysThreshold = 90;
  List<ExpiringBatchDetail> _expiringBatches = [];
  List<LowStockProductDetail> _lowStockProducts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    final repo = ref.read(alertRepositoryProvider);

    final expiring = await repo.listExpiringBatches(daysThreshold: _daysThreshold);
    final lowStock = await repo.listLowStockProducts();

    setState(() {
      _expiringBatches = expiring;
      _lowStockProducts = lowStock;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expiry & Low Stock Alerts'),
          bottom: TabBar(
            tabs: [
              Tab(
                text: 'Expiring Batches (${_expiringBatches.length})',
                icon: const Icon(Icons.access_time),
              ),
              Tab(
                text: 'Low Stock (${_lowStockProducts.length})',
                icon: const Icon(Icons.warning_amber),
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Tab 1: Expiring Batches
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Text('Show batches expiring within: '),
                            DropdownButton<int>(
                              value: _daysThreshold,
                              items: const [
                                DropdownMenuItem(value: 30, child: Text('30 Days')),
                                DropdownMenuItem(value: 60, child: Text('60 Days')),
                                DropdownMenuItem(value: 90, child: Text('90 Days')),
                                DropdownMenuItem(value: 180, child: Text('180 Days')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _daysThreshold = val);
                                  _loadAlerts();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _expiringBatches.isEmpty
                            ? const Center(child: Text('No batches expiring within threshold.'))
                            : ListView.builder(
                                itemCount: _expiringBatches.length,
                                itemBuilder: (ctx, idx) {
                                  final item = _expiringBatches[idx];
                                  final isCritical = item.daysUntilExpiry <= 30;

                                  return ListTile(
                                    key: Key('expiringBatchTile_$idx'),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          isCritical ? Colors.red : Colors.orange,
                                      child: const Icon(Icons.event, color: Colors.white),
                                    ),
                                    title: Text(item.product.name),
                                    subtitle: Text(
                                      'Batch #${item.batch.batchNo} | Exp: ${item.batch.expiryDate.toIso8601String().split('T').first} | Remaining: ${item.batch.qtyRemaining} ${item.product.baseUnit}s',
                                    ),
                                    trailing: Chip(
                                      label: Text('${item.daysUntilExpiry} days left'),
                                      backgroundColor: isCritical
                                          ? Colors.red.shade100
                                          : Colors.orange.shade100,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),

                  // Tab 2: Low Stock Products
                  _lowStockProducts.isEmpty
                      ? const Center(child: Text('All products have adequate stock.'))
                      : ListView.builder(
                          itemCount: _lowStockProducts.length,
                          itemBuilder: (ctx, idx) {
                            final item = _lowStockProducts[idx];
                            return ListTile(
                              key: Key('lowStockTile_$idx'),
                              leading: const CircleAvatar(
                                backgroundColor: Colors.amber,
                                child: Icon(Icons.inventory_2, color: Colors.white),
                              ),
                              title: Text(item.product.name),
                              subtitle: Text(
                                'Barcode: ${item.product.barcode} | Location: ${item.product.category}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Stock: ${item.currentTotalStock} / Threshold: ${item.product.reorderThreshold}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      Text(
                                        '${item.product.baseUnit}s',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    key: Key('createPoFromAlert_${item.product.id}'),
                                    icon: const Icon(Icons.add_shopping_cart, color: Colors.blue),
                                    tooltip: 'Create Purchase Order',
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const PurchaseOrderScreen()),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
      ),
    );
  }
}
