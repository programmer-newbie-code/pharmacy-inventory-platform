import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get role => text()(); // admin|inventory|kasir|audit
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class StorageLocations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get barcode => text().unique()();
  TextColumn get internalCode => text().unique()();
  TextColumn get name => text()();
  TextColumn get activeIngredient => text()();
  RealColumn get ingredientPct => real()();
  TextColumn get baseUnit => text()();
  TextColumn get purchaseUnit => text()();
  IntColumn get unitsPerPurchaseUnit => integer()();
  RealColumn get costPricePerBaseUnit => real()();
  RealColumn get marginPct => real()();
  IntColumn get reorderThreshold => integer()();
  BoolColumn get isControlled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get nationalDrugCode => text().nullable()();
  IntColumn get storageLocationId =>
      integer().nullable().references(StorageLocations, #id)();
  TextColumn get category => text()();
  TextColumn get createdBy => text()();
  TextColumn get updatedBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get deviceId => text().nullable()();
}

class StockBatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get batchNo => text()();
  DateTimeColumn get receivedDate => dateTime()();
  DateTimeColumn get expiryDate => dateTime()();
  IntColumn get qtyReceived => integer()();
  IntColumn get qtyRemaining => integer()();
  RealColumn get costPricePerBaseUnit => real()();
  TextColumn get supplier => text()();
  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get deviceId => text().nullable()();
}

class SaleTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get txnNo => text().unique()();
  TextColumn get patientName => text().nullable()();
  IntColumn get cashierId => integer().references(Users, #id)();
  RealColumn get totalAmount => real()();
  TextColumn get paymentMethod => text()();
  BoolColumn get hasPrescription =>
      boolean().withDefault(const Constant(false))();
  TextColumn get prescriptionPhotoPath => text().nullable()();
  TextColumn get doctorName => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get deviceId => text().nullable()();
}

class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().references(SaleTransactions, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get batchId => integer().references(StockBatches, #id)();
  IntColumn get qtySold => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get subtotal => real()();
}

class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  // fix ci: named `entityTable`, not `tableName` — the latter collides with
  // drift's own `Table.tableName` getter (used to override the SQL table name).
  TextColumn get entityTable => text()();
  IntColumn get recordId => integer()();
  TextColumn get action => text()(); // create|update|delete
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  IntColumn get userId => integer().references(Users, #id)();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

class BackupLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get destination => text()(); // drive|local
  TextColumn get status => text()();
  IntColumn get fileSize => integer().nullable()();
}

@DriftDatabase(tables: [
  Users,
  StorageLocations,
  Products,
  StockBatches,
  SaleTransactions,
  SaleItems,
  AuditLogs,
  BackupLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  factory AppDatabase.defaultConnection() => AppDatabase(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'pharmacy_inventory.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
