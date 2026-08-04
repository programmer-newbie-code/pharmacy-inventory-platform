import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/csv_import_service.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_session.dart';

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
  String _sourceName = 'unknown.csv';

  Future<String?> _pickCsvText() async {
    if (widget.pickCsvText != null) return widget.pickCsvText!();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );
    final files = result?.files;
    if (files != null && files.isNotEmpty) _sourceName = files.first.name;
    final bytes = files == null || files.isEmpty ? null : files.first.bytes;
    return bytes == null ? null : utf8.decode(bytes, allowMalformed: true);
  }

  Future<void> _chooseFile() async {
    setState(() => _isLoading = true);
    try {
      final csv = await _pickCsvText();
      if (csv == null) return;
      final preview = await ref
          .read(csvImportServiceProvider)
          .previewProductsFromCsv(csv);
      if (mounted) setState(() => _preview = preview);
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.csvReadFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _import() async {
    final preview = _preview;
    if (preview == null) return;
    setState(() => _isLoading = true);
    final currentUser = ref.read(authSessionProvider);
    final result = await ref
        .read(csvImportServiceProvider)
        .importPreview(
          preview,
          sourceName: _sourceName,
          createdBy: currentUser?.username ?? 'admin',
        );
    if (mounted) setState(() => _result = result);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final preview = _preview;
    final result = _result;
    return AlertDialog(
      title: Text(l10n.importCsvTitle),
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
          child: Text(result == null ? l10n.cancelButton : l10n.doneButton),
        ),
        if (preview == null && result == null)
          ElevatedButton.icon(
            key: const Key('chooseCsvFileBtn'),
            onPressed: _chooseFile,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(l10n.chooseCsvFile),
          ),
        if (preview != null && result == null)
          ElevatedButton(
            key: const Key('confirmCsvImportBtn'),
            onPressed: preview.validRows.isEmpty ? null : _import,
            child: Text(l10n.csvImportValidRows(preview.validRows.length)),
          ),
      ],
    );
  }
}

class _ChooseFileView extends StatelessWidget {
  const _ChooseFileView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.csvChooseDescription),
        const SizedBox(height: 12),
        Text(l10n.csvRequiredColumns),
        const SizedBox(height: 12),
        Text(l10n.csvCatalogNotice),
      ],
    );
  }
}

class _PreviewView extends StatelessWidget {
  const _PreviewView({required this.preview});
  final CsvImportPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.csvPreviewSummary(
            preview.validRows.length,
            preview.invalidRowCount,
          ),
        ),
        if (preview.errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...preview.errors.map(
            (error) => Text(error, style: const TextStyle(color: Colors.red)),
          ),
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
                leading: Icon(
                  row.errors.isEmpty
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  color: row.errors.isEmpty ? Colors.green : Colors.red,
                ),
                title: Text(
                  '${row.rowNumber}. ${row.name.isEmpty ? l10n.csvUnnamedProduct : row.name}',
                ),
                subtitle: Text(
                  row.errors.isEmpty ? row.barcode : row.errors.join(' '),
                ),
              );
            },
          ),
        ),
        Text(l10n.csvExistingDuplicates),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});
  final CsvImportResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.csvResultSummary(result.successCount, result.failedCount)),
        if (result.errors.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...result.errors.take(20).map((error) => Text(error)),
        ],
      ],
    );
  }
}
