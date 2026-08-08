import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../data/purchase_order_repository.dart';
import 'supplier_list_screen.dart';

final poListFutureProvider = FutureProvider.autoDispose<List<PurchaseOrder>>((ref) {
  final repo = ref.watch(purchaseOrderRepositoryProvider);
  return repo.listPurchaseOrders();
});

class PurchaseOrderScreen extends ConsumerWidget {
  const PurchaseOrderScreen({super.key});

  Future<void> _showCreatePODialog(BuildContext context, WidgetRef ref) async {
    final suppliers = await ref.read(supplierRepositoryProvider).listSuppliers();
    final products = await ref.read(productRepositoryProvider).listProducts();

    if (suppliers.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 1 supplier first.')),
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SupplierListScreen()),
      );
      return;
    }

    if (products.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please register products in inventory catalog first.')),
      );
      return;
    }

    int selectedSupplierId = suppliers.first.id;
    int selectedProductId = products.first.id;
    final qtyController = TextEditingController(text: '50');
    final costController = TextEditingController(text: products.first.costPricePerBaseUnit.toStringAsFixed(0));

    if (!context.mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final prod = products.firstWhere((p) => p.id == selectedProductId);
          return AlertDialog(
            title: const Text('Create Purchase Order'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedSupplierId,
                    decoration: const InputDecoration(labelText: 'Supplier'),
                    items: suppliers
                        .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedSupplierId = val!),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: selectedProductId,
                    decoration: const InputDecoration(labelText: 'Product'),
                    items: products
                        .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedProductId = val!;
                        final p = products.firstWhere((item) => item.id == val);
                        costController.text = p.costPricePerBaseUnit.toStringAsFixed(0);
                      });
                    },
                  ),
                  TextField(
                    key: const Key('poQtyInput'),
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Quantity (${prod.baseUnit}s)'),
                  ),
                  TextField(
                    key: const Key('poCostInput'),
                    controller: costController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Unit Cost Price (Rp)'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                key: const Key('confirmCreatePoBtn'),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Send Order'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      final qty = int.tryParse(qtyController.text) ?? 0;
      final cost = double.tryParse(costController.text) ?? 0.0;

      if (qty > 0 && cost > 0) {
        final poRepo = ref.read(purchaseOrderRepositoryProvider);
        await poRepo.createPurchaseOrder(
          supplierId: selectedSupplierId,
          createdBy: 'admin',
          items: [
            POItemInput(productId: selectedProductId, qtyOrdered: qty, unitCost: cost),
          ],
        );
        ref.invalidate(poListFutureProvider);
      }
    }
  }

  Future<void> _handleReceivePO(BuildContext context, WidgetRef ref, PurchaseOrder po) async {
    final prefixController = TextEditingController(text: 'BATCH-${DateTime.now().year}');
    DateTime expiryDate = DateTime.now().add(const Duration(days: 365));

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text('Receive Delivery for ${po.poNumber}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('batchPrefixInput'),
                  controller: prefixController,
                  decoration: const InputDecoration(labelText: 'Stock Batch No. Prefix'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Expiry Date: ${expiryDate.toIso8601String().split('T').first}'),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: expiryDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setState(() => expiryDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                key: const Key('confirmReceivePoBtn'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Receive & Add to Stock'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      final poRepo = ref.read(purchaseOrderRepositoryProvider);
      await poRepo.receivePurchaseOrder(
        poId: po.id,
        batchNoPrefix: prefixController.text.trim(),
        expiryDate: expiryDate,
      );
      ref.invalidate(poListFutureProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delivery for ${po.poNumber} received and added to active inventory stock!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posAsync = ref.watch(poListFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders & Reordering'),
        actions: [
          IconButton(
            key: const Key('navSuppliersDirectoryBtn'),
            icon: const Icon(Icons.contacts),
            tooltip: 'Suppliers Directory',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SupplierListScreen()),
              );
            },
          ),
        ],
      ),
      body: posAsync.when(
        data: (pos) {
          if (pos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No purchase orders created yet.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    key: const Key('createPoBtn'),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Create Purchase Order'),
                    onPressed: () => _showCreatePODialog(context, ref),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: pos.length,
            itemBuilder: (ctx, idx) {
              final po = pos[idx];
              final isReceived = po.status == 'received';
              final isCancelled = po.status == 'cancelled';

              Widget trailingWidget;
              if (isReceived) {
                trailingWidget = const Chip(
                  label: Text('RECEIVED'),
                  backgroundColor: Colors.greenAccent,
                );
              } else if (isCancelled) {
                trailingWidget = Chip(
                  label: const Text('CANCELLED'),
                  backgroundColor: Colors.red.shade100,
                );
              } else {
                trailingWidget = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      key: Key('cancelPoBtn_${po.id}'),
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                      label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text('Cancel PO ${po.poNumber}'),
                            content: const Text('Are you sure you want to cancel this Purchase Order?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('No'),
                              ),
                              ElevatedButton(
                                key: Key('confirmCancelPoBtn_${po.id}'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Cancel PO'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          final poRepo = ref.read(purchaseOrderRepositoryProvider);
                          await poRepo.cancelPurchaseOrder(po.id, cancelReason: 'Cancelled by user');
                          ref.invalidate(poListFutureProvider);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      key: Key('receivePoBtn_${po.id}'),
                      icon: const Icon(Icons.inventory_2),
                      label: const Text('Receive'),
                      onPressed: () => _handleReceivePO(context, ref, po),
                    ),
                  ],
                );
              }

              return Card(
                child: ListTile(
                  title: Text('${po.poNumber} (${po.status.toUpperCase()})'),
                  subtitle: Text('Total: Rp ${po.totalAmount.toStringAsFixed(0)} • Created: ${po.createdAt.toIso8601String().split('T').first}'),
                  trailing: trailingWidget,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('fabCreatePo'),
        onPressed: () => _showCreatePODialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
