import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/csv_import_service.dart';

class CsvImportDialog extends ConsumerStatefulWidget {
  const CsvImportDialog({super.key, this.pickCsvText});

  final Future<String?> Function()? pickCsvText;

  @override
  ConsumerState<CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends ConsumerState<CsvImportDialog> {
  CsvImportPreview? _preview;
  CsvImportResult? _result;
  bool _isLoading = false;

  Future<String?> _pickCsvText() async {
    if (widget.pickCsvText != null) return widget.pickCsvText!();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );
    final files = result?.files;
    final bytes = files == null || files.isEmpty ? null : files.first.bytes;
    return bytes == null ? null : utf8.decode(bytes, allowMalformed: true);
  }

  Future<void> _chooseFile() async {
    setState(() => _isLoading = true);
    try {
      final csv = await _pickCsvText();
      if (csv == null) return;
      final preview = await ref.read(csvImportServiceProvider).previewProductsFromCsv(csv);
      if (mounted) setState(() => _preview = preview);
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV tidak dapat dibaca: $error')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _import() async {
    final preview = _preview;
    if (preview == null) return;
    setState(() => _isLoading = true);
    final result = await ref.read(csvImportServiceProvider).importPreview(preview);
    if (mounted) setState(() => _result = result);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final result = _result;
    return AlertDialog(
      title: const Text('Impor Inventaris CSV'),
      content: SizedBox(
        width: 640,
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            : result != null
                ? _ResultView(result: result)
                : preview != null
                    ? _PreviewView(preview: preview)
                    : const _ChooseFileView(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(result != null),
          child: Text(result == null ? 'Batal' : 'Selesai'),
        ),
        if (preview == null && result == null)
          ElevatedButton.icon(
            key: const Key('chooseCsvFileBtn'),
            onPressed: _chooseFile,
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Pilih file CSV'),
          ),
        if (preview != null && result == null)
          ElevatedButton(
            key: const Key('confirmCsvImportBtn'),
            onPressed: preview.validRows.isEmpty ? null : _import,
            child: Text('Impor ${preview.validRows.length} baris valid'),
          ),
      ],
    );
  }
}

class _ChooseFileView extends StatelessWidget {
  const _ChooseFileView();

  @override
  Widget build(BuildContext context) => const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pilih file .csv untuk ditinjau sebelum data disimpan.'),
          SizedBox(height: 12),
          Text('Kolom wajib: Barcode, InternalCode, ProductName.'),
          SizedBox(height: 12),
          Text(
            'Katalog obat bawaan hanya membantu nama, kategori, dan unit. Katalog tidak membuat stok, batch, harga beli, pemasok, atau tanggal kedaluwarsa.',
          ),
        ],
      );
}

class _PreviewView extends StatelessWidget {
  const _PreviewView({required this.preview});
  final CsvImportPreview preview;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${preview.validRows.length} valid, ${preview.invalidRowCount} dilewati'),
          if (preview.errors.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...preview.errors.map((error) => Text(error, style: const TextStyle(color: Colors.red))),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: ListView.builder(
              itemCount: preview.rows.length > 20 ? 20 : preview.rows.length,
              itemBuilder: (context, index) {
                final row = preview.rows[index];
                return ListTile(
                  dense: true,
                  leading: Icon(row.errors.isEmpty ? Icons.check_circle_outline : Icons.error_outline,
                      color: row.errors.isEmpty ? Colors.green : Colors.red),
                  title: Text('${row.rowNumber}. ${row.name.isEmpty ? '(tanpa nama)' : row.name}'),
                  subtitle: Text(row.errors.isEmpty ? row.barcode : row.errors.join(' ')),
                );
              },
            ),
          ),
          const Text('Duplikat yang sudah ada akan dilewati; baris valid lainnya tetap dapat diimpor.'),
        ],
      );
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});
  final CsvImportResult result;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${result.successCount} produk diimpor, ${result.failedCount} dilewati.'),
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...result.errors.take(20).map((error) => Text(error)),
          ],
        ],
      );
}
