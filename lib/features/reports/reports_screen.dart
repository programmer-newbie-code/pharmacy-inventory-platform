import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../data/report_repository.dart';
import '../auth/auth_session.dart';
import '../../l10n/app_localizations.dart';
import 'cash_movement_report_screen.dart';
import 'procurement_report_screen.dart';
import 'sales_analytics_screen.dart';

enum ReportDateFilter { today, week, month, year, custom }

final salesReportFutureProvider = FutureProvider.family
    .autoDispose<SalesSummary, DateTimeRange>((ref, range) {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getSalesSummary(startDate: range.start, endDate: range.end);
});

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportDateFilter _activeFilter = ReportDateFilter.month;
  DateTimeRange? _customRange;
  bool _isExporting = false;

  DateTimeRange _computeRange() {
    final now = DateTime.now();
    switch (_activeFilter) {
      case ReportDateFilter.today:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case ReportDateFilter.week:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(monday.year, monday.month, monday.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case ReportDateFilter.month:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case ReportDateFilter.year:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
      case ReportDateFilter.custom:
        return _customRange ??
            DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
            );
    }
  }

  Future<void> _exportExcel(SalesSummary summary, DateTimeRange range) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isExporting = true);
    try {
      final repo = ref.read(reportRepositoryProvider);
      final rows = await repo.getDetailedSalesRows(
        startDate: range.start,
        endDate: range.end,
      );
      final file = await repo.exportSalesReport(
        summary: summary,
        rows: rows,
        startDate: range.start,
        endDate: range.end,
        userId: ref.read(authSessionProvider)?.id ?? 1,
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

  Future<void> _pickCustomRange() async {
    final initial = _computeRange();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: initial,
    );
    if (picked != null) {
      setState(() {
        _customRange = DateTimeRange(
          start: picked.start,
          end: DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
            23,
            59,
            59,
          ),
        );
        _activeFilter = ReportDateFilter.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeRange = _computeRange();
    final reportAsync = ref.watch(salesReportFutureProvider(activeRange));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.salesReportTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Filter Toolbar
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      key: const Key('filterTodayChip'),
                      label: Text(l10n.filterToday),
                      selected: _activeFilter == ReportDateFilter.today,
                      onSelected: (_) => setState(
                        () => _activeFilter = ReportDateFilter.today,
                      ),
                    ),
                    FilterChip(
                      key: const Key('filterWeekChip'),
                      label: Text(l10n.filterThisWeek),
                      selected: _activeFilter == ReportDateFilter.week,
                      onSelected: (_) =>
                          setState(() => _activeFilter = ReportDateFilter.week),
                    ),
                    FilterChip(
                      key: const Key('filterMonthChip'),
                      label: Text(l10n.filterThisMonth),
                      selected: _activeFilter == ReportDateFilter.month,
                      onSelected: (_) => setState(
                        () => _activeFilter = ReportDateFilter.month,
                      ),
                    ),
                    FilterChip(
                      key: const Key('filterYearChip'),
                      label: Text(l10n.filterThisYear),
                      selected: _activeFilter == ReportDateFilter.year,
                      onSelected: (_) =>
                          setState(() => _activeFilter = ReportDateFilter.year),
                    ),
                    ActionChip(
                      key: const Key('filterCustomChip'),
                      avatar: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        _activeFilter == ReportDateFilter.custom
                            ? '${activeRange.start.toString().split(' ').first} - ${activeRange.end.toString().split(' ').first}'
                            : l10n.filterCustom,
                      ),
                      backgroundColor: _activeFilter == ReportDateFilter.custom
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      onPressed: _pickCustomRange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            reportAsync.when(
              data: (summary) {
                final marginPct = summary.totalRevenue > 0
                    ? (summary.grossProfit / summary.totalRevenue) * 100
                    : 0.0;

                return Column(
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
                            const SizedBox(height: 6),
                            Text(
                              '${activeRange.start.toString().split(' ').first} s/d ${activeRange.end.toString().split(' ').first}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildKpiRow(
                              l10n.totalTransactions,
                              '${summary.totalTransactions}',
                              AppTheme.infoColor,
                            ),
                            const Divider(height: 24),
                            _buildKpiRow(
                              l10n.totalRevenue,
                              formatIdr(summary.totalRevenue),
                              AppTheme.successColor,
                            ),
                            const Divider(height: 24),
                            _buildKpiRow(
                              l10n.cogs,
                              formatIdr(summary.totalCostOfGoods),
                              AppTheme.warningColor,
                            ),
                            const Divider(height: 24),
                            _buildKpiRow(
                              l10n.grossProfit,
                              formatIdr(summary.grossProfit),
                              Colors.purple,
                            ),
                            const Divider(height: 24),
                            _buildKpiRow(
                              l10n.grossMargin,
                              '${marginPct.toStringAsFixed(1)}%',
                              AppTheme.primaryColor,
                            ),
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
                            builder: (_) => const SalesAnalyticsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      key: const Key('navProcurementReportBtn'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text(
                        'Laporan Pembelian & Stok (Procurement)',
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProcurementReportScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      key: const Key('navCashMovementReportBtn'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Laporan Arus Kas & Prive Owner'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CashMovementReportScreen(),
                          ),
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
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.table_chart),
                      label: Text(
                        _isExporting
                            ? l10n.exportingReport
                            : l10n.exportExcelButton,
                      ),
                      onPressed: _isExporting
                          ? null
                          : () => _exportExcel(summary, activeRange),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text(l10n.reportsLoadError)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiRow(String title, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
