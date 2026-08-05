import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../data/report_repository.dart';
import '../../l10n/app_localizations.dart';
import 'sales_analytics_screen.dart';

final salesReportFutureProvider =
    FutureProvider.autoDispose<SalesSummary>((ref) {
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month, 1);
  final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getSalesSummary(startDate: startDate, endDate: endDate);
});

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _isExporting = false;

  Future<void> _exportExcel(SalesSummary summary) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isExporting = true);
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final repo = ref.read(reportRepositoryProvider);
      final rows = await repo.getDetailedSalesRows(
          startDate: startDate, endDate: endDate);
      final service = ref.read(excelReportServiceProvider);
      final file = await service.exportAndSaveReport(
        summary: summary,
        rows: rows,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportReportSaved(file.path)),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (err) {
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
    final reportAsync = ref.watch(salesReportFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.salesReportTitle),
      ),
      body: reportAsync.when(
        data: (summary) {
          final marginPct = summary.totalRevenue > 0
              ? (summary.grossProfit / summary.totalRevenue) * 100
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.monthlySummary,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 20),
                        _buildKpiRow(l10n.totalTransactions,
                            '${summary.totalTransactions}', AppTheme.infoColor),
                        const Divider(height: 24),
                        _buildKpiRow(
                            l10n.totalRevenue,
                            formatIdr(summary.totalRevenue),
                            AppTheme.successColor),
                        const Divider(height: 24),
                        _buildKpiRow(
                            l10n.cogs,
                            formatIdr(summary.totalCostOfGoods),
                            AppTheme.warningColor),
                        const Divider(height: 24),
                        _buildKpiRow(l10n.grossProfit,
                            formatIdr(summary.grossProfit), Colors.purple),
                        const Divider(height: 24),
                        _buildKpiRow(
                            l10n.grossMargin,
                            '${marginPct.toStringAsFixed(1)}%',
                            AppTheme.primaryColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  key: const Key('navAnalyticsBtn'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.analytics),
                  label: Text(l10n.salesAnalytics),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SalesAnalyticsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  key: const Key('exportExcelBtn'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  icon: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.table_chart),
                  label: Text(_isExporting
                      ? l10n.exportingReport
                      : l10n.exportExcelButton),
                  onPressed: _isExporting ? null : () => _exportExcel(summary),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.reportsLoadError)),
      ),
    );
  }

  Widget _buildKpiRow(String title, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
        Text(
          value,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
