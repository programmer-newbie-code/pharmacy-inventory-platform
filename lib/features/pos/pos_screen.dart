import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../data/sale_repository.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_session.dart';
import '../inventory/camera_scanner_dialog.dart';
import 'cash_movement_dialog.dart';
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

  void _updateQuantity(int index, int delta) {
    setState(() {
      final existing = _cart[index];
      final newQty = existing.qtyBaseUnit + delta;
      if (newQty <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index] = CartItemInput(
          product: existing.product,
          qtyBaseUnit: newQty,
          unitPrice: existing.unitPrice,
        );
      }
    });
  }

  Future<void> _showEditCartItemDialog(int index) async {
    final l10n = AppLocalizations.of(context)!;
    final item = _cart[index];
    final prod = item.product;
    final bUnit = prod.baseUnit;
    final pUnit = prod.purchaseUnit;
    final ratio = prod.unitsPerPurchaseUnit > 0 ? prod.unitsPerPurchaseUnit : 1;

    int boxQty = item.qtyBaseUnit ~/ ratio;
    int tabQty = item.qtyBaseUnit % ratio;

    final boxController = TextEditingController(text: '$boxQty');
    final tabController = TextEditingController(text: '$tabQty');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final curBoxes = int.tryParse(boxController.text) ?? 0;
          final curTabs = int.tryParse(tabController.text) ?? 0;
          final totalBaseUnits = (curBoxes * ratio) + curTabs;
          final totalSubtotal = totalBaseUnits * item.unitPrice;

          return AlertDialog(
            title: Text(l10n.cartQuantityDialogTitle(prod.name)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.cartUnitRatio(pUnit, ratio, bUnit),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('inputBoxQty'),
                        controller: boxController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.cartQuantityForUnit(pUnit),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        key: const Key('inputBaseQty'),
                        controller: tabController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.cartQuantityForUnit(bUnit),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.cartTotal(totalBaseUnits, bUnit),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        formatIdr(totalSubtotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.cancelButton),
              ),
              ElevatedButton(
                key: const Key('saveCartItemQtyBtn'),
                onPressed: () {
                  if (totalBaseUnits > 0) {
                    setState(() {
                      _cart[index] = CartItemInput(
                        product: prod,
                        qtyBaseUnit: totalBaseUnits,
                        unitPrice: item.unitPrice,
                      );
                    });
                  } else {
                    _removeFromCart(index);
                  }
                  Navigator.of(ctx).pop();
                },
                child: Text(l10n.saveButton),
              ),
            ],
          );
        },
      ),
    );
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

  Future<bool> _promptOpenShiftModal() async {
    final l10n = AppLocalizations.of(context)!;
    final openingController = TextEditingController(text: '100000');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.posOpenShiftTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.posOpenShiftPrompt),
            const SizedBox(height: 12),
            TextField(
              key: const Key('posOpeningBalanceInput'),
              controller: openingController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.posOpeningBalanceLabel,
                prefixText: 'Rp ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            key: const Key('confirmPosOpenShiftBtn'),
            onPressed: () => Navigator.of(ctx).pop(openingController.text),
            child: Text(l10n.openShift),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final amount = double.tryParse(result) ?? 0.0;
      final shiftRepo = ref.read(cashierShiftRepositoryProvider);
      final currentUser = ref.read(authSessionProvider);
      await shiftRepo.openShift(
          cashierId: currentUser?.id ?? 1, openingBalance: amount);
      return true;
    }
    return false;
  }

  Future<void> _handlePosCashMovement() async {
    final currentUser = ref.read(authSessionProvider);
    var activeShift = await ref
        .read(cashierShiftRepositoryProvider)
        .getActiveShift(currentUser?.id ?? 1);
    if (activeShift == null) {
      final opened = await _promptOpenShiftModal();
      if (!opened) return;
      activeShift = await ref
          .read(cashierShiftRepositoryProvider)
          .getActiveShift(currentUser?.id ?? 1);
    }
    if (!mounted) return;
    if (activeShift != null) {
      showDialog(
        context: context,
        builder: (ctx) => CashMovementDialog(shiftId: activeShift!.id),
      );
    }
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;

    final currentUser = ref.read(authSessionProvider);
    var activeShift = await ref
        .read(cashierShiftRepositoryProvider)
        .getActiveShift(currentUser?.id ?? 1);
    if (activeShift == null) {
      final opened = await _promptOpenShiftModal();
      if (!opened) return;
    }

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

      final saleItems = await saleRepo.getSaleItemsForTransaction(txn.id);
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
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final supportsCameraScanner =
        Theme.of(context).platform != TargetPlatform.windows;
    final currentUser = ref.watch(authSessionProvider);
    final permChecker = ref.watch(permissionCheckerProvider);
    final canCheckout =
        currentUser == null || permChecker.canPerformCheckout(currentUser.role);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.posTitle),
        actions: [
          IconButton(
            key: const Key('posCashMovementBtn'),
            icon: const Icon(Icons.swap_horiz),
            tooltip: l10n.cashMovementButton,
            onPressed: _handlePosCashMovement,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Flex(
          direction:
              constraints.maxWidth < 700 ? Axis.vertical : Axis.horizontal,
          children: [
            // Left Side: Product Selector
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('posSearchInput'),
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: l10n.scanBarcode,
                              prefixIcon: const Icon(Icons.search),
                            ),
                            onChanged: (val) {
                              setState(() {});
                            },
                          ),
                        ),
                        if (supportsCameraScanner) ...[
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            key: const Key('cameraScanBtn'),
                            icon: const Icon(Icons.qr_code_scanner),
                            tooltip: l10n.scanCamera,
                            onPressed: () async {
                              final scanned =
                                  await CameraScannerDialog.scanBarcode(
                                      context);
                              if (scanned != null) {
                                _searchController.text = scanned;
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _allProducts.length,
                      itemBuilder: (ctx, idx) {
                        final p = _allProducts[idx];
                        if (_searchController.text.trim().isNotEmpty &&
                            !p.name.toLowerCase().contains(
                                _searchController.text.toLowerCase()) &&
                            !p.barcode.contains(_searchController.text)) {
                          return const SizedBox.shrink();
                        }
                        final price =
                            p.costPricePerBaseUnit * (1 + (p.marginPct / 100));

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            key: Key('productItem_${p.id}'),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.teal.shade50,
                              backgroundImage: p.imagePath != null &&
                                      File(p.imagePath!).existsSync()
                                  ? FileImage(File(p.imagePath!))
                                  : null,
                              child: p.imagePath == null ||
                                      !File(p.imagePath!).existsSync()
                                  ? const Icon(Icons.medication,
                                      size: 18, color: AppTheme.primaryColor)
                                  : null,
                            ),
                            title: Text(
                              p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              '${p.barcode} • ${formatIdr(price)} / ${p.baseUnit}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            trailing: IconButton(
                              key: Key('addToCart_${p.id}'),
                              icon: const Icon(Icons.add_shopping_cart,
                                  color: AppTheme.primaryColor),
                              tooltip: l10n.addProductToCart(p.name),
                              onPressed: () => _addToCart(p),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            constraints.maxWidth < 700
                ? const Divider(height: 1)
                : const VerticalDivider(width: 1),

            // Right Side: Cart Summary & Checkout
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    color: Colors.white,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: 8,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shopping_cart_outlined,
                                color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              l10n.shoppingCart,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_cart.length} ${l10n.items}',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _cart.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.remove_shopping_cart_outlined,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.cartEmpty,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _cart.length,
                            itemBuilder: (ctx, idx) {
                              final item = _cart[idx];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  key: Key('cartTile_$idx'),
                                  title: Text(
                                    item.product.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${formatIdr(item.unitPrice)} / ${item.product.baseUnit}',
                                      ),
                                      InkWell(
                                        key: Key('editCartQty_$idx'),
                                        onTap: () =>
                                            _showEditCartItemDialog(idx),
                                        child: Text(
                                          item.product.unitsPerPurchaseUnit >
                                                      1 &&
                                                  item.qtyBaseUnit >=
                                                      item.product
                                                          .unitsPerPurchaseUnit
                                              ? '${item.qtyBaseUnit ~/ item.product.unitsPerPurchaseUnit} ${item.product.purchaseUnit}'
                                                  '${item.qtyBaseUnit % item.product.unitsPerPurchaseUnit > 0 ? " + ${item.qtyBaseUnit % item.product.unitsPerPurchaseUnit} ${item.product.baseUnit}" : ""}'
                                              : '${item.qtyBaseUnit} ${item.product.baseUnit}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 20),
                                        onPressed: () =>
                                            _updateQuantity(idx, -1),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 20),
                                        onPressed: () =>
                                            _updateQuantity(idx, 1),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        formatIdr(item.subtotal),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      IconButton(
                                        key: Key('removeCart_$idx'),
                                        icon: const Icon(Icons.delete_outline,
                                            color: AppTheme.dangerColor),
                                        onPressed: () => _removeFromCart(idx),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (_hasControlledDrugInCart)
                    Container(
                      color: AppTheme.warningColor.withAlpha(15),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: AppTheme.warningColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  l10n.controlledDrugWarning,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.warningColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          CheckboxListTile(
                            key: const Key('hasPrescriptionCheckbox'),
                            title: Text(l10n.prescriptionVerified),
                            value: _hasPrescription,
                            onChanged: (val) =>
                                setState(() => _hasPrescription = val ?? false),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: const Key('doctorNameInput'),
                                  controller: _doctorController,
                                  decoration: InputDecoration(
                                    labelText: l10n.doctorName,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  key: const Key('patientNameInput'),
                                  controller: _patientController,
                                  decoration: InputDecoration(
                                    labelText: l10n.patientName,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _paymentMethod,
                                  items: [
                                    'Cash',
                                    'QRIS',
                                    'Card',
                                    'Bank Transfer',
                                    'Owner Use'
                                  ]
                                      .map((m) => DropdownMenuItem(
                                          value: m,
                                          child: Text(m == 'Owner Use'
                                              ? 'Owner Use (Rp 0)'
                                              : m)))
                                      .toList(),
                                  onChanged: (val) => setState(
                                      () => _paymentMethod = val ?? 'Cash'),
                                ),
                              ),
                            ),
                            Text(
                              _paymentMethod == 'Owner Use'
                                  ? 'Rp 0 (Owner Use)'
                                  : formatIdr(_totalCartAmount),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _paymentMethod == 'Owner Use'
                                    ? Colors.orange.shade800
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            key: const Key('checkoutButton'),
                            onPressed:
                                _isLoading || _cart.isEmpty || !canCheckout
                                    ? null
                                    : _checkout,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.point_of_sale),
                            label: Text(l10n.completeSale),
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
      ),
    );
  }
}
