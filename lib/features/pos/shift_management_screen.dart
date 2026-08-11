import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_session.dart';
import 'cash_movement_dialog.dart';

final shiftListFutureProvider = FutureProvider.autoDispose<List<CashierShift>>((
  ref,
) {
  final repo = ref.watch(cashierShiftRepositoryProvider);
  return repo.listShifts();
});

class ShiftManagementScreen extends ConsumerStatefulWidget {
  const ShiftManagementScreen({super.key});

  @override
  ConsumerState<ShiftManagementScreen> createState() =>
      _ShiftManagementScreenState();
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
    final currentUser = ref.read(authSessionProvider);
    if (currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final repo = ref.read(cashierShiftRepositoryProvider);
    final active = await repo.getActiveShift(currentUser.id);
    setState(() {
      _activeShift = active;
      _isLoading = false;
    });
  }

  bool _requireSession() {
    if (ref.read(authSessionProvider) != null) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.sessionRequired)),
    );
    return false;
  }

  Future<void> _handleOpenShift() async {
    if (!_requireSession()) return;
    final l10n = AppLocalizations.of(context)!;
    final openingController = TextEditingController(text: '100000');
    final amountStr = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.openCashierShift),
        content: TextField(
          key: const Key('openingBalanceInput'),
          controller: openingController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.openingDrawerBalance,
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            key: const Key('confirmOpenShiftBtn'),
            onPressed: () => Navigator.of(ctx).pop(openingController.text),
            child: Text(l10n.openShift),
          ),
        ],
      ),
    );

    if (amountStr != null && amountStr.isNotEmpty) {
      final amount = double.tryParse(amountStr) ?? 0.0;
      final repo = ref.read(cashierShiftRepositoryProvider);
      await repo.openShift(
        cashierId: ref.read(authSessionProvider)!.id,
        openingBalance: amount,
      );
      _loadActiveShift();
      ref.invalidate(shiftListFutureProvider);
    }
  }

  Future<void> _handleCashMovement() async {
    if (!_requireSession()) return;
    if (_activeShift == null) return;
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => CashMovementDialog(shiftId: _activeShift!.id),
    );
    if (updated == true) {
      setState(() {});
    }
  }

  Future<void> _handleCloseShift() async {
    if (_activeShift == null) return;
    if (!_requireSession()) return;
    final l10n = AppLocalizations.of(context)!;
    final actualController = TextEditingController();
    final reasonController = TextEditingController();

    final actualStr = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.closeShiftReconcile),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.openingCash}: Rp ${_activeShift!.openingBalance.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('actualCashInput'),
              controller: actualController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.countedDrawerCash,
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('discrepancyReasonInput'),
              controller: reasonController,
              decoration: InputDecoration(labelText: l10n.discrepancyReason),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            key: const Key('confirmCloseShiftBtn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(actualController.text),
            child: Text(l10n.reconcileClose),
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
            ? l10n.shiftClosedBalanced
            : disc > 0
                ? l10n.shiftClosedOverage(disc.toStringAsFixed(0))
                : l10n.shiftClosedShortage(disc.abs().toStringAsFixed(0));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: disc == 0
                ? Colors.green
                : (disc > 0 ? Colors.blue : Colors.red),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shiftListAsync = ref.watch(shiftListFutureProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cashShiftTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: _activeShift != null
                        ? Colors.green.shade50
                        : Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _activeShift != null
                                    ? l10n.shiftActive
                                    : l10n.noActiveShift,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (_activeShift != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${l10n.shiftOpened}: ${_activeShift!.openedAt.toIso8601String().replaceAll('T', ' ').substring(0, 16)} • Rp ${_activeShift!.openingBalance.toStringAsFixed(0)}',
                                ),
                              ],
                              const SizedBox(height: 12),
                              _activeShift == null
                                  ? ElevatedButton.icon(
                                      key: const Key('openShiftBtn'),
                                      icon: const Icon(Icons.play_arrow),
                                      label: Text(l10n.openShift),
                                      onPressed: _handleOpenShift,
                                    )
                                  : Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ElevatedButton.icon(
                                          key: const Key('cashMovementBtn'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                          ),
                                          icon: const Icon(Icons.swap_horiz),
                                          label: Text(l10n.cashMovementButton),
                                          onPressed: _handleCashMovement,
                                        ),
                                        ElevatedButton.icon(
                                          key: const Key('closeShiftBtn'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          icon: const Icon(Icons.stop),
                                          label: Text(l10n.closeShift),
                                          onPressed: _handleCloseShift,
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.pastShifts,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: shiftListAsync.when(
                      data: (shifts) {
                        if (shifts.isEmpty) {
                          return Center(child: Text(l10n.noShifts));
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
                                        : (disc > 0
                                            ? Icons.add_circle
                                            : Icons.warning))
                                    : Icons.access_time,
                                color: isClosed
                                    ? (disc == 0
                                        ? Colors.green
                                        : (disc > 0 ? Colors.blue : Colors.red))
                                    : Colors.orange,
                              ),
                              title: Text(
                                'Shift #${s.id} (${s.status.toUpperCase()})',
                              ),
                              subtitle: Text(
                                '${l10n.shiftOpened}: ${s.openedAt.toIso8601String().replaceAll('T', ' ').substring(0, 16)}'
                                '${isClosed ? '\n${l10n.expectedCash}: Rp ${(s.expectedCash ?? 0).toStringAsFixed(0)} | ${l10n.actualCash}: Rp ${(s.actualCash ?? 0).toStringAsFixed(0)}' : ''}',
                              ),
                              trailing: isClosed
                                  ? Chip(
                                      label: Text(
                                        disc == 0
                                            ? l10n.shiftClosedBalanced
                                            : (disc > 0
                                                ? '+Rp ${disc.toStringAsFixed(0)}'
                                                : '-Rp ${disc.abs().toStringAsFixed(0)}'),
                                      ),
                                      backgroundColor: disc == 0
                                          ? Colors.green.shade100
                                          : (disc > 0
                                              ? Colors.blue.shade100
                                              : Colors.red.shade100),
                                    )
                                  : null,
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, __) =>
                          Center(child: Text(l10n.analyticsLoadError)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
