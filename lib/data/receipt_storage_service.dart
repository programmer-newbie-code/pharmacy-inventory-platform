import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final receiptStorageServiceProvider = Provider<ReceiptStorageService>((ref) {
  return ReceiptStorageService();
});

class ReceiptStorageService {
  ReceiptStorageService({SharedPreferences? prefsOverride})
      : _prefsOverride = prefsOverride;

  final SharedPreferences? _prefsOverride;
  static const _customBaseDirKey = 'receipt_custom_base_dir';

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? await SharedPreferences.getInstance();

  /// Returns user-configured custom receipt directory path (or null if default).
  Future<String?> getCustomBaseDirectoryPath() async {
    final p = await _prefs;
    final val = p.getString(_customBaseDirKey);
    return (val != null && val.trim().isNotEmpty) ? val.trim() : null;
  }

  /// Sets user-configured custom receipt base directory path.
  Future<void> setCustomBaseDirectoryPath(String? path) async {
    final p = await _prefs;
    if (path == null || path.trim().isEmpty) {
      await p.remove(_customBaseDirKey);
    } else {
      await p.setString(_customBaseDirKey, path.trim());
    }
  }

  /// Saves the printable receipt PDF into an organized date-based folder:
  /// `<BaseDirectory>/PharmaLoka/Receipts/YYYY-MM-DD/receipt_<txnNo>.pdf`
  Future<File> saveReceiptPdf({
    required String txnNo,
    required DateTime createdAt,
    required Uint8List pdfBytes,
    Directory? baseDirectoryOverride,
  }) async {
    Directory baseDir;
    if (baseDirectoryOverride != null) {
      baseDir = baseDirectoryOverride;
    } else {
      final customPath = await getCustomBaseDirectoryPath();
      if (customPath != null && customPath.isNotEmpty) {
        baseDir = Directory(customPath);
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }
    }

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
