import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import 'backup_document.dart';
import 'database.dart';

class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  Future<BackupPreview> previewBackupJson(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const BackupPreviewException('Backup file was not found.');
    }
    return previewBackupData(await file.readAsString());
  }

  BackupPreview previewBackupData(String json) {
    final document = BackupDocument.parseAndValidate(json);
    return BackupPreview(
      createdAt: document.createdAt,
      schemaVersion: document.schemaVersion,
      counts: {
        for (final entry in document.data.entries)
          entry.key: entry.value.length,
      },
    );
  }

  /// Creates a full local database backup JSON export string.
  Future<String> exportDatabaseToJson() async {
    final users = await _db.select(_db.users).get();
    final locations = await _db.select(_db.storageLocations).get();
    final products = await _db.select(_db.products).get();
    final batches = await _db.select(_db.stockBatches).get();
    final sales = await _db.select(_db.saleTransactions).get();
    final saleItems = await _db.select(_db.saleItems).get();
    final auditLogs = await _db.select(_db.auditLogs).get();
    final backupLogs = await _db.select(_db.backupLogs).get();
    final csvImportLogs = await _db.select(_db.csvImportLogs).get();
    final cashierShifts = await _db.select(_db.cashierShifts).get();
    final returnTransactions = await _db.select(_db.returnTransactions).get();
    final returnItems = await _db.select(_db.returnItems).get();
    final suppliers = await _db.select(_db.suppliers).get();
    final purchaseOrders = await _db.select(_db.purchaseOrders).get();
    final purchaseOrderItems = await _db.select(_db.purchaseOrderItems).get();

    final data = <String, List<Map<String, dynamic>>>{
      'users': users.map((row) => row.toJson()).toList(),
      'storageLocations': locations.map((row) => row.toJson()).toList(),
      'products': products.map((row) => row.toJson()).toList(),
      'stockBatches': batches.map((row) => row.toJson()).toList(),
      'saleTransactions': sales.map((row) => row.toJson()).toList(),
      'saleItems': saleItems.map((row) => row.toJson()).toList(),
      'auditLogs': auditLogs.map((row) => row.toJson()).toList(),
      'backupLogs': backupLogs.map((row) => row.toJson()).toList(),
      'csvImportLogs': csvImportLogs.map((row) => row.toJson()).toList(),
      'cashierShifts': cashierShifts.map((row) => row.toJson()).toList(),
      'returnTransactions':
          returnTransactions.map((row) => row.toJson()).toList(),
      'returnItems': returnItems.map((row) => row.toJson()).toList(),
      'suppliers': suppliers.map((row) => row.toJson()).toList(),
      'purchaseOrders': purchaseOrders.map((row) => row.toJson()).toList(),
      'purchaseOrderItems':
          purchaseOrderItems.map((row) => row.toJson()).toList(),
    };
    final counts = <String, int>{
      for (final entry in data.entries) entry.key: entry.value.length,
    };

    return const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': BackupDocument.currentSchemaVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'counts': counts,
      'data': data,
    });
  }

  /// Creates a full local database backup JSON file.
  Future<String> createBackupJson(String exportDirectoryPath) async {
    final jsonStr = await exportDatabaseToJson();
    final filename =
        'pharmacy_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final filePath = p.join(exportDirectoryPath, filename);

    final file = File(filePath);
    await file.writeAsString(jsonStr);
    final bytes = await file.length();

    await _db.into(_db.backupLogs).insert(
          BackupLogsCompanion.insert(
            destination: 'local',
            status: 'Success',
            fileSize: Value(bytes),
            timestamp: Value(DateTime.now()),
          ),
        );

    return filePath;
  }

  /// Restores database tables from a backup JSON string within a transaction.
  Future<bool> restoreFromBackupData(String jsonStr) async {
    final document = BackupDocument.parseAndValidate(jsonStr);
    final data = document.data;

    await _db.transaction(() async {
      await _db.delete(_db.returnItems).go();
      await _db.delete(_db.returnTransactions).go();
      await _db.delete(_db.saleItems).go();
      await _db.delete(_db.saleTransactions).go();
      await _db.delete(_db.purchaseOrderItems).go();
      await _db.delete(_db.purchaseOrders).go();
      await _db.delete(_db.stockBatches).go();
      await _db.delete(_db.cashierShifts).go();
      await _db.delete(_db.auditLogs).go();
      await _db.delete(_db.csvImportLogs).go();
      await _db.delete(_db.products).go();
      await _db.delete(_db.suppliers).go();
      await _db.delete(_db.storageLocations).go();
      await _db.delete(_db.users).go();

      for (final row in data['users']!) {
        await _db.into(_db.users).insert(User.fromJson(_json(row)));
      }
      for (final row in data['storageLocations']!) {
        await _db
            .into(_db.storageLocations)
            .insert(StorageLocation.fromJson(_json(row)));
      }
      for (final row in data['suppliers']!) {
        await _db.into(_db.suppliers).insert(Supplier.fromJson(_json(row)));
      }
      for (final row in data['products']!) {
        await _db.into(_db.products).insert(Product.fromJson(_json(row)));
      }
      for (final row in data['stockBatches']!) {
        await _db
            .into(_db.stockBatches)
            .insert(StockBatch.fromJson(_json(row)));
      }
      for (final row in data['saleTransactions']!) {
        await _db
            .into(_db.saleTransactions)
            .insert(SaleTransaction.fromJson(_json(row)));
      }
      for (final row in data['saleItems']!) {
        await _db.into(_db.saleItems).insert(SaleItem.fromJson(_json(row)));
      }
      for (final row in data['auditLogs']!) {
        await _db.into(_db.auditLogs).insert(AuditLog.fromJson(_json(row)));
      }
      for (final row in data['csvImportLogs'] ?? const []) {
        await _db
            .into(_db.csvImportLogs)
            .insert(CsvImportLog.fromJson(_json(row)));
      }
      for (final row in data['cashierShifts']!) {
        await _db
            .into(_db.cashierShifts)
            .insert(CashierShift.fromJson(_json(row)));
      }
      for (final row in data['returnTransactions']!) {
        await _db
            .into(_db.returnTransactions)
            .insert(ReturnTransaction.fromJson(_json(row)));
      }
      for (final row in data['returnItems']!) {
        await _db.into(_db.returnItems).insert(ReturnItem.fromJson(_json(row)));
      }
      for (final row in data['purchaseOrders']!) {
        await _db
            .into(_db.purchaseOrders)
            .insert(PurchaseOrder.fromJson(_json(row)));
      }
      for (final row in data['purchaseOrderItems']!) {
        await _db
            .into(_db.purchaseOrderItems)
            .insert(PurchaseOrderItem.fromJson(_json(row)));
      }

      await _db.delete(_db.backupLogs).go();
      for (final row in data['backupLogs']!) {
        await _db.into(_db.backupLogs).insert(BackupLog.fromJson(_json(row)));
      }
    });

    await _db.into(_db.backupLogs).insert(
          BackupLogsCompanion.insert(
            destination: 'restore',
            status: 'Success',
            fileSize: Value(utf8.encode(jsonStr).length),
            timestamp: Value(DateTime.now()),
          ),
        );

    return true;
  }

  /// Restores database tables from a backup JSON file within a transaction.
  Future<bool> restoreFromBackupJson(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return false;
    }

    final jsonStr = await file.readAsString();
    return restoreFromBackupData(jsonStr);
  }

  /// Lists past backup logs.
  Future<List<BackupLog>> listBackupLogs() {
    return (_db.select(_db.backupLogs)
          ..orderBy([
            (tbl) => OrderingTerm.desc(tbl.timestamp),
            (tbl) => OrderingTerm.desc(tbl.id),
          ]))
        .get();
  }

  Map<String, dynamic> _json(Map<String, Object?> row) =>
      Map<String, dynamic>.from(row);
}

class BackupPreview {
  const BackupPreview({
    required this.createdAt,
    required this.schemaVersion,
    required this.counts,
  });

  final DateTime createdAt;
  final int schemaVersion;
  final Map<String, int> counts;
}

class BackupPreviewException implements Exception {
  const BackupPreviewException(this.message);

  final String message;

  @override
  String toString() => 'BackupPreviewException: $message';
}
