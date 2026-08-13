import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import 'supplier_detail_screen.dart';

final supplierListFutureProvider = FutureProvider.autoDispose<List<Supplier>>((ref) {
  final repo = ref.watch(supplierRepositoryProvider);
  return repo.listSuppliers();
});

class SupplierListScreen extends ConsumerStatefulWidget {
  const SupplierListScreen({super.key});

  @override
  ConsumerState<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends ConsumerState<SupplierListScreen> {
  final _searchController = TextEditingController();
  bool _showActiveOnly = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddSupplierDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final paymentTermsController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addNewSupplier),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('supplierNameInput'),
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.supplierNameLabel),
              ),
              TextField(
                key: const Key('supplierContactInput'),
                controller: contactController,
                decoration: InputDecoration(labelText: l10n.contactPersonLabel),
              ),
              TextField(
                key: const Key('supplierPhoneInput'),
                controller: phoneController,
                decoration: InputDecoration(labelText: l10n.phoneLabel),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                key: const Key('supplierEmailInput'),
                controller: emailController,
                decoration: InputDecoration(labelText: l10n.emailLabel),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                key: const Key('supplierAddressInput'),
                controller: addressController,
                decoration: InputDecoration(labelText: l10n.addressLabel),
                maxLines: 2,
              ),
              TextField(
                key: const Key('supplierPaymentTermsInput'),
                controller: paymentTermsController,
                decoration: InputDecoration(
                  labelText: l10n.paymentTermsLabel,
                  hintText: l10n.paymentTermsHint,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            key: const Key('confirmAddSupplierBtn'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.saveButton),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      final repo = ref.read(supplierRepositoryProvider);
      await repo.createSupplier(
        name: nameController.text.trim(),
        contactPerson: contactController.text.trim().isEmpty
            ? null
            : contactController.text.trim(),
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        email: emailController.text.trim().isEmpty
            ? null
            : emailController.text.trim(),
        address: addressController.text.trim().isEmpty
            ? null
            : addressController.text.trim(),
        paymentTerms: paymentTermsController.text.trim().isEmpty
            ? null
            : paymentTermsController.text.trim(),
      );
      ref.invalidate(supplierListFutureProvider);
    }
  }

  List<Supplier> _filterSuppliers(List<Supplier> suppliers) {
    var filtered = suppliers;

    if (_showActiveOnly) {
      filtered = filtered.where((s) => s.isActive).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((s) => s.name.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final suppliersAsync = ref.watch(supplierListFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.suppliersDirectoryTitle),
        actions: [
          IconButton(
            key: const Key('addSupplierBtn'),
            icon: const Icon(Icons.person_add),
            tooltip: l10n.addSupplierButton,
            onPressed: () => _showAddSupplierDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('supplierSearchInput'),
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchSuppliersHint,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  key: const Key('activeFilterChip'),
                  label: Text(l10n.activeOnlyToggle),
                  selected: _showActiveOnly,
                  onSelected: (val) => setState(() => _showActiveOnly = val),
                ),
              ],
            ),
          ),
          Expanded(
            child: suppliersAsync.when(
              data: (suppliers) {
                final filtered = _filterSuppliers(suppliers);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          suppliers.isEmpty
                              ? l10n.noSuppliersAdded
                              : l10n.noSuppliersMatchFilter,
                        ),
                        if (suppliers.isEmpty) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            key: const Key('addFirstSupplierBtn'),
                            icon: const Icon(Icons.add),
                            label: Text(l10n.addFirstSupplier),
                            onPressed: () => _showAddSupplierDialog(context),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final s = filtered[idx];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: s.isActive
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.grey.shade300,
                        child: Icon(
                          Icons.local_shipping,
                          color: s.isActive
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Colors.grey,
                        ),
                      ),
                      title: Text(
                        s.name,
                        style: TextStyle(
                          color: s.isActive ? null : Colors.grey,
                          decoration:
                              s.isActive ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      subtitle: Text(
                        [
                          if (s.contactPerson != null)
                            '${l10n.contactLabel}: ${s.contactPerson}',
                          if (s.phone != null) '${l10n.phoneLabel}: ${s.phone}',
                          if (s.paymentTerms != null) s.paymentTerms!,
                        ].join(' • '),
                      ),
                      trailing: s.isActive
                          ? null
                          : Chip(label: Text(l10n.statusInactive)),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SupplierDetailScreen(supplierId: s.id),
                          ),
                        );
                        ref.invalidate(supplierListFutureProvider);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
