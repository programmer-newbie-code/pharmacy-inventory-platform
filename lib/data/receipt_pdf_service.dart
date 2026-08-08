import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'database.dart';

class ReceiptPdfService {
  /// Generates printable PDF receipt bytes for a completed sale transaction.
  Future<Uint8List> generateReceiptPdf({
    required SaleTransaction transaction,
    required List<SaleItem> items,
    required Map<int, Product> productsMap,
    String pharmacyName = 'Apotek Medika Sehat',
    String pharmacyAddress = 'Jl. Merdeka No. 45, Jakarta',
    String cashierName = 'Kasir Staff',
    Uint8List? logoBytes,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Pharmacy Logo & Header
              if (logoBytes != null) ...[
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(logoBytes),
                    height: 36,
                    fit: pw.BoxFit.contain,
                  ),
                ),
                pw.SizedBox(height: 4),
              ],
              pw.Center(
                child: pw.Text(
                  pharmacyName,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  pharmacyAddress,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Divider(thickness: 1),

              // Transaction Info
              pw.Text('No. Transaksi: ${transaction.txnNo}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text(
                'Tanggal: ${transaction.createdAt.toIso8601String().split('T').first} ${transaction.createdAt.toIso8601String().split('T').last.substring(0, 5)}',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text('Kasir: $cashierName', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Pembayaran: ${transaction.paymentMethod}', style: const pw.TextStyle(fontSize: 8)),
              if (transaction.hasPrescription) ...[
                pw.SizedBox(height: 4),
                pw.Text('Dokter: ${transaction.doctorName ?? "-"}', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('Pasien: ${transaction.patientName ?? "-"}', style: const pw.TextStyle(fontSize: 8)),
              ],
              pw.Divider(thickness: 0.5),

              // Itemized Table
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('Item', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Qty', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Harga', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Total', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  for (final item in items)
                    pw.TableRow(
                      children: [
                        pw.Text(
                          productsMap[item.productId]?.name ?? 'Item ${item.productId}',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text('${item.qtySold}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('Rp ${item.unitPrice.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('Rp ${item.subtotal.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                ],
              ),
              pw.Divider(thickness: 1),

              // Total Summary
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    'Rp ${transaction.totalAmount.toStringAsFixed(0)}',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Footer & Barcode
              pw.Center(
                child: pw.Text(
                  '-- Terima Kasih --\nSemoga Lekas Sembuh!',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: transaction.txnNo,
                  width: 140,
                  height: 35,
                  drawText: true,
                  textStyle: const pw.TextStyle(fontSize: 7),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
