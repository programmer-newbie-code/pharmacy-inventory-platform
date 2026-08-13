import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../data/report_repository.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_session.dart';

class CategorySalesData {
  CategorySalesData(
      {required this.category,
      required this.totalAmount,
      required this.unitsSold});
  final String category;
  final double totalAmount;
  final int unitsSold;
}

class SalesAnalyticsFilter {
  const SalesAnalyticsFilter({required this.range, required this.rankBy});

  final DateTimeRange range;
  final BestSellingRankMode rankBy;

  @override
  bool operator ==(Object other) =>
      other is SalesAnalyticsFilter &&
      other.range == range &&
      other.rankBy == rankBy;

  @override
  int get hashCode => Object.hash(range, rankBy);
}

final salesAnalyticsFutureProvider = FutureProvider.family
    .autoDispose<SalesAnalyticsData, SalesAnalyticsFilter>((ref, filter) {
  return ref.watch(reportRepositoryProvider).getSalesAnalytics(
        BestSellingMedicinesFilter(
          startDate: filter.range.start,
          endDate: filter.range.end,
          rankMode: filter.rankBy,
        ),
      );
});

class SalesAnalyticsScreen extends ConsumerStatefulWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  ConsumerState<SalesAnalyticsScreen> createState() =>
      _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends ConsumerState<SalesAnalyticsScreen> {
  late DateTimeRange _dateRange;
  String _selectedPreset = 'This Month';
  BestSellingRankMode _rankBy = BestSellingRankMode.netQuantity;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _applyPreset('This Month');
  }

  void _applyPreset(String preset) {
    final now = DateTime.now();
    DateTime start;
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (preset == 'Today') {
      start = DateTime(now.year, now.month, now.day);
    } else if (preset == 'This Week') {
      start = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
    } else {
      // This Month
      start = DateTime(now.year, now.month, 1);
    }

    setState(() {
      _selectedPreset = preset;
      _dateRange = DateTimeRange(start: start, end: end);
    });
  }

  Future<void> _selectCustomRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedPreset = 'Custom';
      _dateRange = DateTimeRange(
        start: DateTime(
            selected.start.year, selected.start.month, selected.start.day),
        end: DateTime(selected.end.year, selected.end.month, selected.end.day,
            23, 59, 59),
      );
    });
  }

  Future<void> _exportBestSelling(
      List<BestSellingMedicineRow> rows) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isExporting = true);
    try {
      final currentUser = ref.read(authSessionProvider);
      final repo = ref.read(reportRepositoryProvider);
      final file = await repo.exportBestSellingMedicines(
        filter: BestSellingMedicinesFilter(
          startDate: _dateRange.start,
          endDate: _dateRange.end,
          rankMode: _rankBy,
        ),
        rows: rows,
        userId: currentUser?.id ?? 1,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportBestSellingSaved(file.path)),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportBestSellingFailed),
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
    final analyticsAsync = ref.watch(
      salesAnalyticsFutureProvider(
        SalesAnalyticsFilter(range: _dateRange, rankBy: _rankBy),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analyticsTitle),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                        value: 'Today', label: Text(l10n.filterToday)),
                    ButtonSegment(
                        value: 'This Week', label: Text(l10n.filterThisWeek)),
                    ButtonSegment(
                        value: 'This Month', label: Text(l10n.filterThisMonth)),
                  ],
                  selected: {_selectedPreset},
                  onSelectionChanged: (val) => _applyPreset(val.first),
                ),
                OutlinedButton.icon(
                  onPressed: _selectCustomRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(l10n.filterCustom),
                ),
                Text(
                  '${_dateRange.start.toIso8601String().split('T').first} - ${_dateRange.end.toIso8601String().split('T').first}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: analyticsAsync.when(
              data: (data) {
                final summary = data.summary;
                final totalRefunds = summary.totalRefunds;
                final paymentCounts = data.paymentCounts;
                final categoryMap = data.categoryRevenue;
                final topProducts = data.bestSellingMedicines;

                final marginPct = summary.totalRevenue > 0
                    ? (summary.grossProfit / summary.totalRevenue) * 100
                    : 0.0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Executive Metric Cards
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: l10n.analyticsNetRevenue,
                              value: formatIdr(summary.netRevenue),
                              icon: Icons.monetization_on,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              title: l10n.analyticsGrossRevenue,
                              value: formatIdr(summary.totalRevenue),
                              icon: Icons.receipt_long,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: l10n.analyticsNetProfit,
                              value:
                                  '${formatIdr(summary.grossProfit - totalRefunds)} (${marginPct.toStringAsFixed(1)}%)',
                              icon: Icons.trending_up,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              title: l10n.analyticsTotalRefunds,
                              value: formatIdr(totalRefunds),
                              icon: Icons.assignment_return,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Sales by Category
                      Text(
                        l10n.analyticsCategorySales,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      if (categoryMap.isEmpty)
                        Text(l10n.noCategoryData)
                      else
                        ...categoryMap.entries.map((e) {
                          final pct = summary.totalRevenue > 0
                              ? (e.value / summary.totalRevenue)
                              : 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                        '${formatIdr(e.value)} (${(pct * 100).toStringAsFixed(1)}%)'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.bestSellingMedicines,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Tooltip(
                            message: _isExporting
                                ? l10n.exportingBestSelling
                                : topProducts.isEmpty
                                    ? l10n.exportBestSellingDisabledEmpty
                                    : l10n.exportBestSellingButtonTooltip,
                            child: OutlinedButton.icon(
                              key: const Key('exportBestSellingBtn'),
                              onPressed: topProducts.isEmpty || _isExporting
                                  ? null
                                  : () => _exportBestSelling(topProducts),
                              icon: _isExporting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.file_download),
                              label: Text(l10n.exportBestSellingButton),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<BestSellingRankMode>(
                        segments: [
                          ButtonSegment(
                              value: BestSellingRankMode.netQuantity,
                              label: Text(l10n.rankByNetUnits)),
                          ButtonSegment(
                              value: BestSellingRankMode.netRevenue,
                              label: Text(l10n.rankByNetRevenue)),
                        ],
                        selected: {_rankBy},
                        onSelectionChanged: (value) =>
                            setState(() => _rankBy = value.first),
                      ),
                      const SizedBox(height: 8),
                      if (topProducts.isEmpty)
                        Text(l10n.noSalesData)
                      else ...[
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SizedBox(
                              height: 180,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: ((_rankBy ==
                                                  BestSellingRankMode
                                                      .netQuantity
                                              ? topProducts.first.netQuantity
                                                  .toDouble()
                                              : topProducts.first.netRevenue) *
                                          1.2)
                                      .clamp(10.0, double.infinity),
                                  barTouchData: BarTouchData(enabled: true),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    leftTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index >= 0 &&
                                              index < topProducts.length) {
                                            final name =
                                                topProducts[index].productName;
                                            final shortName = name.length > 8
                                                ? '${name.substring(0, 7)}…'
                                                : name;
                                            return SideTitleWidget(
                                              axisSide: meta.axisSide,
                                              child: Text(shortName,
                                                  style: const TextStyle(
                                                      fontSize: 10)),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                  ),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  barGroups:
                                      topProducts.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final item = entry.value;
                                    return BarChartGroupData(
                                      x: idx,
                                      barRods: [
                                        BarChartRodData(
                                          toY: _rankBy ==
                                                  BestSellingRankMode
                                                      .netQuantity
                                              ? item.netQuantity.toDouble()
                                              : item.netRevenue,
                                          color: Colors.indigo,
                                          width: 16,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: [
                                DataColumn(label: Text(l10n.reportProduct)),
                                DataColumn(label: Text(l10n.rankByNetUnits)),
                                DataColumn(label: Text(l10n.reportReturned)),
                                DataColumn(label: Text(l10n.rankByNetRevenue)),
                              ],
                              rows: topProducts
                                  .map(
                                    (p) => DataRow(
                                      cells: [
                                        DataCell(Text(p.productName)),
                                        DataCell(Text('${p.netQuantity}')),
                                        DataCell(Text('${p.returnedQuantity}')),
                                        DataCell(Text(formatIdr(p.netRevenue))),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Payment Method Breakdown
                      Text(
                        l10n.reportPaymentBreakdown,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: paymentCounts.entries
                            .map(
                              (e) => Chip(
                                avatar: const Icon(Icons.payment, size: 18),
                                label: Text('${e.key}: ${e.value}'),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(l10n.analyticsLoadError)),
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
                  Text(title,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700)),
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
