import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_session.dart';

class CashMovementDialog extends ConsumerStatefulWidget {
  const CashMovementDialog({super.key, required this.shiftId});

  final int shiftId;

  @override
  ConsumerState<CashMovementDialog> createState() => _CashMovementDialogState();
}

class _CashMovementDialogState extends ConsumerState<CashMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  String _movementType = 'cash_out';
  String _category = 'owner_draw';
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
      final currentUser = ref.read(authSessionProvider);
      final repo = ref.read(cashierShiftRepositoryProvider);

      await repo.recordCashMovement(
        shiftId: widget.shiftId,
        movementType: _movementType,
        category: _category,
        amount: amount,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        performedBy: currentUser?.id ?? 1,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _movementType == 'cash_out'
                  ? 'Pengambilan/Tarik Kas berhasil dicatat!'
                  : 'Penambahan Kas berhasil dicatat!',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencatat arus kas: $err'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _movementType == 'cash_out' ? Icons.money_off : Icons.attach_money,
            color: _movementType == 'cash_out' ? Colors.orange : AppTheme.successColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(l10n.cashMovementTitle),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Movement Type Toggle
              SegmentedButton<String>(
                key: const Key('movementTypeToggle'),
                segments: [
                  ButtonSegment(
                    value: 'cash_out',
                    label: Text(l10n.cashOutLabel),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: 'cash_in',
                    label: Text(l10n.cashInLabel),
                    icon: const Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_movementType},
                onSelectionChanged: (set) {
                  setState(() {
                    _movementType = set.first;
                    _category = _movementType == 'cash_out' ? 'owner_draw' : 'topup';
                  });
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                key: const Key('movementCategoryDropdown'),
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori / Keperluan',
                  border: OutlineInputBorder(),
                ),
                items: _movementType == 'cash_out'
                    ? [
                        DropdownMenuItem(
                          value: 'owner_draw',
                          child: Text(l10n.ownerDrawCategory),
                        ),
                        DropdownMenuItem(
                          value: 'operational_expense',
                          child: Text(l10n.operationalExpenseCategory),
                        ),
                        DropdownMenuItem(
                          value: 'bank_deposit',
                          child: Text(l10n.bankDepositCategory),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text(l10n.otherCategory),
                        ),
                      ]
                    : [
                        DropdownMenuItem(
                          value: 'topup',
                          child: Text(l10n.topupCategory),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text(l10n.otherCategory),
                        ),
                      ],
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                key: const Key('movementAmountInput'),
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Uang (Rp)',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Jumlah tidak boleh kosong';
                  final num = double.tryParse(val.trim());
                  if (num == null || num <= 0) return 'Jumlah harus lebih besar dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes Field
              TextFormField(
                key: const Key('movementNotesInput'),
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan / Keterangan (Opsional)',
                  hintText: 'mis. Ambil untung harian Rp 500.000',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          key: const Key('submitCashMovementBtn'),
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _movementType == 'cash_out' ? Colors.orange : AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Simpan Arus Kas'),
        ),
      ],
    );
  }
}
