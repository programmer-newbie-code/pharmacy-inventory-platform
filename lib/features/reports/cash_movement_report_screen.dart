import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../data/database.dart';

final cashMovementsFutureProvider =
    FutureProvider.family.autoDispose<List<CashMovement>, DateTimeRange>(
        (ref, range) async {
  final repo = ref.watch(cashierShiftRepositoryProvider);
  return repo.getCashMovementsInRange(
    startDate: range.start,
    endDate: range.end,
  );
});

class CashMovementReportScreen extends ConsumerStatefulWidget {
  const CashMovementReportScreen({super.key});

  @override
  ConsumerState<CashMovementReportScreen> createState() =>
      _CashMovementReportScreenState();
}

class _CashMovementReportScreenState
    extends ConsumerState<CashMovementReportScreen> {
  late DateTimeRange _selectedDateRange;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  String _formatCategory(String cat) {
    switch (cat) {
      case 'owner_draw':
        return '👑 Ambil Untung Owner (Prive)';
      case 'operational_expense':
        return '💸 Pengeluaran Operasional';
      case 'bank_deposit':
        return '🏦 Setor Kas ke Bank';
      case 'topup':
        return '💵 Tambah Modal Kasir';
      default:
        return 'Lain-lain ($cat)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final movementsAsync =
        ref.watch(cashMovementsFutureProvider(_selectedDateRange));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Arus Kas & Prive Owner'),
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.date_range, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedDateRange.start.toIso8601String().split('T').first} - ${_selectedDateRange.end.toIso8601String().split('T').first}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  key: const Key('changeCashMovementDateRangeBtn'),
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.filter_alt),
                  label: const Text('Filter Date'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: movementsAsync.when(
              data: (movements) {
                double totalOut = 0;
                double totalIn = 0;
                double totalOwnerPrive = 0;

                for (final m in movements) {
                  if (m.movementType == 'cash_out') {
                    totalOut += m.amount;
                    if (m.category == 'owner_draw') {
                      totalOwnerPrive += m.amount;
                    }
                  } else {
                    totalIn += m.amount;
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Metric Cards
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: 'AMBIL UNTUNG OWNER (PRIVE)',
                              value: formatIdr(totalOwnerPrive),
                              icon: Icons.workspace_premium,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              title: 'TOTAL TARIK KAS (OUT)',
                              value: formatIdr(totalOut),
                              icon: Icons.arrow_upward,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              title: 'TOTAL TAMBAH KAS (IN)',
                              value: formatIdr(totalIn),
                              icon: Icons.arrow_downward,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // History Table
                      const Text(
                        'Riwayat Mutasi Arus Kas',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: movements.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Center(
                                  child: Text('Belum ada transaksi arus kas pada periode ini.'),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: movements.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (ctx, idx) {
                                  final m = movements[idx];
                                  final isOut = m.movementType == 'cash_out';
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isOut
                                          ? Colors.orange.shade100
                                          : Colors.green.shade100,
                                      child: Icon(
                                        isOut
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        color: isOut
                                            ? Colors.orange.shade800
                                            : Colors.green.shade800,
                                      ),
                                    ),
                                    title: Text(
                                      _formatCategory(m.category),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      '${m.createdAt.toIso8601String().replaceAll('T', ' ').substring(0, 16)}${m.notes != null && m.notes!.isNotEmpty ? " • ${m.notes}" : ""}',
                                    ),
                                    trailing: Text(
                                      '${isOut ? "-" : "+"}${formatIdr(m.amount)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isOut
                                            ? Colors.orange.shade900
                                            : Colors.green.shade900,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
