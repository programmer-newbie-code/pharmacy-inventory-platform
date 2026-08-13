import 'dart:io';
import 'package:drift/drift.dart' hide Column, isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../data/media_storage_service.dart';
import '../../core/unit_constants.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';

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
  late TextEditingController _purchaseUnitController;
  late TextEditingController _unitsPerPurchaseUnitController;
  late TextEditingController _costPriceController;
  late TextEditingController _purchaseUnitPriceController;
  late TextEditingController _marginController;
  late TextEditingController _reorderThresholdController;

  late bool _isControlled;
  String? _controlledCategory;
  late String _category;
  String? _imagePath;

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
    _purchaseUnitController = TextEditingController(text: p.purchaseUnit);
    _unitsPerPurchaseUnitController =
        TextEditingController(text: p.unitsPerPurchaseUnit.toString());
    _costPriceController =
        TextEditingController(text: p.costPricePerBaseUnit.toString());

    final initialPurchasePrice =
        p.costPricePerBaseUnit * p.unitsPerPurchaseUnit;
    _purchaseUnitPriceController =
        TextEditingController(text: initialPurchasePrice.toStringAsFixed(0));

    _marginController = TextEditingController(text: p.marginPct.toString());
    _reorderThresholdController =
        TextEditingController(text: p.reorderThreshold.toString());
    _isControlled = p.isControlled;
    _controlledCategory = p.controlledCategory;
    _category = p.category;
    _imagePath = p.imagePath;
  }

  Future<void> _pickProductImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final path = await MediaStorageService().saveImage(
        picked.path,
        folder: 'products',
      );
      if (mounted) setState(() => _imagePath = path);
    }
  }

  void _onPurchasePriceChanged(String val) {
    final purchasePrice = double.tryParse(val) ?? 0.0;
    final units = int.tryParse(_unitsPerPurchaseUnitController.text) ?? 1;
    if (units > 0) {
      final basePrice = purchasePrice / units;
      _costPriceController.value = TextEditingValue(
        text: basePrice == basePrice.roundToDouble()
            ? basePrice.toStringAsFixed(0)
            : basePrice.toStringAsFixed(2),
      );
      setState(() {});
    }
  }

  void _onBasePriceChanged(String val) {
    final basePrice = double.tryParse(val) ?? 0.0;
    final units = int.tryParse(_unitsPerPurchaseUnitController.text) ?? 1;
    if (units > 0) {
      final purchasePrice = basePrice * units;
      _purchaseUnitPriceController.value = TextEditingValue(
        text: purchasePrice == purchasePrice.roundToDouble()
            ? purchasePrice.toStringAsFixed(0)
            : purchasePrice.toStringAsFixed(2),
      );
      setState(() {});
    }
  }

  void _onUnitsChanged(String val) {
    _onPurchasePriceChanged(_purchaseUnitPriceController.text);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _activeIngredientController.dispose();
    _ingredientPctController.dispose();
    _baseUnitController.dispose();
    _purchaseUnitController.dispose();
    _unitsPerPurchaseUnitController.dispose();
    _costPriceController.dispose();
    _purchaseUnitPriceController.dispose();
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
      purchaseUnit: _purchaseUnitController.text.trim(),
      unitsPerPurchaseUnit:
          int.tryParse(_unitsPerPurchaseUnitController.text) ?? 1,
      costPricePerBaseUnit: double.tryParse(_costPriceController.text) ??
          widget.product.costPricePerBaseUnit,
      marginPct:
          double.tryParse(_marginController.text) ?? widget.product.marginPct,
      reorderThreshold: int.tryParse(_reorderThresholdController.text) ??
          widget.product.reorderThreshold,
      isControlled: _isControlled,
      controlledCategory: Value(_isControlled ? _controlledCategory : null),
      category: _category,
      imagePath: Value(_imagePath),
      updatedBy: const Value('admin'),
    );

    await repo.updateProduct(updated, updatedBy: 'admin');

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: const Text('Edit Product Details'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickProductImage,
                child: Container(
                  height: 90,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _imagePath != null && File(_imagePath!).existsSync()
                      ? Stack(
                          children: [
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(File(_imagePath!),
                                    fit: BoxFit.contain, height: 90),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                icon:
                                    const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () =>
                                    setState(() => _imagePath = null),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate,
                                size: 30, color: AppTheme.primaryColor),
                            const SizedBox(height: 4),
                            Text(l10n.productImageEdit,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('editProductNameInput'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _activeIngredientController,
                      decoration: const InputDecoration(
                          labelText: 'Active Ingredient *'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Ingredient required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ingredientPctController,
                      decoration: const InputDecoration(labelText: 'Pct (%) *'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Pct required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Units row ───────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: EditableUnitDropdown(
                      widgetKey: const Key('editBaseUnitDropdown'),
                      controller: _baseUnitController,
                      labelText: l10n.baseUnitLabel,
                      defaultOptions: defaultBaseUnits,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Wajib' : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: EditableUnitDropdown(
                      widgetKey: const Key('editPurchaseUnitDropdown'),
                      controller: _purchaseUnitController,
                      labelText: l10n.purchaseUnitLabel,
                      defaultOptions: defaultPurchaseUnits,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Wajib' : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unitsPerPurchaseUnitController,
                decoration: InputDecoration(
                  labelText: l10n.unitsPerPurchaseUnitLabel,
                  suffixText: _baseUnitController.text,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: _onUnitsChanged,
                validator: (v) => (v == null || int.tryParse(v) == null)
                    ? 'Angka tidak valid'
                    : null,
              ),
              const SizedBox(height: 12),

              // ── Price row (Dual Box vs Tablet Calculation) ───────────────
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
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Cost required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Price Conversion Live Breakdown Card ──────────────────────
              Builder(builder: (ctx) {
                final purchasePrice =
                    double.tryParse(_purchaseUnitPriceController.text) ?? 0.0;
                final basePrice =
                    double.tryParse(_costPriceController.text) ?? 0.0;
                final units =
                    int.tryParse(_unitsPerPurchaseUnitController.text) ?? 1;
                final pUnit = _purchaseUnitController.text.trim().isEmpty
                    ? 'box'
                    : _purchaseUnitController.text.trim();
                final bUnit = _baseUnitController.text.trim().isEmpty
                    ? 'tablet'
                    : _baseUnitController.text.trim();

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppTheme.primaryColor.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calculate,
                          size: 18, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.conversionBreakdownHint(
                            pUnit,
                            units,
                            bUnit,
                            formatIdr(purchasePrice).replaceAll('Rp ', ''),
                            formatIdr(basePrice).replaceAll('Rp ', ''),
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),

              Row(
                children: [
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _reorderThresholdController,
                      decoration:
                          const InputDecoration(labelText: 'Reorder Alert Qty'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(l10n.controlledSubstance),
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
