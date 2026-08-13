import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/compounding_repository.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';

class FormulaEditorScreen extends ConsumerStatefulWidget {
  const FormulaEditorScreen({super.key});

  @override
  ConsumerState<FormulaEditorScreen> createState() =>
      _FormulaEditorScreenState();
}

class _IngredientLine {
  _IngredientLine({required this.product});

  final Product product;
  final TextEditingController qtyController = TextEditingController(text: '1');
}

class _FormulaEditorScreenState extends ConsumerState<FormulaEditorScreen> {
  final _nameController = TextEditingController();
  final _yieldQtyController = TextEditingController(text: '10');
  final _yieldUnitController = TextEditingController(text: 'bungkus');
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  String _dosageForm = 'puyer';
  List<Product> _availableProducts = [];
  final List<_IngredientLine> _ingredients = [];
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yieldQtyController.dispose();
    _yieldUnitController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    for (final ing in _ingredients) {
      ing.qtyController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final list = await ref.read(productRepositoryProvider).listProducts();
    if (!mounted) return;
    setState(() {
      _availableProducts = list;
      _isLoadingProducts = false;
    });
  }

  void _addIngredient(Product p) {
    if (_ingredients.any((ing) => ing.product.id == p.id)) return;
    setState(() {
      _ingredients.add(_IngredientLine(product: p));
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients[index].qtyController.dispose();
      _ingredients.removeAt(index);
    });
  }

  Future<void> _saveFormula() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.formulaNameRequired)),
      );
      return;
    }

    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.addAtLeastOneIngredient)),
      );
      return;
    }

    final repo = ref.read(compoundingRepositoryProvider);
    final ingInputs = _ingredients.map((ing) {
      final qty = double.tryParse(ing.qtyController.text) ?? 1.0;
      return IngredientInput(
        productId: ing.product.id,
        qtyPerYield: qty,
      );
    }).toList();

    await repo.createFormula(
      name: _nameController.text.trim(),
      dosageForm: _dosageForm,
      yieldQuantity: int.tryParse(_yieldQtyController.text) ?? 10,
      yieldUnit: _yieldUnitController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      preparationNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      ingredients: ingInputs,
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newFormulaTitle),
        actions: [
          TextButton(
            key: const Key('saveFormulaBtn'),
            onPressed: _saveFormula,
            child: Text(l10n.saveButton),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('formulaNameInput'),
              controller: _nameController,
              decoration:
                  InputDecoration(labelText: l10n.formulaNameLabel),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _dosageForm,
                    decoration: InputDecoration(labelText: l10n.dosageFormLabel),
                    items: [
                      DropdownMenuItem(value: 'puyer', child: Text(l10n.formPuyer)),
                      DropdownMenuItem(value: 'kapsul', child: Text(l10n.formCapsule)),
                      DropdownMenuItem(value: 'salep', child: Text(l10n.formOintment)),
                      DropdownMenuItem(value: 'sirup', child: Text(l10n.formSyrup)),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _dosageForm = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _yieldQtyController,
                    decoration:
                        InputDecoration(labelText: l10n.yieldQtyLabel),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _yieldUnitController,
                    decoration:
                        InputDecoration(labelText: l10n.yieldUnitLabel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.ingredientsHeader, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            // Product selector dropdown
            if (_isLoadingProducts)
              const CircularProgressIndicator()
            else
              DropdownButtonFormField<Product>(
                decoration: InputDecoration(
                  labelText: l10n.addComponentDrugButton,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: _availableProducts.map((p) {
                  return DropdownMenuItem<Product>(
                    value: p,
                    child: Text('${p.name} (${p.baseUnit})'),
                  );
                }).toList(),
                onChanged: (p) {
                  if (p != null) _addIngredient(p);
                },
              ),
            const SizedBox(height: 12),
            // Ingredients list
            ..._ingredients.asMap().entries.map((entry) {
              final idx = entry.key;
              final ing = entry.value;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(ing.product.name),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: ing.qtyController,
                          decoration: InputDecoration(
                            labelText: 'Qty (${ing.product.baseUnit})',
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeIngredient(idx),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
