import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../data/report_repository.dart';
import '../../l10n/app_localizations.dart';

final salesReportFutureProvider = FutureProvider.autoDispose<SalesSummary>((ref) {
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
    setState(() => _isExporting = true);
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final repo = ref.read(reportRepositoryProvider);
      final rows = await repo.getDetailedSalesRows(startDate: startDate, endDate: endDate);
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
            content: Text('Excel report saved to: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export error: $err'),
            backgroundColor: Colors.red,
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
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan & Keuangan'),
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
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan Bulan Ini',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildKpiRow('Total Transaksi', '${summary.totalTransactions} Transaksi', Colors.blue),
                    const Divider(height: 24),
                    _buildKpiRow('Total Pendapatan (Revenue)', currencyFormat.format(summary.totalRevenue), Colors.green),
                    const Divider(height: 24),
                    _buildKpiRow('Harga Pokok Penjualan (COGS)', currencyFormat.format(summary.totalCostOfGoods), Colors.orange),
                    const Divider(height: 24),
                    _buildKpiRow('Laba Kotor (Gross Profit)', currencyFormat.format(summary.grossProfit), Colors.purple),
                    const Divider(height: 24),
                    _buildKpiRow('Margin Kotor (%)', '${marginPct.toStringAsFixed(1)}%', Colors.teal),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: const Key('exportExcelBtn'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.table_chart),
              label: Text(_isExporting ? 'Exporting...' : l10n.exportExcelButton),
              onPressed: _isExporting ? null : () => _exportExcel(summary),
            ),
          ],
        ),
      );
    },
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (err, stack) => Center(child: Text('Error: $err')),
  ),
);
}

Widget _buildKpiRow(String title, String value, Color color) {
return Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, color: Colors.black87)),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
