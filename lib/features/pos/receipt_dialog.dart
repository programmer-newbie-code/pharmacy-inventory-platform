import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/providers.dart';
import '../../data/database.dart';
import '../../data/receipt_storage_service.dart';
import '../../l10n/app_localizations.dart';

typedef ReceiptSaveCallback = Future<String> Function();
typedef ReceiptPrintCallback = Future<void> Function();

class ReceiptDialog extends ConsumerStatefulWidget {
  const ReceiptDialog({
    super.key,
    required this.transaction,
    required this.items,
    required this.productsMap,
    this.saveReceipt,
    this.printReceipt,
  });

  final SaleTransaction transaction;
  final List<SaleItem> items;
  final Map<int, Product> productsMap;
  final ReceiptSaveCallback? saveReceipt;
  final ReceiptPrintCallback? printReceipt;

  @override
  ConsumerState<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends ConsumerState<ReceiptDialog> {
  bool _isSaving = false;
  bool _isPrinting = false;

  Future<String> _saveReceipt() async {
    if (widget.saveReceipt != null) return widget.saveReceipt!();
    final l10n = AppLocalizations.of(context)!;
    final pdfService = ref.read(receiptPdfServiceProvider);
    final pdfBytes = await pdfService.generateReceiptPdf(
      transaction: widget.transaction,
      items: widget.items,
      productsMap: widget.productsMap,
      poweredByAttribution: l10n.poweredByAttribution,
      priceColumnLabel: l10n.receiptColPrice,
      totalColumnLabel: l10n.receiptColTotal,
      txnNoLabel: l10n.receiptPdfTxnNoLabel,
      dateLabel: l10n.receiptPdfDateLabel,
      cashierLabel: l10n.receiptPdfCashierLabel,
      paymentMethodLabel: l10n.receiptPdfPaymentMethodLabel,
      doctorLabel: l10n.receiptPdfDoctorLabel,
      patientLabel: l10n.receiptPdfPatientLabel,
      itemColumnLabel: l10n.receiptPdfItemColumn,
      qtyColumnLabel: l10n.receiptPdfQtyColumn,
      totalRowLabel: l10n.receiptPdfTotalRowLabel,
      footerMessage: l10n.receiptPdfFooterMessage,
    );
    final storageService = ref.read(receiptStorageServiceProvider);
    final savedFile = await storageService.saveReceiptPdf(
      txnNo: widget.transaction.txnNo,
      createdAt: widget.transaction.createdAt,
      pdfBytes: pdfBytes,
    );
    return savedFile.path;
  }

  Future<void> _printReceipt() async {
    if (widget.printReceipt != null) return widget.printReceipt!();
    final l10n = AppLocalizations.of(context)!;
    final pdfService = ref.read(receiptPdfServiceProvider);
    final pdfBytes = await pdfService.generateReceiptPdf(
      transaction: widget.transaction,
      items: widget.items,
      productsMap: widget.productsMap,
      poweredByAttribution: l10n.poweredByAttribution,
      priceColumnLabel: l10n.receiptColPrice,
      totalColumnLabel: l10n.receiptColTotal,
      txnNoLabel: l10n.receiptPdfTxnNoLabel,
      dateLabel: l10n.receiptPdfDateLabel,
      cashierLabel: l10n.receiptPdfCashierLabel,
      paymentMethodLabel: l10n.receiptPdfPaymentMethodLabel,
      doctorLabel: l10n.receiptPdfDoctorLabel,
      patientLabel: l10n.receiptPdfPatientLabel,
      itemColumnLabel: l10n.receiptPdfItemColumn,
      qtyColumnLabel: l10n.receiptPdfQtyColumn,
      totalRowLabel: l10n.receiptPdfTotalRowLabel,
      footerMessage: l10n.receiptPdfFooterMessage,
    );
    await Printing.layoutPdf(
      onLayout: (_) => pdfBytes,
      name: 'receipt_${widget.transaction.txnNo}',
    );
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await _saveReceipt();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.receiptSavedSuccess(path)),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.receiptSaveFailed),
          action:
              SnackBarAction(label: l10n.retryButton, onPressed: _handleSave),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handlePrint() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _printReceipt();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.receiptPrintFailed),
          action:
              SnackBarAction(label: l10n.retryButton, onPressed: _handlePrint),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.transactionReceipt),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.receiptAppName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            Text(l10n.receiptTxnNoLine(widget.transaction.txnNo)),
            Text(
              l10n.receiptDateLine(
                widget.transaction.createdAt
                    .toIso8601String()
                    .replaceAll('T', ' ')
                    .substring(0, 16),
              ),
            ),
            Text(l10n.receiptPaymentMethodLine(widget.transaction.paymentMethod)),
            if (widget.transaction.patientName != null)
              Text(l10n.receiptPatientLine(widget.transaction.patientName!)),
            if (widget.transaction.doctorName != null)
              Text(l10n.receiptDoctorLine(widget.transaction.doctorName!)),
            const SizedBox(height: 12),
            Text(
              l10n.receiptItemsHeading,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...widget.items.map((item) {
              final prod = widget.productsMap[item.productId];
              final name =
                  prod?.name ?? l10n.receiptItemFallbackName(item.productId);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                          '$name x${item.qtySold} ${prod?.baseUnit ?? ''}'),
                    ),
                    Text('Rp ${item.subtotal.toStringAsFixed(0)}'),
                  ],
                ),
              );
            }),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.receiptTotalPaidLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Rp ${widget.transaction.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton.icon(
          key: const Key('saveReceiptPdfBtn'),
          icon: _isSaving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf),
          label: Text(l10n.saveReceiptPdf),
          onPressed: _isSaving ? null : _handleSave,
        ),
        OutlinedButton.icon(
          key: const Key('printReceiptBtn'),
          icon: _isPrinting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.print),
          label: Text(l10n.printReceipt),
          onPressed: _isPrinting ? null : _handlePrint,
        ),
        ElevatedButton.icon(
          key: const Key('closeReceiptButton'),
          icon: const Icon(Icons.check),
          label: Text(l10n.doneButton),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
