import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/report_repository.dart';

class CategorySalesData {
  CategorySalesData({required this.category, required this.totalAmount, required this.unitsSold});
  final String category;
  final double totalAmount;
  final int unitsSold;
}

class TopProductData {
  TopProductData({required this.productName, required this.unitsSold, required this.revenue});
  final String productName;
  final int unitsSold;
  final double revenue;
}

final salesAnalyticsFutureProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, DateTimeRange>((ref, range) async {
  final reportRepo = ref.watch(reportRepositoryProvider);
  final saleRepo = ref.watch(saleRepositoryProvider);
  final prodRepo = ref.watch(productRepositoryProvider);
  final returnRepo = ref.watch(returnRepositoryProvider);

  final summary = await reportRepo.getSalesSummary(startDate: range.start, endDate: range.end);
  final txns = await saleRepo.listTransactions();
  final products = await prodRepo.listProducts();
  final returns = await returnRepo.listReturns();

  final filteredTxns = txns.where((t) => t.createdAt.isAfter(range.start) && t.createdAt.isBefore(range.end)).toList();
  final filteredReturns = returns.where((r) => r.createdAt.isAfter(range.start) && r.createdAt.isBefore(range.end)).toList();

  double totalRefunds = 0;
  for (final r in filteredReturns) {
    totalRefunds += r.refundAmount;
  }

  // Payment methods breakdown
  final paymentCounts = <String, int>{'Cash': 0, 'QRIS': 0, 'Debit': 0, 'Credit': 0};
  for (final t in filteredTxns) {
    final pm = t.paymentMethod;
    paymentCounts[pm] = (paymentCounts[pm] ?? 0) + 1;
  }

  // Product sales and category breakdown
  final prodSalesMap = <int, int>{}; // prodId -> totalQty
  final prodRevMap = <int, double>{}; // prodId -> totalRevenue

  for (final t in filteredTxns) {
    final items = await saleRepo.getSaleItemsForTransaction(t.id);
    for (final item in items) {
      prodSalesMap[item.productId] = (prodSalesMap[item.productId] ?? 0) + item.qtySold;
      prodRevMap[item.productId] = (prodRevMap[item.productId] ?? 0) + item.subtotal;
    }
  }

  final prodMap = {for (var p in products) p.id: p};
  final categoryMap = <String, double>{};
  final topProducts = <TopProductData>[];

  prodSalesMap.forEach((prodId, qty) {
    final prod = prodMap[prodId];
    final name = prod?.name ?? 'Product #$prodId';
    final rev = prodRevMap[prodId] ?? 0;
    final cat = prod?.category ?? 'General';

    categoryMap[cat] = (categoryMap[cat] ?? 0) + rev;
    topProducts.add(TopProductData(productName: name, unitsSold: qty, revenue: rev));
  });

  topProducts.sort((a, b) => b.revenue.compareTo(a.revenue));

  return {
    'summary': summary,
    'totalTxns': filteredTxns.length,
    'totalRefunds': totalRefunds,
    'paymentCounts': paymentCounts,
    'categoryMap': categoryMap,
    'topProducts': topProducts.take(5).toList(),
  };
});

class SalesAnalyticsScreen extends ConsumerStatefulWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  ConsumerState<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends ConsumerState<SalesAnalyticsScreen> {
  late DateTimeRange _dateRange;
  String _selectedPreset = 'This Month';

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

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(salesAnalyticsFutureProvider(_dateRange));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Analytics & Insights'),
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
                  segments: const [
                    ButtonSegment(value: 'Today', label: Text('Today')),
                    ButtonSegment(value: 'This Week', label: Text('This Week')),
                    ButtonSegment(value: 'This Month', label: Text('This Month')),
                  ],
                  selected: {_selectedPreset},
                  onSelectionChanged: (val) => _applyPreset(val.first),
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
                final summary = data['summary'] as SalesSummary;
                final totalTxns = data['totalTxns'] as int;
                final totalRefunds = data['totalRefunds'] as double;
                final paymentCounts = data['paymentCounts'] as Map<String, int>;
                final categoryMap = data['categoryMap'] as Map<String, double>;
                final topProducts = data['topProducts'] as List<TopProductData>;

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
                              title: 'GROSS REVENUE',
                              value: 'Rp ${summary.totalRevenue.toStringAsFixed(0)}',
                              icon: Icons.monetization_on,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              title: 'TRANSACTIONS',
                              value: '$totalTxns Orders',
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
                              title: 'GROSS PROFIT',
                              value: 'Rp ${summary.grossProfit.toStringAsFixed(0)} (${marginPct.toStringAsFixed(1)}%)',
                              icon: Icons.trending_up,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              title: 'TOTAL REFUNDS',
                              value: 'Rp ${totalRefunds.toStringAsFixed(0)}',
                              icon: Icons.assignment_return,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Sales by Category
                      const Text(
                        'Sales by Product Category',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      if (categoryMap.isEmpty)
                        const Text('No category sales data for selected period.')
                      else
                        ...categoryMap.entries.map((e) {
                          final pct = summary.totalRevenue > 0 ? (e.value / summary.totalRevenue) : 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text('Rp ${e.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(1)}%)'),
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

                      // Top 5 Best-Selling Products Table
                      const Text(
                        'Top 5 Best-Selling Products',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      if (topProducts.isEmpty)
                        const Text('No sales recorded in selected period.')
                      else
                        Card(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Product')),
                                DataColumn(label: Text('Qty Sold')),
                                DataColumn(label: Text('Revenue')),
                              ],
                              rows: topProducts
                                  .map(
                                    (p) => DataRow(
                                      cells: [
                                        DataCell(Text(p.productName)),
                                        DataCell(Text('${p.unitsSold}')),
                                        DataCell(Text('Rp ${p.revenue.toStringAsFixed(0)}')),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Payment Method Breakdown
                      const Text(
                        'Payment Method Breakdown',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
              error: (err, _) => Center(child: Text('Error loading analytics: $err')),
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
                  Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
