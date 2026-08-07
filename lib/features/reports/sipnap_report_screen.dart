import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/sipnap_export_service.dart';

class SipnapReportScreen extends ConsumerStatefulWidget {
  const SipnapReportScreen({super.key});

  @override
  ConsumerState<SipnapReportScreen> createState() =>
      _SipnapReportScreenState();
}

class _SipnapReportScreenState extends ConsumerState<SipnapReportScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  List<SipnapReportRow> _reportRows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final service = ref.read(sipnapExportServiceProvider);
    final rows = await service.generateMonthlyReport(
      year: _selectedYear,
      month: _selectedMonth,
    );

    if (!mounted) return;
    setState(() {
      _reportRows = rows;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SIPNAP Monthly Report (Kemenkes RI)'),
        actions: [
          IconButton(
            key: const Key('refreshSipnapReportBtn'),
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Period Row
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Icon(Icons.calendar_month),
                const SizedBox(width: 8),
                const Text('Period: '),
                DropdownButton<int>(
                  value: _selectedMonth,
                  items: List.generate(
                    12,
                    (idx) => DropdownMenuItem(
                      value: idx + 1,
                      child: Text('Month ${idx + 1}'),
                    ),
                  ),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedMonth = val);
                      _loadReport();
                    }
                  },
                ),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _selectedYear,
                  items: [2025, 2026, 2027]
                      .map(
                        (y) => DropdownMenuItem(
                          value: y,
                          child: Text(y.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedYear = val);
                      _loadReport();
                    }
                  },
                ),
                const Spacer(),
                ElevatedButton.icon(
                  key: const Key('exportSipnapExcelBtn'),
                  icon: const Icon(Icons.file_download),
                  label: const Text('Export Excel'),
                  onPressed: _reportRows.isEmpty
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final service =
                              ref.read(sipnapExportServiceProvider);
                          await service.exportSipnapExcel(
                            year: _selectedYear,
                            month: _selectedMonth,
                            pharmacyName: 'Apotek Utama',
                            siaNo: 'SIA-12345/2026',
                          );
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content:
                                  Text('SIPNAP Excel report generated!'),
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reportRows.isEmpty
                    ? const Center(
                        child: Text(
                          'No controlled substances (Narkotika/Psikotropika) found.',
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('No')),
                            DataColumn(label: Text('Nama Obat')),
                            DataColumn(label: Text('Kategori')),
                            DataColumn(label: Text('Stok Awal')),
                            DataColumn(label: Text('Pengeluaran')),
                            DataColumn(label: Text('Stok Akhir')),
                            DataColumn(label: Text('Satuan')),
                          ],
                          rows: _reportRows
                              .asMap()
                              .entries
                              .map(
                                (e) => DataRow(
                                  cells: [
                                    DataCell(Text((e.key + 1).toString())),
                                    DataCell(Text(e.value.productName)),
                                    DataCell(Chip(
                                      label: Text(e.value.category),
                                    )),
                                    DataCell(
                                        Text(e.value.openingStock.toString())),
                                    DataCell(
                                        Text(e.value.qtySold.toString())),
                                    DataCell(
                                        Text(e.value.closingStock.toString())),
                                    DataCell(Text(e.value.unit)),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
