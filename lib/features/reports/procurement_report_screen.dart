import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../data/report_repository.dart';
import '../auth/auth_session.dart';

import '../../l10n/app_localizations.dart';

final procurementReportFutureProvider = FutureProvider.family
    .autoDispose<ProcurementSummary, DateTimeRange>((ref, range) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getProcurementSummary(
    startDate: range.start,
    endDate: range.end,
  );
});

class ProcurementReportScreen extends ConsumerStatefulWidget {
  const ProcurementReportScreen({super.key});

  @override
  ConsumerState<ProcurementReportScreen> createState() =>
      _ProcurementReportScreenState();
}

class _ProcurementReportScreenState
    extends ConsumerState<ProcurementReportScreen> {
  late DateTimeRange _selectedDateRange;
  bool _isExporting = false;

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

  Future<void> _export(ProcurementSummary summary) async {
    if (summary.supplierSpendMap.isEmpty || _isExporting) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isExporting = true);
    try {
      final file =
          await ref.read(reportRepositoryProvider).exportProcurementReport(
                summary: summary,
                startDate: _selectedDateRange.start,
                endDate: _selectedDateRange.end,
                userId: ref.read(authSessionProvider)?.id ?? 1,
              );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportReportSaved(file.path)),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportReportFailed),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final procurementAsync =
        ref.watch(procurementReportFutureProvider(_selectedDateRange));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.procurementReportTitle)),
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
                  key: const Key('changeProcurementDateRangeBtn'),
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.filter_alt),
                  label: Text(l10n.filterDate),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: procurementAsync.when(
              data: (summary) {
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
                              title: l10n.procurementTotalPurchases,
                              value: formatIdr(summary.totalPurchaseSpend),
                              icon: Icons.shopping_bag,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              title: l10n.procurementPurchaseOrders,
                              value: '${summary.totalOrdersCount}',
                              icon: Icons.assignment,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              title: l10n.procurementBatchesReceived,
                              value: '${summary.receivedBatchesCount}',
                              icon: Icons.inventory_2,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Supplier Spend Breakdown Table
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.procurementBySupplier,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            key: const Key('exportProcurementReportBtn'),
                            tooltip: _isExporting
                                ? l10n.exportingProcurement
                                : summary.supplierSpendMap.isEmpty
                                    ? l10n.exportProcurementEmpty
                                    : l10n.exportProcurementTooltip,
                            onPressed:
                                summary.supplierSpendMap.isEmpty || _isExporting
                                    ? null
                                    : () => _export(summary),
                            icon: _isExporting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.download),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: summary.supplierSpendMap.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Center(
                                  child: Text(l10n.procurementEmpty),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: summary.supplierSpendMap.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (ctx, idx) {
                                  final entry = summary.supplierSpendMap.entries
                                      .elementAt(idx);
                                  return ListTile(
                                    title: Text(
                                      entry.key,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    trailing: Text(
                                      formatIdr(entry.value),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
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
              error: (_, __) => Center(child: Text(l10n.reportsLoadError)),
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
                        fontSize: 12,
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
