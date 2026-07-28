import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/database.dart';
import 'add_product_dialog.dart';
import 'add_stock_batch_dialog.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  List<Product> _products = [];
  Map<int, int> _stockMap = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    final repo = ref.read(productRepositoryProvider);
    final batchRepo = ref.read(stockBatchRepositoryProvider);

    final list = await repo.listProducts(
      searchQuery: _searchController.text.trim(),
    );

    final stockMap = <int, int>{};
    for (final prod in list) {
      stockMap[prod.id] = await batchRepo.getTotalStockForProduct(prod.id);
    }

    setState(() {
      _products = list;
      _stockMap = stockMap;
      _isLoading = false;
    });
  }

  Future<void> _openAddProduct() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => const AddProductDialog(),
    );
    if (added == true) {
      _fetchProducts();
    }
  }

  Future<void> _openAddBatch(Product product) async {
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AddStockBatchDialog(product: product),
    );
    if (added == true) {
      _fetchProducts();
    }
  }

  Future<void> _openImportCsvDialog() async {
    final csvController = TextEditingController(
      text: 'Barcode,InternalCode,ProductName,ActiveIngredient,BaseUnit,PurchaseUnit,UnitsPerPurchaseUnit,CostPrice,MarginPct,ReorderThreshold,Category,IsControlled\n'
            '899123456701,P001,Amoxicillin 500mg,Amoxicillin,tablet,box,100,500,20,50,Obat Keras,true\n'
            '899123456702,P002,Paracetamol 500mg,Paracetamol,tablet,box,100,200,25,30,Obat Bebas,false',
    );

    final importContent = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Inventory CSV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste or edit CSV spreadsheet rows below:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('csvTextInput'),
              controller: csvController,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Barcode,InternalCode,ProductName,...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('submitCsvImportBtn'),
            onPressed: () => Navigator.of(ctx).pop(csvController.text),
            child: const Text('Import Products'),
          ),
        ],
      ),
    );

    if (importContent != null && importContent.isNotEmpty) {
      final csvService = ref.read(csvImportServiceProvider);
      final result = await csvService.importProductsFromCsv(importContent);
      _fetchProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported ${result.successCount} products successfully (${result.failedCount} failed).',
            ),
            backgroundColor: result.failedCount == 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Catalog'),
        actions: [
          IconButton(
            key: const Key('importCsvBtn'),
            icon: const Icon(Icons.file_upload),
            tooltip: 'Import Inventory CSV',
            onPressed: _openImportCsvDialog,
          ),
          IconButton(
            key: const Key('refreshButton'),
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              key: const Key('productSearchInput'),
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search product by name or barcode',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _fetchProducts();
                  },
                ),
              ),
              onSubmitted: (_) => _fetchProducts(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('No products found.'))
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (ctx, idx) {
                          final prod = _products[idx];
                          final stock = _stockMap[prod.id] ?? 0;
                          final isLow = stock <= prod.reorderThreshold;

                          return ListTile(
                            key: Key('productTile_${prod.id}'),
                            title: Text(
                              prod.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${prod.barcode} | ${prod.category} | ${prod.baseUnit} | Stock: $stock ${prod.baseUnit}s',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (prod.isControlled)
                                  const Chip(
                                    label: Text('Obat Keras'),
                                    backgroundColor: Colors.redAccent,
                                    labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                if (isLow)
                                  const Icon(Icons.warning, color: Colors.orange),
                                IconButton(
                                  key: Key('addBatchBtn_${prod.id}'),
                                  icon: const Icon(Icons.add_shopping_cart),
                                  tooltip: 'Receive Stock',
                                  onPressed: () => _openAddBatch(prod),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addProductFab'),
        onPressed: _openAddProduct,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}
