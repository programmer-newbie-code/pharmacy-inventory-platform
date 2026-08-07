import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/database.dart';

class SupplierDetailScreen extends ConsumerStatefulWidget {
  const SupplierDetailScreen({super.key, required this.supplierId});

  final int supplierId;

  @override
  ConsumerState<SupplierDetailScreen> createState() =>
      _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends ConsumerState<SupplierDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Supplier? _supplier;
  List<PurchaseOrder>? _orders;
  bool _isLoading = true;
  bool _isEditing = false;

  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  final _leadTimeDaysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _paymentTermsController.dispose();
    _leadTimeDaysController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final supplierRepo = ref.read(supplierRepositoryProvider);
    final poRepo = ref.read(purchaseOrderRepositoryProvider);

    final supplier = await supplierRepo.getSupplier(widget.supplierId);
    final orders = await poRepo.listPurchaseOrders();

    if (!mounted) return;
    setState(() {
      _supplier = supplier;
      _orders =
          orders.where((o) => o.supplierId == widget.supplierId).toList();
      _isLoading = false;
      _populateFields(supplier);
    });
  }

  void _populateFields(Supplier s) {
    _nameController.text = s.name;
    _contactController.text = s.contactPerson ?? '';
    _phoneController.text = s.phone ?? '';
    _emailController.text = s.email ?? '';
    _addressController.text = s.address ?? '';
    _paymentTermsController.text = s.paymentTerms ?? '';
    _leadTimeDaysController.text = s.leadTimeDays.toString();
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier name is required.')),
      );
      return;
    }

    final repo = ref.read(supplierRepositoryProvider);
    final updated = await repo.updateSupplier(
      id: widget.supplierId,
      name: _nameController.text.trim(),
      contactPerson: _contactController.text.trim().isEmpty
          ? null
          : _contactController.text.trim(),
      phone:
          _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email:
          _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      paymentTerms: _paymentTermsController.text.trim().isEmpty
          ? null
          : _paymentTermsController.text.trim(),
      leadTimeDays: int.tryParse(_leadTimeDaysController.text.trim()) ?? 7,
    );

    if (!mounted) return;
    setState(() {
      _supplier = updated;
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Supplier updated.')),
    );
  }

  Future<void> _toggleActive() async {
    final repo = ref.read(supplierRepositoryProvider);
    if (_supplier!.isActive) {
      await repo.deactivateSupplier(widget.supplierId);
    } else {
      await repo.activateSupplier(widget.supplierId);
    }
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _supplier == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Supplier Detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final supplier = _supplier!;

    return Scaffold(
      appBar: AppBar(
        title: Text(supplier.name),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              key: const Key('editSupplierBtn'),
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: () => setState(() => _isEditing = true),
            ),
            IconButton(
              key: const Key('toggleActiveBtn'),
              icon: Icon(supplier.isActive ? Icons.block : Icons.check_circle),
              tooltip: supplier.isActive ? 'Deactivate' : 'Activate',
              onPressed: _toggleActive,
            ),
          ] else ...[
            TextButton(
              onPressed: () {
                _populateFields(supplier);
                setState(() => _isEditing = false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              key: const Key('saveSupplierBtn'),
              onPressed: _saveChanges,
              child: const Text('Save'),
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Details'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Purchase Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(supplier),
          _buildOrdersTab(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(Supplier supplier) {
    if (_isEditing) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Supplier Name *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(labelText: 'Contact Person'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _paymentTermsController,
              decoration: const InputDecoration(
                labelText: 'Payment Terms',
                hintText: 'e.g. Net 30, COD',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _leadTimeDaysController,
              decoration: const InputDecoration(
                labelText: 'Lead Time (days)',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        child: Text(
                          supplier.name.isNotEmpty
                              ? supplier.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              supplier.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Chip(
                              label: Text(
                                supplier.isActive ? 'Active' : 'Inactive',
                              ),
                              backgroundColor: supplier.isActive
                                  ? Colors.green.shade100
                                  : Colors.grey.shade300,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _detailRow(Icons.person, 'Contact', supplier.contactPerson),
          _detailRow(Icons.phone, 'Phone', supplier.phone),
          _detailRow(Icons.email, 'Email', supplier.email),
          _detailRow(Icons.location_on, 'Address', supplier.address),
          _detailRow(Icons.payment, 'Payment Terms', supplier.paymentTerms),
          _detailRow(
            Icons.schedule,
            'Lead Time',
            '${supplier.leadTimeDays} days',
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value ?? '-')),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_orders == null || _orders!.isEmpty) {
      return const Center(
        child: Text('No purchase orders for this supplier.'),
      );
    }

    return ListView.builder(
      itemCount: _orders!.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (ctx, idx) {
        final order = _orders![idx];
        final statusColor = switch (order.status) {
          'received' => Colors.green,
          'sent' => Colors.orange,
          'cancelled' => Colors.red,
          _ => Colors.grey,
        };

        return Card(
          child: ListTile(
            leading: Icon(Icons.receipt, color: statusColor),
            title: Text(order.poNumber),
            subtitle: Text(
              'Total: Rp ${order.totalAmount.toStringAsFixed(0)} • '
              '${order.createdAt.toString().split(' ')[0]}',
            ),
            trailing: Chip(
              label: Text(
                order.status.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 12),
              ),
            ),
          ),
        );
      },
    );
  }
}
