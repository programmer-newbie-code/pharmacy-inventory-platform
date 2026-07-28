import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../data/return_repository.dart';

class ReturnScreen extends ConsumerStatefulWidget {
  const ReturnScreen({super.key});

  @override
  ConsumerState<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends ConsumerState<ReturnScreen> {
  final _searchController = TextEditingController();
  SaleTransaction? _foundTxn;
  List<SaleItem> _txnItems = [];
  Map<int, Product> _productsMap = {};
  Map<int, int> _returnQtyMap = {}; // saleItemId -> qtyReturned
  Map<int, bool> _restockMap = {};   // saleItemId -> restock

  String _reason = 'wrong_product';
  String _refundMethod = 'Cash';
  bool _isSearching = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchTransaction() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final saleRepo = ref.read(saleRepositoryProvider);
      final prodRepo = ref.read(productRepositoryProvider);

      final allTxns = await saleRepo.listTransactions();
      final matched = allTxns.where((t) => t.txnNo.toLowerCase() == query.toLowerCase()).firstOrNull;

      if (matched == null) {
        setState(() {
          _foundTxn = null;
          _txnItems = [];
          _isSearching = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction not found.')),
          );
        }
        return;
      }

      final items = await saleRepo.getSaleItemsForTransaction(matched.id);
      final products = await prodRepo.listProducts();
      final pMap = {for (var p in products) p.id: p};

      final returnQtyMap = <int, int>{};
      final restockMap = <int, bool>{};
      for (final item in items) {
        returnQtyMap[item.id] = 0;
        restockMap[item.id] = true;
      }

      setState(() {
        _foundTxn = matched;
        _txnItems = items;
        _productsMap = pMap;
        _returnQtyMap = returnQtyMap;
        _restockMap = restockMap;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  double get _totalRefundAmount {
    double total = 0;
    for (final item in _txnItems) {
      final qty = _returnQtyMap[item.id] ?? 0;
      total += qty * item.unitPrice;
    }
    return total;
  }

  Future<void> _processReturn() async {
    if (_foundTxn == null) return;

    final selectedInputs = <ReturnItemInput>[];
    for (final item in _txnItems) {
      final qty = _returnQtyMap[item.id] ?? 0;
      if (qty > 0) {
        selectedInputs.add(
          ReturnItemInput(
            saleItem: item,
            qtyReturned: qty,
            restock: _restockMap[item.id] ?? true,
          ),
        );
      }
    }

    if (selectedInputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 1 item to return.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final returnRepo = ref.read(returnRepositoryProvider);
      final ret = await returnRepo.processReturn(
        originalTxnId: _foundTxn!.id,
        processedBy: 1, // default cashierId=1
        reason: _reason,
        refundMethod: _refundMethod,
        returnItems: selectedInputs,
      );

      setState(() {
        _foundTxn = null;
        _txnItems = [];
        _searchController.clear();
        _isProcessing = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Return Processed'),
            content: Text(
              'Return #${ret.returnNo} processed successfully.\n'
              'Total Refund: Rp ${ret.refundAmount.toStringAsFixed(0)} via ${ret.refundMethod}.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Returns & Refunds'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('searchTxnInput'),
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Transaction Number (e.g. TXN-...)',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  key: const Key('searchTxnBtn'),
                  icon: _isSearching
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search),
                  label: const Text('Search'),
                  onPressed: _isSearching ? null : _searchTransaction,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_foundTxn != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Txn: ${_foundTxn!.txnNo}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text('Payment: ${_foundTxn!.paymentMethod} • Total: Rp ${_foundTxn!.totalAmount.toStringAsFixed(0)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _txnItems.length,
                  itemBuilder: (ctx, idx) {
                    final item = _txnItems[idx];
                    final prod = _productsMap[item.productId];
                    final maxQty = item.qtySold;
                    final currentQty = _returnQtyMap[item.id] ?? 0;

                    return Card(
                      child: ListTile(
                        title: Text(prod?.name ?? 'Product #${item.productId}'),
                        subtitle: Text('Sold: ${item.qtySold} @ Rp ${item.unitPrice.toStringAsFixed(0)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _restockMap[item.id] ?? true,
                              onChanged: (val) {
                                setState(() => _restockMap[item.id] = val ?? true);
                              },
                            ),
                            const Text('Restock'),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: currentQty > 0
                                  ? () => setState(() => _returnQtyMap[item.id] = currentQty - 1)
                                  : null,
                            ),
                            Text('$currentQty / $maxQty', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: currentQty < maxQty
                                  ? () => setState(() => _returnQtyMap[item.id] = currentQty + 1)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade100,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<String>(
                          value: _reason,
                          items: const [
                            DropdownMenuItem(value: 'wrong_product', child: Text('Wrong Product')),
                            DropdownMenuItem(value: 'allergic', child: Text('Allergic Reaction')),
                            DropdownMenuItem(value: 'defective', child: Text('Defective / Damaged')),
                            DropdownMenuItem(value: 'other', child: Text('Other')),
                          ],
                          onChanged: (val) => setState(() => _reason = val ?? 'wrong_product'),
                        ),
                        DropdownButton<String>(
                          value: _refundMethod,
                          items: const [
                            DropdownMenuItem(value: 'Cash', child: Text('Cash Refund')),
                            DropdownMenuItem(value: 'Store Credit', child: Text('Store Credit')),
                            DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                          ],
                          onChanged: (val) => setState(() => _refundMethod = val ?? 'Cash'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL REFUND:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          'Rp ${_totalRefundAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        key: const Key('processReturnBtn'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        icon: _isProcessing
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.assignment_return),
                        label: const Text('Process Return & Issue Refund'),
                        onPressed: _isProcessing || _totalRefundAmount == 0 ? null : _processReturn,
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              const Expanded(child: Center(child: Text('Search a transaction number to process a return.'))),
          ],
        ),
      ),
    );
  }
}
