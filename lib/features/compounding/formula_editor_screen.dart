import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/compounding_repository.dart';
import '../../data/database.dart';

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
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formula name is required.')),
      );
      return;
    }

    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one ingredient.')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Compounding Formula'),
        actions: [
          TextButton(
            key: const Key('saveFormulaBtn'),
            onPressed: _saveFormula,
            child: const Text('Save'),
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
                  const InputDecoration(labelText: 'Formula Name *'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _dosageForm,
                    decoration: const InputDecoration(labelText: 'Dosage Form'),
                    items: const [
                      DropdownMenuItem(value: 'puyer', child: Text('Puyer (Powder)')),
                      DropdownMenuItem(value: 'kapsul', child: Text('Kapsul (Capsule)')),
                      DropdownMenuItem(value: 'salep', child: Text('Salep (Ointment)')),
                      DropdownMenuItem(value: 'sirup', child: Text('Sirup (Syrup)')),
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
                        const InputDecoration(labelText: 'Yield Qty'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _yieldUnitController,
                    decoration:
                        const InputDecoration(labelText: 'Yield Unit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            // Product selector dropdown
            if (_isLoadingProducts)
              const CircularProgressIndicator()
            else
              DropdownButtonFormField<Product>(
                decoration: const InputDecoration(
                  labelText: 'Add Component Drug',
                  border: OutlineInputBorder(),
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
