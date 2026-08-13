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
                          // The name gets the tile's full width and can wrap to
                          // two lines instead of truncating. The 'Obat Keras'
                          // badge and edit icon previously left only ~179dp for
                          // a name that can need ~175dp or more, so it broke
                          // with any longer name or text scaling. The badge
                          // moves into the subtitle row instead of sharing the
                          // title's width.
                          title: Text(
                            prod.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (prod.isControlled)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.golonganKeras.withAlpha(25),
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
                                // A single RichText, not a nested Row: Wrap
                                // constrains each child to its own max width,
                                // and an atomic Row cannot reflow internally,
                                // so it overflowed by 69dp once the name's
                                // 2-line wrap left this run narrower than
                                // 'Stok: 20 kapsul' at bold weight needs.
                                // RichText keeps the two-weight styling in one
                                // flowable Wrap child instead.
                                RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(ctx).style,
                                    children: [
                                      TextSpan(
                                        text: '${l10n.stockLabel}: ',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '$stock ${prod.baseUnit}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isLow
                                              ? AppTheme.warningColor
                                              : AppTheme.successColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isLow)
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 16,
                                    color: AppTheme.warningColor,
                                  ),
                                // Actions moved here from `trailing`, which
                                // previously reserved ~96dp on every row for
                                // two full-size IconButtons. Even the longest
                                // real catalog name (33 characters) did not
                                // fit the name in 2 lines once that space was
                                // taken from a 393dp-wide phone. They join the
                                // Wrap as compact icon-only buttons instead.
                                if (canCreate) ...[
                                  InkWell(
                                    key: Key('editProdBtn_${prod.id}'),
                                    onTap: () => _openEditProduct(prod),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Tooltip(
                                      message: l10n.editProductTooltip,
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(Icons.edit_outlined,
                                            size: 18,
                                            color: Colors.grey.shade700),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    key: Key('addBatchBtn_${prod.id}'),
                                    onTap: () => _openAddBatch(prod),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Tooltip(
                                      message: l10n.receiveStock,
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.add_shopping_cart,
                                            size: 18,
                                            color: AppTheme.primaryColor),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
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
