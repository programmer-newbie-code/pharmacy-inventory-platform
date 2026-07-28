import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/database.dart';

final supplierListFutureProvider = FutureProvider.autoDispose<List<Supplier>>((ref) {
  final repo = ref.watch(supplierRepositoryProvider);
  return repo.listSuppliers();
});

class SupplierListScreen extends ConsumerWidget {
  const SupplierListScreen({super.key});

  Future<void> _showAddSupplierDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('supplierNameInput'),
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Supplier Name *'),
            ),
            TextField(
              key: const Key('supplierContactInput'),
              controller: contactController,
              decoration: const InputDecoration(labelText: 'Contact Person'),
            ),
            TextField(
              key: const Key('supplierPhoneInput'),
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              key: const Key('supplierEmailInput'),
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirmAddSupplierBtn'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      final repo = ref.read(supplierRepositoryProvider);
      await repo.createSupplier(
        name: nameController.text.trim(),
        contactPerson: contactController.text.trim().isEmpty ? null : contactController.text.trim(),
        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
        email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
      );
      ref.invalidate(supplierListFutureProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(supplierListFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers Directory'),
        actions: [
          IconButton(
            key: const Key('addSupplierBtn'),
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddSupplierDialog(context, ref),
          ),
        ],
      ),
      body: suppliersAsync.when(
        data: (suppliers) {
          if (suppliers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No suppliers added yet.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    key: const Key('addFirstSupplierBtn'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Supplier'),
                    onPressed: () => _showAddSupplierDialog(context, ref),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: suppliers.length,
            itemBuilder: (ctx, idx) {
              final s = suppliers[idx];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.local_shipping)),
                title: Text(s.name),
                subtitle: Text('Contact: ${s.contactPerson ?? "-"} • Phone: ${s.phone ?? "-"}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
