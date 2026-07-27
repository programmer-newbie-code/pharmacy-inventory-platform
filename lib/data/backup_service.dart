import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import 'database.dart';

class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  /// Creates a local database backup JSON export.
  Future<String> createBackupJson(String exportDirectoryPath) async {
    final products = await _db.select(_db.products).get();
    final batches = await _db.select(_db.stockBatches).get();
    final txns = await _db.select(_db.saleTransactions).get();
    final saleItems = await _db.select(_db.saleItems).get();

    final backupData = {
      'exportedAt': DateTime.now().toIso8601String(),
      'version': 1,
      'productsCount': products.length,
      'batchesCount': batches.length,
      'transactionsCount': txns.length,
      'itemsCount': saleItems.length,
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);
    final filename =
        'pharmacy_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final filePath = p.join(exportDirectoryPath, filename);

    final file = File(filePath);
    await file.writeAsString(jsonStr);

    await _db.into(_db.backupLogs).insert(
          BackupLogsCompanion.insert(
            backupType: 'Local JSON',
            filePath: Value(filePath),
            status: 'Success',
            detail: Value('Exported ${products.length} products, ${batches.length} stock batches'),
            createdAt: Value(DateTime.now()),
          ),
        );

    return filePath;
  }

  /// Lists past backup logs.
  Future<List<BackupLog>> listBackupLogs() {
    return (_db.select(_db.backupLogs)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
  }
}
