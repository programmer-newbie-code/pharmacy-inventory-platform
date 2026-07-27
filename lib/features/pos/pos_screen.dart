import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/database.dart';
import '../../data/sale_repository.dart';
import 'receipt_dialog.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  final _patientController = TextEditingController();
  final _doctorController = TextEditingController();

  List<Product> _allProducts = [];
  final List<CartItemInput> _cart = [];
  String _paymentMethod = 'Cash';
  bool _hasPrescription = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _patientController.dispose();
    _doctorController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final list = await ref.read(productRepositoryProvider).listProducts();
    setState(() {
      _allProducts = list;
    });
  }

  void _addToCart(Product product) {
    // Default selling price = cost price * (1 + marginPct / 100)
    final defaultPrice =
        product.costPricePerBaseUnit * (1 + (product.marginPct / 100));

    final existingIdx =
        _cart.indexWhere((item) => item.product.id == product.id);
    setState(() {
      if (existingIdx >= 0) {
        final existing = _cart[existingIdx];
        _cart[existingIdx] = CartItemInput(
          product: product,
          qtyBaseUnit: existing.qtyBaseUnit + 1,
          unitPrice: existing.unitPrice,
        );
      } else {
        _cart.add(CartItemInput(
          product: product,
          qtyBaseUnit: 1,
          unitPrice: defaultPrice,
        ));
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  double get _totalCartAmount {
    return _cart.fold(0, (sum, item) => sum + item.subtotal);
  }

  bool get _hasControlledDrugInCart {
    return _cart.any((item) => item.product.isControlled);
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final saleRepo = ref.read(saleRepositoryProvider);
      final txn = await saleRepo.createSaleTransaction(
        cashierId: 1,
        items: _cart,
        paymentMethod: _paymentMethod,
        patientName: _patientController.text.trim().isEmpty
            ? null
            : _patientController.text.trim(),
        doctorName: _doctorController.text.trim().isEmpty
            ? null
            : _doctorController.text.trim(),
        hasPrescription: _hasPrescription,
      );

      final saleItems =
          await saleRepo.getSaleItemsForTransaction(txn.id);
      final prodMap = {for (var p in _allProducts) p.id: p};

      setState(() {
        _cart.clear();
        _patientController.clear();
        _doctorController.clear();
        _hasPrescription = false;
        _isLoading = false;
      });

      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => ReceiptDialog(
            transaction: txn,
            items: saleItems,
            productsMap: prodMap,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Sales Counter'),
      ),
      body: Row(
        children: [
          // Left Side: Product Selector
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    key: const Key('posSearchInput'),
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Scan barcode or search product',
                      prefixIcon: Icon(Icons.qr_code_scanner),
                    ),
                    onChanged: (val) {
                      setState(() {});
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _allProducts.length,
                    itemBuilder: (ctx, idx) {
                      final p = _allProducts[idx];
                      if (_searchController.text.trim().isNotEmpty &&
                          !p.name.toLowerCase().contains(_searchController.text.toLowerCase()) &&
                          !p.barcode.contains(_searchController.text)) {
                        return const SizedBox.shrink();
                      }
                      final price = p.costPricePerBaseUnit * (1 + (p.marginPct / 100));

                      return ListTile(
                        key: Key('productItem_${p.id}'),
                        title: Text(p.name),
                        subtitle: Text('${p.barcode} | Rp ${price.toStringAsFixed(0)} / ${p.baseUnit}'),
                        trailing: IconButton(
                          key: Key('addToCart_${p.id}'),
                          icon: const Icon(Icons.add_shopping_cart, color: Colors.blue),
                          onPressed: () => _addToCart(p),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),

          // Right Side: Cart Summary & Checkout
          Expanded(
            flex: 6,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey.shade100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Shopping Cart',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text('${_cart.length} items'),
                    ],
                  ),
                ),
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(child: Text('Cart is empty. Select products to add.'))
                      : ListView.builder(
                          itemCount: _cart.length,
                          itemBuilder: (ctx, idx) {
                            final item = _cart[idx];
                            return ListTile(
                              key: Key('cartTile_$idx'),
                              title: Text(item.product.name),
                              subtitle: Text(
                                '${item.qtyBaseUnit} ${item.product.baseUnit}s @ Rp ${item.unitPrice.toStringAsFixed(0)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Rp ${item.subtotal.toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    key: Key('removeCart_$idx'),
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeFromCart(idx),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                if (_hasControlledDrugInCart)
                  Container(
                    color: Colors.amber.shade50,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.deepOrange),
                            SizedBox(width: 4),
                            Text(
                              'Controlled Drug Detected (Prescription Required)',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                            ),
                          ],
                        ),
                        CheckboxListTile(
                          key: const Key('hasPrescriptionCheckbox'),
                          title: const Text('Prescription Verified'),
                          value: _hasPrescription,
                          onChanged: (val) => setState(() => _hasPrescription = val ?? false),
                        ),
                        TextFormField(
                          key: const Key('doctorNameInput'),
                          controller: _doctorController,
                          decoration: const InputDecoration(labelText: 'Doctor Name'),
                        ),
                        TextFormField(
                          key: const Key('patientNameInput'),
                          controller: _patientController,
                          decoration: const InputDecoration(labelText: 'Patient Name'),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          DropdownButton<String>(
                            value: _paymentMethod,
                            items: ['Cash', 'QRIS', 'Card', 'Bank Transfer']
                                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                                .toList(),
                            onChanged: (val) => setState(() => _paymentMethod = val ?? 'Cash'),
                          ),
                          Text(
                            'Rp ${_totalCartAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          key: const Key('checkoutButton'),
                          onPressed: _isLoading || _cart.isEmpty ? null : _checkout,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.point_of_sale),
                          label: const Text('Complete Sale (Checkout)'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
