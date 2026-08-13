import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../data/media_storage_service.dart';
import '../../core/unit_constants.dart';
import '../../data/database.dart';
import '../../data/drug_lookup_service.dart';
import '../../l10n/app_localizations.dart';
import 'camera_scanner_dialog.dart';

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
  final _purchaseUnitPriceController = TextEditingController(text: '10000.0');
  final _marginPctController = TextEditingController(text: '20.0');
  final _reorderThresholdController = TextEditingController(text: '50');
  final _categoryController = TextEditingController(text: 'Obat Bebas');
  final _drugSearchController = TextEditingController();

  bool _isControlled = false;
  int? _selectedStorageLocationId;
  List<StorageLocation> _locations = [];
  String? _imagePath;

  // Drug search state
  bool _isSearching = false;
  List<DrugLookupResult> _searchResults = [];
  bool _searchPanelOpen = false;

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
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final locs =
        await ref.read(productRepositoryProvider).listStorageLocations();
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
    _purchaseUnitPriceController.dispose();
    _marginPctController.dispose();
    _reorderThresholdController.dispose();
    _categoryController.dispose();
    _drugSearchController.dispose();
    super.dispose();
  }

  Future<void> _runDrugSearch(String query) async {
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final service = ref.read(drugLookupServiceProvider);
      final results = await service.search(query);
      if (mounted) setState(() => _searchResults = results);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  /// Auto-fills all form fields from a selected drug lookup result.
  void _applyDrugResult(DrugLookupResult drug) {
    _nameController.text = drug.name;
    _activeIngredientController.text = drug.activeIngredient;
    _categoryController.text = drug.category;
    _baseUnitController.text = drug.unit;
    if (_purchaseUnitController.text.trim().isEmpty) {
      _purchaseUnitController.text = 'box';
    }
    _onUnitsChanged(_unitsPerPurchaseUnitController.text);
    _isControlled = drug.requiresPrescription;
    _drugSearchController.clear();
    setState(() {
      _searchResults = [];
      _searchPanelOpen = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Auto-filled from ${drug.source == DrugSource.bpom ? 'BPOM' : 'database lokal'}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      unitsPerPurchaseUnit:
          int.parse(_unitsPerPurchaseUnitController.text.trim()),
      costPricePerBaseUnit: double.parse(_costPriceController.text.trim()),
      marginPct: double.parse(_marginPctController.text.trim()),
      reorderThreshold: int.parse(_reorderThresholdController.text.trim()),
      isControlled: _isControlled,
      storageLocationId: _selectedStorageLocationId,
      category: _categoryController.text.trim(),
      createdBy: 'admin',
      imagePath: _imagePath,
    );

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isWindows = Platform.isWindows;

    return AlertDialog(
      title: Text(l10n.addProductTitle),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Drug Lookup Panel ───────────────────────────────────────
                _DrugLookupPanel(
                  controller: _drugSearchController,
                  isSearching: _isSearching,
                  results: _searchResults,
                  isOpen: _searchPanelOpen,
                  onToggle: () =>
                      setState(() => _searchPanelOpen = !_searchPanelOpen),
                  onQueryChanged: _runDrugSearch,
                  onResultSelected: _applyDrugResult,
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 4),

                // ── Product Image Picker ──────────────────────────────────────
                GestureDetector(
                  onTap: _pickProductImage,
                  child: Container(
                    height: 90,
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
                                  icon: const Icon(Icons.cancel,
                                      color: Colors.red),
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
                              Text(l10n.productImageOptional,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Product Name ────────────────────────────────────────────
                TextFormField(
                  key: const Key('productNameInput'),
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.productNameRequired,
                    prefixIcon: const Icon(Icons.medication),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 8),

                // ── Barcode ─────────────────────────────────────────────────
                TextFormField(
                  key: const Key('productBarcodeInput'),
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    labelText: l10n.barcodeLabel,
                    prefixIcon: const Icon(Icons.barcode_reader),
                    suffixIcon: isWindows
                        ? null
                        : IconButton(
                            key: const Key('cameraScanBarcodeBtn'),
                            icon: const Icon(Icons.qr_code_scanner),
                            tooltip: l10n.scanBarcodeCamera,
                            onPressed: () async {
                              final scanned =
                                  await CameraScannerDialog.scanBarcode(
                                      context);
                              if (scanned != null) {
                                _barcodeController.text = scanned;
                              }
                            },
                          ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? l10n.fieldRequired : null,
                ),
                if (isWindows)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.windowsScannerGuidance,
                      style: TextStyle(color: cs.outline, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),

                // ── Internal Code ───────────────────────────────────────────
                TextFormField(
                  key: const Key('productInternalCodeInput'),
                  controller: _internalCodeController,
                  decoration: InputDecoration(
                    labelText: l10n.internalCodeLabel,
                    prefixIcon: const Icon(Icons.tag),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 8),

                // ── Active Ingredient ───────────────────────────────────────
                TextFormField(
                  key: const Key('activeIngredientInput'),
                  controller: _activeIngredientController,
                  decoration: InputDecoration(
                    labelText: l10n.activeIngredientLabel,
                    prefixIcon: const Icon(Icons.science),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Category ────────────────────────────────────────────────
                DropdownButtonFormField<String>(
                  initialValue: _categoryController.text.isEmpty
                      ? 'Obat Bebas'
                      : _categoryController.text,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.drugClassLabel,
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: 'Obat Bebas', child: Text(l10n.drugClassOtc)),
                    DropdownMenuItem(
                        value: 'Obat Bebas Terbatas',
                        child: Text(l10n.drugClassOtcLimited)),
                    DropdownMenuItem(
                        value: 'Obat Keras',
                        child: Text(l10n.drugClassPrescription)),
                    DropdownMenuItem(
                        value: 'Psikotropika', child: Text(l10n.categoryPsychotropic)),
                    DropdownMenuItem(
                        value: 'Narkotika', child: Text(l10n.categoryNarcotic)),
                    DropdownMenuItem(
                        value: 'Herbal / Jamu', child: Text(l10n.categoryHerbal)),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      _categoryController.text = val;
                      setState(() {
                        _isControlled = val == 'Obat Keras' ||
                            val == 'Psikotropika' ||
                            val == 'Narkotika';
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),

                // ── Units row ───────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: EditableUnitDropdown(
                        widgetKey: const Key('baseUnitDropdown'),
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
                        widgetKey: const Key('purchaseUnitDropdown'),
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
                        key: const Key('purchaseUnitPriceInput'),
                        controller: _purchaseUnitPriceController,
                        decoration: InputDecoration(
                          labelText: l10n.pricePerPurchaseUnitLabel,
                          prefixText: l10n.currencyPrefix,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: _onPurchasePriceChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        key: const Key('costPricePerBaseUnitInput'),
                        controller: _costPriceController,
                        decoration: InputDecoration(
                          labelText: l10n.costPricePerBaseUnitLabel,
                          prefixText: l10n.currencyPrefix,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: _onBasePriceChanged,
                        validator: (v) =>
                            (v == null || double.tryParse(v) == null)
                                ? l10n.fieldRequired
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
                      border: Border.all(
                          color: AppTheme.primaryColor.withAlpha(40)),
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
                        controller: _marginPctController,
                        decoration: InputDecoration(
                          labelText: l10n.marginPctLabel,
                          suffixText: '%',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _reorderThresholdController,
                        decoration: InputDecoration(
                          labelText: l10n.minStockLabel,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Storage location ─────────────────────────────────────────
                if (_locations.isNotEmpty) ...[
                  DropdownButtonFormField<int>(
                    initialValue: _selectedStorageLocationId,
                    decoration: InputDecoration(
                      labelText: l10n.storageLocationLabel,
                      prefixIcon: const Icon(Icons.shelves),
                    ),
                    items: _locations
                        .map((loc) => DropdownMenuItem<int>(
                              value: loc.id,
                              child: Text('${loc.code} - ${loc.name}'),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedStorageLocationId = val),
                  ),
                  const SizedBox(height: 8),
                ],

                // ── Controlled toggle ─────────────────────────────────────────
                CheckboxListTile(
                  key: const Key('isControlledCheckbox'),
                  title: Text(l10n.controlledToggleTitle),
                  subtitle:
                      _isControlled ? Text(l10n.controlledToggleNote) : null,
                  secondary: Icon(
                    Icons.lock_outline,
                    color: _isControlled ? cs.error : cs.outline,
                  ),
                  value: _isControlled,
                  tileColor: _isControlled
                      ? cs.errorContainer.withAlpha(80)
                      : cs.surfaceContainerHighest.withAlpha(60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onChanged: (val) =>
                      setState(() => _isControlled = val ?? false),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancelButton),
        ),
        FilledButton.icon(
          key: const Key('saveProductButton'),
          icon: const Icon(Icons.save_outlined, size: 18),
          label: Text(l10n.saveProductButton),
          onPressed: _save,
        ),
      ],
    );
  }
}

// ─── Drug Lookup Panel Widget ──────────────────────────────────────────────────

class _DrugLookupPanel extends StatelessWidget {
  const _DrugLookupPanel({
    required this.controller,
    required this.isSearching,
    required this.results,
    required this.isOpen,
    required this.onToggle,
    required this.onQueryChanged,
    required this.onResultSelected,
  });

  final TextEditingController controller;
  final bool isSearching;
  final List<DrugLookupResult> results;
  final bool isOpen;
  final VoidCallback onToggle;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<DrugLookupResult> onResultSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header button to expand/collapse
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withAlpha(120),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.primary.withAlpha(80)),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cari Obat Otomatis (BPOM / Database Lokal)',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(
                  isOpen ? Icons.expand_less : Icons.expand_more,
                  color: cs.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        // Expandable search area
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState:
              isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText:
                      'Ketik nama obat (contoh: paracetamol, amoksisilin)...',
                  prefixIcon: isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.medication_liquid),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            controller.clear();
                            onQueryChanged('');
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: onQueryChanged,
              ),
              if (results.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: results.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: cs.outlineVariant.withAlpha(80),
                      ),
                      itemBuilder: (context, index) {
                        final drug = results[index];
                        return _DrugResultTile(
                          drug: drug,
                          onTap: () => onResultSelected(drug),
                        );
                      },
                    ),
                  ),
                ),
              ] else if (!isSearching && controller.text.length >= 2) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Tidak ditemukan. Coba nama generik (contoh: "paracetamol").',
                    style: TextStyle(color: cs.outline, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 12, color: cs.outline),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Data dari database lokal 600+ obat Indonesia + BPOM (jika ada koneksi)',
                      style: TextStyle(color: cs.outline, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DrugResultTile extends StatelessWidget {
  const _DrugResultTile({required this.drug, required this.onTap});

  final DrugLookupResult drug;
  final VoidCallback onTap;

  Color _categoryColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (drug.category) {
      'Obat Bebas' => Colors.green.shade700,
      'Obat Bebas Terbatas' => Colors.blue.shade700,
      'Obat Keras' => Colors.red.shade700,
      'Psikotropika' => Colors.deepPurple.shade700,
      'Narkotika' => Colors.red.shade900,
      'Herbal / Jamu' => Colors.teal.shade700,
      _ => cs.outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final catColor = _categoryColor(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category dot indicator
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: catColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drug.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (drug.activeIngredient.isNotEmpty)
                    Text(
                      drug.activeIngredient,
                      style: TextStyle(color: cs.outline, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Row(
                    children: [
                      Text(
                        drug.category,
                        style: TextStyle(
                          color: catColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (drug.manufacturer.isNotEmpty) ...[
                        Text(' - ',
                            style: TextStyle(color: cs.outline, fontSize: 11)),
                        Text(
                          drug.manufacturer,
                          style: TextStyle(color: cs.outline, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Source badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: drug.source == DrugSource.bpom
                    ? Colors.green.shade100
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                drug.source == DrugSource.bpom ? 'BPOM' : 'Lokal',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: drug.source == DrugSource.bpom
                      ? Colors.green.shade800
                      : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
