import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/database.dart';

class AddProductDialog extends ConsumerStatefulWidget {
  const AddProductDialog({super.key});

  @override
  ConsumerState<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _internalCodeController = TextEditingController();
  final _activeIngredientController = TextEditingController();
  final _baseUnitController = TextEditingController(text: 'tablet');
  final _purchaseUnitController = TextEditingController(text: 'box');
  final _unitsPerPurchaseUnitController = TextEditingController(text: '100');
  final _costPriceController = TextEditingController(text: '100.0');
  final _marginPctController = TextEditingController(text: '20.0');
  final _reorderThresholdController = TextEditingController(text: '50');
  final _categoryController = TextEditingController(text: 'Obat Bebas');
  bool _isControlled = false;
  int? _selectedStorageLocationId;
  List<StorageLocation> _locations = [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final locs = await ref.read(productRepositoryProvider).listStorageLocations();
    setState(() {
      _locations = locs;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _internalCodeController.dispose();
    _activeIngredientController.dispose();
    _baseUnitController.dispose();
    _purchaseUnitController.dispose();
    _unitsPerPurchaseUnitController.dispose();
    _costPriceController.dispose();
    _marginPctController.dispose();
    _reorderThresholdController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(productRepositoryProvider);

    await repo.createProduct(
      barcode: _barcodeController.text.trim(),
      internalCode: _internalCodeController.text.trim(),
      name: _nameController.text.trim(),
      activeIngredient: _activeIngredientController.text.trim(),
      ingredientPct: 100.0,
      baseUnit: _baseUnitController.text.trim(),
      purchaseUnit: _purchaseUnitController.text.trim(),
      unitsPerPurchaseUnit: int.parse(_unitsPerPurchaseUnitController.text.trim()),
      costPricePerBaseUnit: double.parse(_costPriceController.text.trim()),
      marginPct: double.parse(_marginPctController.text.trim()),
      reorderThreshold: int.parse(_reorderThresholdController.text.trim()),
      isControlled: _isControlled,
      storageLocationId: _selectedStorageLocationId,
      category: _categoryController.text.trim(),
      createdBy: 'admin',
    );

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Product'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('productNameInput'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                key: const Key('productBarcodeInput'),
                controller: _barcodeController,
                decoration: const InputDecoration(labelText: 'Barcode'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                key: const Key('productInternalCodeInput'),
                controller: _internalCodeController,
                decoration: const InputDecoration(labelText: 'Internal Code'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                key: const Key('activeIngredientInput'),
                controller: _activeIngredientController,
                decoration: const InputDecoration(labelText: 'Active Ingredient'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _baseUnitController,
                      decoration: const InputDecoration(labelText: 'Base Unit (e.g. tablet)'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _purchaseUnitController,
                      decoration: const InputDecoration(labelText: 'Purchase Unit (e.g. box)'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _unitsPerPurchaseUnitController,
                decoration: const InputDecoration(labelText: 'Base Units per Purchase Unit'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || int.tryParse(v) == null) ? 'Invalid number' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceController,
                      decoration: const InputDecoration(labelText: 'Cost Price / Base Unit'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _marginPctController,
                      decoration: const InputDecoration(labelText: 'Margin %'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _reorderThresholdController,
                decoration: const InputDecoration(labelText: 'Reorder Threshold (Base Units)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              if (_locations.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: _selectedStorageLocationId,
                  decoration: const InputDecoration(labelText: 'Storage Location'),
                  items: _locations
                      .map((loc) => DropdownMenuItem<int>(
                            value: loc.id,
                            child: Text('${loc.code} - ${loc.name}'),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedStorageLocationId = val),
                ),
              CheckboxListTile(
                key: const Key('isControlledCheckbox'),
                title: const Text('Controlled Drug / Prescription Required'),
                value: _isControlled,
                onChanged: (val) => setState(() => _isControlled = val ?? false),
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
          key: const Key('saveProductButton'),
          onPressed: _save,
          child: const Text('Save Product'),
        ),
      ],
    );
  }
}
