import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/database.dart';

class AddStockBatchDialog extends ConsumerStatefulWidget {
  const AddStockBatchDialog({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<AddStockBatchDialog> createState() => _AddStockBatchDialogState();
}

class _AddStockBatchDialogState extends ConsumerState<AddStockBatchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _batchNoController = TextEditingController();
  final _supplierController = TextEditingController();
  final _qtyPurchaseUnitController = TextEditingController(text: '1');
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  @override
  void dispose() {
    _batchNoController.dispose();
    _supplierController.dispose();
    _qtyPurchaseUnitController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final batchRepo = ref.read(stockBatchRepositoryProvider);
    final purchaseQty = int.parse(_qtyPurchaseUnitController.text.trim());
    final totalBaseUnits = purchaseQty * widget.product.unitsPerPurchaseUnit;

    await batchRepo.createStockBatch(
      productId: widget.product.id,
      batchNo: _batchNoController.text.trim(),
      receivedDate: DateTime.now(),
      expiryDate: _expiryDate,
      qtyReceivedBaseUnit: totalBaseUnits,
      costPricePerBaseUnit: widget.product.costPricePerBaseUnit,
      supplier: _supplierController.text.trim(),
      createdBy: 'admin',
    );

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final purchaseQty = int.tryParse(_qtyPurchaseUnitController.text.trim()) ?? 0;
    final totalBaseUnits = purchaseQty * widget.product.unitsPerPurchaseUnit;

    return AlertDialog(
      title: Text('Receive Stock: ${widget.product.name}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('batchNoInput'),
                controller: _batchNoController,
                decoration: const InputDecoration(labelText: 'Batch Number'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                key: const Key('supplierInput'),
                controller: _supplierController,
                decoration: const InputDecoration(labelText: 'Supplier'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                key: const Key('qtyPurchaseUnitInput'),
                controller: _qtyPurchaseUnitController,
                decoration: InputDecoration(
                  labelText: 'Quantity in ${widget.product.purchaseUnit}s',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (v) => (v == null || int.tryParse(v) == null) ? 'Invalid' : null,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.blue.shade50,
                child: Text(
                  '= $totalBaseUnits ${widget.product.baseUnit}s total stock',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text('Expiry Date: ${_expiryDate.toIso8601String().split('T').first}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickExpiryDate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('saveBatchButton'),
          onPressed: _save,
          child: const Text('Save Stock Batch'),
        ),
      ],
    );
  }
}
