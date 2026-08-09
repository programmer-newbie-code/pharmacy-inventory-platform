import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final receiptStorageServiceProvider = Provider<ReceiptStorageService>((ref) {
  return ReceiptStorageService();
});

class ReceiptStorageService {
  /// Saves the printable receipt PDF into an organized date-based folder:
  /// `Documents/PharmaLoka/Receipts/YYYY-MM-DD/receipt_<txnNo>.pdf`
  Future<File> saveReceiptPdf({
    required String txnNo,
    required DateTime createdAt,
    required Uint8List pdfBytes,
    Directory? baseDirectoryOverride,
  }) async {
    final Directory baseDir = baseDirectoryOverride ??
        await getApplicationDocumentsDirectory();

    final String dateFolder =
        '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
    final String sanitizedTxnNo = txnNo.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final String targetDirPath =
        p.join(baseDir.path, 'PharmaLoka', 'Receipts', dateFolder);

    final targetDir = Directory(targetDirPath);
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final String filePath =
        p.join(targetDir.path, 'receipt_$sanitizedTxnNo.pdf');
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    return file;
  }
}
