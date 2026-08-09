import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';

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
  late TextEditingController _costPriceController;
  late TextEditingController _purchaseUnitPriceController;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  @override
  void initState() {
    super.initState();
    _costPriceController =
        TextEditingController(text: widget.product.costPricePerBaseUnit.toString());
    final initialBoxPrice =
        widget.product.costPricePerBaseUnit * widget.product.unitsPerPurchaseUnit;
    _purchaseUnitPriceController =
        TextEditingController(text: initialBoxPrice.toStringAsFixed(0));
  }

  void _onPurchasePriceChanged(String val) {
    final purchasePrice = double.tryParse(val) ?? 0.0;
    final units = widget.product.unitsPerPurchaseUnit > 0
        ? widget.product.unitsPerPurchaseUnit
        : 1;
    final basePrice = purchasePrice / units;
    _costPriceController.value = TextEditingValue(
      text: basePrice == basePrice.roundToDouble()
          ? basePrice.toStringAsFixed(0)
          : basePrice.toStringAsFixed(2),
    );
    setState(() {});
  }

  void _onBasePriceChanged(String val) {
    final basePrice = double.tryParse(val) ?? 0.0;
    final units = widget.product.unitsPerPurchaseUnit > 0
        ? widget.product.unitsPerPurchaseUnit
        : 1;
    final purchasePrice = basePrice * units;
    _purchaseUnitPriceController.value = TextEditingValue(
      text: purchasePrice == purchasePrice.roundToDouble()
          ? purchasePrice.toStringAsFixed(0)
          : purchasePrice.toStringAsFixed(2),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _batchNoController.dispose();
    _supplierController.dispose();
    _qtyPurchaseUnitController.dispose();
    _costPriceController.dispose();
    _purchaseUnitPriceController.dispose();
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
    final costPrice = double.parse(_costPriceController.text.trim());

    await batchRepo.createStockBatch(
      productId: widget.product.id,
      batchNo: _batchNoController.text.trim(),
      receivedDate: DateTime.now(),
      expiryDate: _expiryDate,
      qtyReceivedBaseUnit: totalBaseUnits,
      costPricePerBaseUnit: costPrice,
      supplier: _supplierController.text.trim(),
      createdBy: 'admin',
    );

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                decoration: const InputDecoration(
                  labelText: 'Batch Number',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('supplierInput'),
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Supplier',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('qtyPurchaseUnitInput'),
                controller: _qtyPurchaseUnitController,
                decoration: InputDecoration(
                  labelText: 'Quantity in ${widget.product.purchaseUnit}s',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (v) => (v == null || int.tryParse(v) == null) ? 'Invalid' : null,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2, size: 16, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      '= $totalBaseUnits ${widget.product.baseUnit}s total stock',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Dual Unit Price Input
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchaseUnitPriceController,
                      decoration: InputDecoration(
                        labelText: l10n.pricePerPurchaseUnitLabel,
                        prefixText: 'Rp ',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: _onPurchasePriceChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceController,
                      decoration: InputDecoration(
                        labelText: l10n.costPricePerBaseUnitLabel,
                        prefixText: 'Rp ',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: _onBasePriceChanged,
                      validator: (v) => (v == null || double.tryParse(v) == null) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Live Breakdown Banner
              Builder(builder: (ctx) {
                final purchasePrice =
                    double.tryParse(_purchaseUnitPriceController.text) ?? 0.0;
                final basePrice =
                    double.tryParse(_costPriceController.text) ?? 0.0;
                final units = widget.product.unitsPerPurchaseUnit > 0
                    ? widget.product.unitsPerPurchaseUnit
                    : 1;

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.primaryColor.withAlpha(40)),
                  ),
                  child: Text(
                    l10n.conversionBreakdownHint(
                      widget.product.purchaseUnit,
                      units,
                      widget.product.baseUnit,
                      formatIdr(purchasePrice).replaceAll('Rp ', ''),
                      formatIdr(basePrice).replaceAll('Rp ', ''),
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              }),
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
