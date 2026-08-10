import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/receipt_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;
  late ReceiptStorageService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('receipt_storage_test_');
    service = ReceiptStorageService();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('saveReceiptPdf saves PDF into date-based subfolder named by txnNo',
      () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
    final createdAt = DateTime(2026, 8, 9, 14, 30);
    const txnNo = 'TXN-20260809-0001';

    final savedFile = await service.saveReceiptPdf(
      txnNo: txnNo,
      createdAt: createdAt,
      pdfBytes: bytes,
      baseDirectoryOverride: tempDir,
    );

    expect(await savedFile.exists(), isTrue);
    expect(savedFile.path, contains('PharmaLoka'));
    expect(savedFile.path, contains('Receipts'));
    expect(savedFile.path, contains('2026-08-09'));
    expect(savedFile.path, contains('receipt_TXN-20260809-0001.pdf'));
    expect(await savedFile.readAsBytes(), equals(bytes));
  });

  test('persists and clears configured receipt base directory', () async {
    SharedPreferences.setMockInitialValues({});
    final service = ReceiptStorageService(
      prefsOverride: await SharedPreferences.getInstance(),
    );

    expect(await service.getCustomBaseDirectoryPath(), isNull);
    await service.setCustomBaseDirectoryPath('  C:/Receipts  ');
    expect(await service.getCustomBaseDirectoryPath(), 'C:/Receipts');
    await service.setCustomBaseDirectoryPath('');
    expect(await service.getCustomBaseDirectoryPath(), isNull);
  });
}
