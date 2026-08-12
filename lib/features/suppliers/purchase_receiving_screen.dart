import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../data/purchase_receiving_repository.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_session.dart';

class PurchaseReceivingScreen extends ConsumerStatefulWidget {
  const PurchaseReceivingScreen({super.key, required this.purchaseOrderId});

  final int purchaseOrderId;

  @override
  ConsumerState<PurchaseReceivingScreen> createState() =>
      _PurchaseReceivingScreenState();
}

class _ReceivingLine {
  _ReceivingLine({required this.poItem, required this.product});

  final PurchaseOrderItem poItem;
  final Product product;
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController batchNoController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  DateTime expiryDate = DateTime.now().add(const Duration(days: 365));
  double costPricePerBaseUnit = 0;

  int get qtyRemaining => poItem.qtyOrdered - poItem.qtyReceived;
  int get qtyEntered => int.tryParse(qtyController.text) ?? 0;
  bool get hasDiscrepancy => qtyEntered != qtyRemaining;
}

class _PurchaseReceivingScreenState
    extends ConsumerState<PurchaseReceivingScreen> {
  PurchaseOrder? _po;
  Supplier? _supplier;
  List<_ReceivingLine> _lines = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final poRepo = ref.read(purchaseOrderRepositoryProvider);
    final supplierRepo = ref.read(supplierRepositoryProvider);
    final productRepo = ref.read(productRepositoryProvider);

    final pos = await poRepo.listPurchaseOrders();
    final po = pos.firstWhere((p) => p.id == widget.purchaseOrderId);
    final supplier = await supplierRepo.getSupplier(po.supplierId);
    final poItems = await poRepo.getPOItems(widget.purchaseOrderId);

    final lines = <_ReceivingLine>[];
    for (final item in poItems) {
      // Only show items with outstanding quantities
      if (item.qtyReceived >= item.qtyOrdered) continue;

      final products = await productRepo.getProductById(item.productId);
      if (products == null) continue;

      final line = _ReceivingLine(poItem: item, product: products);
      line.qtyController.text = line.qtyRemaining.toString();
      line.costPricePerBaseUnit = item.unitCost;
      lines.add(line);
    }

    if (!mounted) return;
    setState(() {
      _po = po;
      _supplier = supplier;
      _lines = lines;
      _isLoading = false;
    });
  }

  Future<void> _processReceiving() async {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.read(authSessionProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.sessionRequired)));
      return;
    }

    // Validate all lines have batch numbers
    for (final line in _lines) {
      if (line.batchNoController.text.trim().isEmpty && line.qtyEntered > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.receivingBatchRequired(line.product.name)),
          ),
        );
        return;
      }
      if (line.hasDiscrepancy && line.reasonController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.receivingDiscrepancyReasonRequired(line.product.name),
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final receivingRepo = ref.read(purchaseReceivingRepositoryProvider);
      final items = _lines
          .map(
            (line) => ReceivingItemInput(
              productId: line.poItem.productId,
              qtyOrdered: line.qtyRemaining,
              qtyReceived: line.qtyEntered,
              batchNo: line.batchNoController.text.trim(),
              expiryDate: line.expiryDate,
              costPricePerBaseUnit: line.costPricePerBaseUnit,
              discrepancyReason: line.hasDiscrepancy
                  ? line.reasonController.text.trim()
                  : null,
            ),
          )
          .toList();

      await receivingRepo.processReceiving(
        purchaseOrderId: widget.purchaseOrderId,
        items: items,
        receivedByUserId: currentUser.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.receivingSuccess)),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.receivingFailed)));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickExpiryDate(_ReceivingLine line) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: line.expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => line.expiryDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.receivingLoadingTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.receivingTitle(_po?.poNumber ?? '')),
        actions: [
          FilledButton.icon(
            key: const Key('completeReceivingBtn'),
            icon: const Icon(Icons.check),
            label: Text(l10n.receivingComplete),
            onPressed: _isProcessing ? null : _processReceiving,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Supplier & PO info header
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Icon(Icons.local_shipping),
                const SizedBox(width: 8),
                Text(
                  l10n.receivingSupplier(_supplier?.name ?? '-'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  l10n.receivingItemsCount(_lines.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Line items
          if (_lines.isEmpty)
            Expanded(
              child: Center(child: Text(l10n.receivingAllItemsReceived)),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: _lines.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (ctx, idx) => _buildLineItem(_lines[idx]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLineItem(_ReceivingLine line) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product name
            Text(
              line.product.name,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.receivingLineSummary(
                line.qtyRemaining,
                line.product.baseUnit,
                line.costPricePerBaseUnit.toStringAsFixed(0),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            // Input fields in a row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: line.qtyController,
                    decoration: InputDecoration(
                      labelText: l10n.receivingQuantityLabel,
                      suffixText: line.product.baseUnit,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: line.batchNoController,
                    decoration: InputDecoration(
                      labelText: l10n.receivingBatchLabel,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => _pickExpiryDate(line),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.receivingExpiryLabel,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: Text(
                        '${line.expiryDate.day}/${line.expiryDate.month}/${line.expiryDate.year}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Discrepancy warning
            if (line.hasDiscrepancy) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.orange.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.receivingDiscrepancy(
                            line.qtyRemaining,
                            line.qtyEntered,
                          ),
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: line.reasonController,
                      decoration: InputDecoration(
                        hintText: l10n.receivingDiscrepancyReasonHint,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
