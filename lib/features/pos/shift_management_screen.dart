import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/database.dart';

final shiftListFutureProvider = FutureProvider.autoDispose<List<CashierShift>>((ref) {
  final repo = ref.watch(cashierShiftRepositoryProvider);
  return repo.listShifts();
});

class ShiftManagementScreen extends ConsumerStatefulWidget {
  const ShiftManagementScreen({super.key});

  @override
  ConsumerState<ShiftManagementScreen> createState() => _ShiftManagementScreenState();
}

class _ShiftManagementScreenState extends ConsumerState<ShiftManagementScreen> {
  CashierShift? _activeShift;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveShift();
  }

  Future<void> _loadActiveShift() async {
    final repo = ref.read(cashierShiftRepositoryProvider);
    final active = await repo.getActiveShift(1); // default cashierId=1
    setState(() {
      _activeShift = active;
      _isLoading = false;
    });
  }

  Future<void> _handleOpenShift() async {
    final openingController = TextEditingController(text: '100000');
    final amountStr = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Open Cashier Shift'),
        content: TextField(
          key: const Key('openingBalanceInput'),
          controller: openingController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Opening Cash Drawer Balance (Rp)',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirmOpenShiftBtn'),
            onPressed: () => Navigator.of(ctx).pop(openingController.text),
            child: const Text('Open Shift'),
          ),
        ],
      ),
    );

    if (amountStr != null && amountStr.isNotEmpty) {
      final amount = double.tryParse(amountStr) ?? 0.0;
      final repo = ref.read(cashierShiftRepositoryProvider);
      await repo.openShift(cashierId: 1, openingBalance: amount);
      _loadActiveShift();
      ref.invalidate(shiftListFutureProvider);
    }
  }

  Future<void> _handleCloseShift() async {
    if (_activeShift == null) return;
    final actualController = TextEditingController();
    final reasonController = TextEditingController();

    final actualStr = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Shift & Reconcile Cash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Opening Balance: Rp ${_activeShift!.openingBalance.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            TextField(
              key: const Key('actualCashInput'),
              controller: actualController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Counted Actual Cash in Drawer (Rp)',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('discrepancyReasonInput'),
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason required if cash is over or short',
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
            key: const Key('confirmCloseShiftBtn'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(actualController.text),
            child: const Text('Reconcile & Close'),
          ),
        ],
      ),
    );

    if (actualStr != null && actualStr.isNotEmpty) {
      final actual = double.tryParse(actualStr) ?? 0.0;
      final repo = ref.read(cashierShiftRepositoryProvider);
      final closed = await repo.closeShift(
        shiftId: _activeShift!.id,
        actualCash: actual,
        discrepancyReason: reasonController.text,
      );
      
      _loadActiveShift();
      ref.invalidate(shiftListFutureProvider);

      if (mounted) {
        final disc = closed.discrepancy ?? 0.0;
        final message = disc == 0
            ? 'Shift closed. Balanced perfectly!'
            : disc > 0
                ? 'Shift closed. Cash OVERAGE of Rp ${disc.toStringAsFixed(0)}'
                : 'Shift closed. Cash SHORTAGE of Rp ${disc.abs().toStringAsFixed(0)}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: disc == 0 ? Colors.green : (disc > 0 ? Colors.blue : Colors.red),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shiftListAsync = ref.watch(shiftListFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Shift Reconciliation'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: _activeShift != null ? Colors.green.shade50 : Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _activeShift != null ? 'Shift Active (Open)' : 'No Active Shift',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if (_activeShift != null)
                                      Text(
                                        'Opened: ${_activeShift!.openedAt.toIso8601String().replaceAll('T', ' ').substring(0, 16)} • Rp ${_activeShift!.openingBalance.toStringAsFixed(0)}',
                                      ),
                                  ],
                                ),
                              ),
                              _activeShift == null
                                  ? ElevatedButton.icon(
                                      key: const Key('openShiftBtn'),
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text('Open Shift'),
                                      onPressed: _handleOpenShift,
                                    )
                                  : ElevatedButton.icon(
                                      key: const Key('closeShiftBtn'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                      icon: const Icon(Icons.stop),
                                      label: const Text('Close & Reconcile'),
                                      onPressed: _handleCloseShift,
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Past Shifts Log',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: shiftListAsync.when(
                      data: (shifts) {
                        if (shifts.isEmpty) {
                          return const Center(child: Text('No shifts recorded yet.'));
                        }
                        return ListView.builder(
                          itemCount: shifts.length,
                          itemBuilder: (ctx, idx) {
                            final s = shifts[idx];
                            final disc = s.discrepancy ?? 0.0;
                            final isClosed = s.status == 'closed';

                            return ListTile(
                              leading: Icon(
                                isClosed
                                    ? (disc == 0
                                        ? Icons.check_circle
                                        : (disc > 0 ? Icons.add_circle : Icons.warning))
                                    : Icons.access_time,
                                color: isClosed
                                    ? (disc == 0 ? Colors.green : (disc > 0 ? Colors.blue : Colors.red))
                                    : Colors.orange,
                              ),
                              title: Text('Shift #${s.id} (${s.status.toUpperCase()})'),
                              subtitle: Text(
                                'Opened: ${s.openedAt.toIso8601String().replaceAll('T', ' ').substring(0, 16)}'
                                '${isClosed ? '\nExpected: Rp ${(s.expectedCash ?? 0).toStringAsFixed(0)} | Actual: Rp ${(s.actualCash ?? 0).toStringAsFixed(0)}' : ''}',
                              ),
                              trailing: isClosed
                                  ? Chip(
                                      label: Text(
                                        disc == 0
                                            ? 'BALANCED'
                                            : (disc > 0
                                                ? '+Rp ${disc.toStringAsFixed(0)}'
                                                : '-Rp ${disc.abs().toStringAsFixed(0)}'),
                                      ),
                                      backgroundColor: disc == 0
                                          ? Colors.green.shade100
                                          : (disc > 0 ? Colors.blue.shade100 : Colors.red.shade100),
                                    )
                                  : null,
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
            ),
    );
  }
}
