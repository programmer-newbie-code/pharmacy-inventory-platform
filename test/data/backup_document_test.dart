import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/backup_document.dart';

const _collections = [
  'users',
  'storageLocations',
  'products',
  'stockBatches',
  'saleTransactions',
  'saleItems',
  'auditLogs',
  'backupLogs',
  'cashierShifts',
  'returnTransactions',
  'returnItems',
  'suppliers',
  'purchaseOrders',
  'purchaseOrderItems',
];

String backup({
  int version = 2,
  Map<String, List<Map<String, Object?>>> changes = const {},
  Map<String, Object?>? counts,
}) {
  final data = {
    for (final name in _collections) name: <Map<String, Object?>>[],
  }..addAll(changes);

  return jsonEncode({
    'schemaVersion': version,
    'createdAt': '2026-07-29T12:00:00.000Z',
    'counts': counts ??
        {for (final entry in data.entries) entry.key: entry.value.length},
    'data': data,
  });
}

void main() {
  test('parses a complete version 2 document', () {
    final document = BackupDocument.parseAndValidate(backup());

    expect(document.schemaVersion, 2);
    expect(document.createdAt, DateTime.utc(2026, 7, 29, 12));
    expect(document.data.keys, containsAll(_collections));
    expect(document.data['csvImportLogs'], isEmpty);
  });

  test('accepts optional CSV import history rows', () {
    final document = BackupDocument.parseAndValidate(
      backup(changes: {
        'csvImportLogs': [
          {
            'id': 1,
            'importedAt': '2026-08-04T12:00:00.000Z',
            'sourceName': 'catalog.csv',
            'createdBy': 'admin',
            'totalRows': 2,
            'importedRows': 2,
            'rejectedRows': 0,
            'status': 'success',
            'errorSummary': null,
          },
        ],
      }),
    );

    expect(document.data['csvImportLogs'], hasLength(1));
  });

  test('normalizes a legacy version 1 document', () {
    final source = jsonEncode({
      'version': 1,
      'exportedAt': '2026-07-28T12:00:00.000Z',
      for (final name in _collections.take(6)) name: <Object?>[],
    });

    final document = BackupDocument.parseAndValidate(source);

    expect(document.schemaVersion, 1);
    expect(document.data['returnTransactions'], isEmpty);
    expect(document.data['suppliers'], isEmpty);
  });

  test('rejects a missing version 2 collection', () {
    final decoded = jsonDecode(backup()) as Map<String, dynamic>;
    (decoded['data'] as Map<String, dynamic>).remove('products');

    expect(
      () => BackupDocument.parseAndValidate(jsonEncode(decoded)),
      throwsA(isA<BackupValidationException>()),
    );
  });

  test('rejects invalid counts and broken references', () {
    expect(
      () => BackupDocument.parseAndValidate(
        backup(counts: {
          for (final name in _collections) name: name == 'users' ? 2 : 0
        }),
      ),
      throwsA(isA<BackupValidationException>()),
    );

    expect(
      () => BackupDocument.parseAndValidate(
        backup(changes: {
          'products': [
            {'id': 8, 'storageLocationId': 99},
          ],
        }),
      ),
      throwsA(isA<BackupValidationException>()),
    );
  });

  test('rejects duplicate IDs and broken dependent references', () {
    expect(
      () => BackupDocument.parseAndValidate(
        backup(changes: {
          'users': [
            {'id': 1},
            {'id': 1},
          ],
        }),
      ),
      throwsA(isA<BackupValidationException>()),
    );

    expect(
      () => BackupDocument.parseAndValidate(
        backup(changes: {
          'returnItems': [
            {'id': 1, 'returnTxnId': 2, 'saleItemId': 3},
          ],
        }),
      ),
      throwsA(isA<BackupValidationException>()),
    );
  });
}
