import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../data/product_repository.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_session.dart';
import 'add_product_dialog.dart';
import 'add_stock_batch_dialog.dart';
import 'edit_product_dialog.dart';
import 'csv_import_dialog.dart';
import 'csv_import_history_dialog.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<ProductStockSummary> _products = [];
  bool _isLoading = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    final requestId = ++_requestId;
    setState(() => _isLoading = true);
    final repo = ref.read(productRepositoryProvider);
    final list = await repo.listProductsWithStock(
      searchQuery: _searchController.text.trim(),
    );

    if (!mounted || requestId != _requestId) return;
    setState(() {
      _products = list;
      _isLoading = false;
    });
  }

  void _scheduleSearch(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), _fetchProducts);
  }

  void _clearSearch() {
    _searchController.clear();
    _fetchProducts();
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

  Future<void> _openEditProduct(Product product) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => EditProductDialog(product: product),
    );
    if (updated == true) {
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
    final imported = await showDialog<bool>(
      context: context,
      builder: (ctx) => const CsvImportDialog(),
    );
    if (imported == true) {
      _fetchProducts();
    }
  }

  Future<void> _openImportHistory() => showDialog<void>(
    context: context,
    builder: (_) => const CsvImportHistoryDialog(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(authSessionProvider);
    final permChecker = ref.watch(permissionCheckerProvider);
    final canCreate =
        currentUser == null || permChecker.canCreateProducts(currentUser.role);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventoryTitle),
        actions: [
          if (canCreate)
            IconButton(
              key: const Key('importCsvBtn'),
              icon: const Icon(Icons.file_upload_outlined),
              tooltip: l10n.importCsvButton,
              onPressed: _openImportCsvDialog,
            ),
          IconButton(
            key: const Key('csvImportHistoryBtn'),
            icon: const Icon(Icons.history),
            tooltip: l10n.csvImportHistoryButton,
            onPressed: _openImportHistory,
          ),
          IconButton(
            key: const Key('refreshButton'),
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refreshProducts,
            onPressed: _fetchProducts,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              key: const Key('productSearchInput'),
              controller: _searchController,
              decoration: InputDecoration(
                labelText: l10n.searchProductHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: l10n.clearSearchButton,
                  onPressed: _clearSearch,
                ),
              ),
              onChanged: _scheduleSearch,
              onSubmitted: (_) => _fetchProducts(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchController.text.trim().isEmpty
                              ? l10n.noProductsFound
                              : l10n.noProductsFoundForQuery(
                                  _searchController.text.trim(),
                                ),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        if (_searchController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: const Key('clearSearchEmptyStateBtn'),
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.clear),
                            label: Text(l10n.clearSearchButton),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (ctx, idx) {
                      final summary = _products[idx];
                      final prod = summary.product;
                      final stock = summary.stock;
                      final isLow = stock <= prod.reorderThreshold;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          key: Key('productTile_${prod.id}'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.teal.shade50,
                            backgroundImage: prod.imagePath != null &&
                                    File(prod.imagePath!).existsSync()
                                ? FileImage(File(prod.imagePath!))
                                : null,
                            child: prod.imagePath == null ||
                                    !File(prod.imagePath!).existsSync()
                                ? const Icon(Icons.medication,
                                    color: AppTheme.primaryColor)
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  prod.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (prod.isControlled)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.golonganKeras.withAlpha(25),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppTheme.golonganKeras.withAlpha(
                                        80,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.obatKeras,
                                    style: const TextStyle(
                                      color: AppTheme.golonganKeras,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  prod.barcode,
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                Text(
                                  '•',
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                                Text(
                                  prod.category,
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                Text(
                                  '•',
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${l10n.stockLabel}: ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '$stock ${prod.baseUnit}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isLow
                                            ? AppTheme.warningColor
                                            : AppTheme.successColor,
                                      ),
                                    ),
                                    if (isLow) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        size: 16,
                                        color: AppTheme.warningColor,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          trailing: canCreate
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      key: Key('editProdBtn_${prod.id}'),
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: 'Edit Product',
                                      onPressed: () => _openEditProduct(prod),
                                    ),
                                    IconButton(
                                      key: Key('addBatchBtn_${prod.id}'),
                                      icon: const Icon(
                                        Icons.add_shopping_cart,
                                        color: AppTheme.primaryColor,
                                      ),
                                      tooltip: l10n.receiveStock,
                                      onPressed: () => _openAddBatch(prod),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              key: const Key('addProductFab'),
              onPressed: _openAddProduct,
              icon: const Icon(Icons.add),
              label: Text(l10n.addProductButton),
            )
          : null,
    );
  }
}
