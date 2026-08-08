import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/database.dart';

class EditProductDialog extends ConsumerStatefulWidget {
  const EditProductDialog({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends ConsumerState<EditProductDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _activeIngredientController;
  late TextEditingController _ingredientPctController;
  late TextEditingController _baseUnitController;
  late TextEditingController _costPriceController;
  late TextEditingController _marginController;
  late TextEditingController _reorderThresholdController;

  late bool _isControlled;
  String? _controlledCategory;
  late String _category;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p.name);
    _activeIngredientController =
        TextEditingController(text: p.activeIngredient);
    _ingredientPctController =
        TextEditingController(text: p.ingredientPct.toString());
    _baseUnitController = TextEditingController(text: p.baseUnit);
    _costPriceController =
        TextEditingController(text: p.costPricePerBaseUnit.toString());
    _marginController = TextEditingController(text: p.marginPct.toString());
    _reorderThresholdController =
        TextEditingController(text: p.reorderThreshold.toString());
    _isControlled = p.isControlled;
    _controlledCategory = p.controlledCategory;
    _category = p.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _activeIngredientController.dispose();
    _ingredientPctController.dispose();
    _baseUnitController.dispose();
    _costPriceController.dispose();
    _marginController.dispose();
    _reorderThresholdController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = ref.read(productRepositoryProvider);
    final updated = widget.product.copyWith(
      name: _nameController.text.trim(),
      activeIngredient: _activeIngredientController.text.trim(),
      ingredientPct: double.tryParse(_ingredientPctController.text) ?? 100,
      baseUnit: _baseUnitController.text.trim(),
      costPricePerBaseUnit:
          double.tryParse(_costPriceController.text) ?? widget.product.costPricePerBaseUnit,
      marginPct: double.tryParse(_marginController.text) ?? widget.product.marginPct,
      reorderThreshold:
          int.tryParse(_reorderThresholdController.text) ?? widget.product.reorderThreshold,
      isControlled: _isControlled,
      controlledCategory: Value(_isControlled ? _controlledCategory : null),
      category: _category,
    );

    await repo.updateProduct(updated);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Product: ${widget.product.name}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('editProductNameInput'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _activeIngredientController,
                decoration:
                    const InputDecoration(labelText: 'Active Ingredient'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceController,
                      decoration: const InputDecoration(
                          labelText: 'Cost Price (IDR) *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Cost required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _marginController,
                      decoration:
                          const InputDecoration(labelText: 'Margin % *'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Margin required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _baseUnitController,
                      decoration:
                          const InputDecoration(labelText: 'Base Unit *'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Unit required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _reorderThresholdController,
                      decoration: const InputDecoration(
                          labelText: 'Reorder Alert Qty'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Controlled Substance (Golongan Keras)'),
                value: _isControlled,
                onChanged: (val) => setState(() => _isControlled = val),
              ),
              if (_isControlled) ...[
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _controlledCategory ?? 'Narkotika',
                  decoration: const InputDecoration(
                      labelText: 'Controlled Substance Category'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Narkotika', child: Text('Narkotika')),
                    DropdownMenuItem(
                        value: 'Psikotropika', child: Text('Psikotropika')),
                    DropdownMenuItem(
                        value: 'Prekursor', child: Text('Prekursor')),
                    DropdownMenuItem(value: 'OOT', child: Text('OOT')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _controlledCategory = val);
                  },
                ),
              ],
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
          key: const Key('saveEditProductBtn'),
          onPressed: _saveProduct,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
