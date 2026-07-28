import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import 'database.dart';

class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  /// Creates a full local database backup JSON export string.
  Future<String> exportDatabaseToJson() async {
    final users = await _db.select(_db.users).get();
    final locations = await _db.select(_db.storageLocations).get();
    final products = await _db.select(_db.products).get();
    final batches = await _db.select(_db.stockBatches).get();
    final txns = await _db.select(_db.saleTransactions).get();
    final saleItems = await _db.select(_db.saleItems).get();

    final backupData = {
      'exportedAt': DateTime.now().toIso8601String(),
      'version': 1,
      'users': users.map((u) => u.toJson()).toList(),
      'storageLocations': locations.map((l) => l.toJson()).toList(),
      'products': products.map((p) => p.toJson()).toList(),
      'stockBatches': batches.map((b) => b.toJson()).toList(),
      'saleTransactions': txns.map((t) => t.toJson()).toList(),
      'saleItems': saleItems.map((i) => i.toJson()).toList(),
      'productsCount': products.length,
      'batchesCount': batches.length,
      'transactionsCount': txns.length,
      'itemsCount': saleItems.length,
    };

    return const JsonEncoder.withIndent('  ').convert(backupData);
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
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    await _db.transaction(() async {
      // Clear existing records in proper dependency order
      await _db.delete(_db.saleItems).go();
      await _db.delete(_db.saleTransactions).go();
      await _db.delete(_db.stockBatches).go();
      await _db.delete(_db.products).go();
      await _db.delete(_db.storageLocations).go();
      await _db.delete(_db.users).go();

      // Restore Users
      if (data['users'] != null) {
        final usersList = data['users'] as List;
        for (final item in usersList) {
          await _db.into(_db.users).insert(User.fromJson(item as Map<String, dynamic>));
        }
      }

      // Restore Storage Locations
      if (data['storageLocations'] != null) {
        final locationsList = data['storageLocations'] as List;
        for (final item in locationsList) {
          await _db.into(_db.storageLocations).insert(StorageLocation.fromJson(item as Map<String, dynamic>));
        }
      }

      // Restore Products
      if (data['products'] != null) {
        final productsList = data['products'] as List;
        for (final item in productsList) {
          await _db.into(_db.products).insert(Product.fromJson(item as Map<String, dynamic>));
        }
      }

      // Restore Stock Batches
      if (data['stockBatches'] != null) {
        final batchesList = data['stockBatches'] as List;
        for (final item in batchesList) {
          await _db.into(_db.stockBatches).insert(StockBatch.fromJson(item as Map<String, dynamic>));
        }
      }

      // Restore Sale Transactions
      if (data['saleTransactions'] != null) {
        final txnsList = data['saleTransactions'] as List;
        for (final item in txnsList) {
          await _db.into(_db.saleTransactions).insert(SaleTransaction.fromJson(item as Map<String, dynamic>));
        }
      }

      // Restore Sale Items
      if (data['saleItems'] != null) {
        final itemsList = data['saleItems'] as List;
        for (final item in itemsList) {
          await _db.into(_db.saleItems).insert(SaleItem.fromJson(item as Map<String, dynamic>));
        }
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
}

