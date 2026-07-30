import 'package:drift/drift.dart';

import 'connection/connection.dart';

part 'database.g.dart';

@DataClassName('User')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get role => text()(); // admin|inventory|kasir|audit
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('StorageLocation')
class StorageLocations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Product')
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

@DataClassName('StockBatch')
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

@DataClassName('StockAdjustment')
class StockAdjustments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get batchId => integer().nullable().references(StockBatches, #id)();
  IntColumn get quantityDelta => integer()();
  TextColumn get reason => text()();
  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('SaleTransaction')
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

@DataClassName('SaleItem')
class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().references(SaleTransactions, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get batchId => integer().references(StockBatches, #id)();
  IntColumn get qtySold => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get subtotal => real()();
}

@DataClassName('AuditLog')
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

@DataClassName('BackupLog')
class BackupLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get destination => text()(); // drive|local
  TextColumn get status => text()();
  IntColumn get fileSize => integer().nullable()();
}

@DataClassName('CashierShift')
class CashierShifts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cashierId => integer().references(Users, #id)();
  RealColumn get openingBalance => real()();
  RealColumn get expectedCash => real().nullable()(); // calculated on close
  RealColumn get actualCash => real().nullable()();   // entered by cashier
  RealColumn get discrepancy => real().nullable()();  // actual - expected
  TextColumn get status => text()(); // open|closed
  DateTimeColumn get openedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get closedAt => dateTime().nullable()();
}

@DataClassName('ReturnTransaction')
class ReturnTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get returnNo => text().unique()();
  IntColumn get originalTxnId => integer().references(SaleTransactions, #id)();
  IntColumn get processedBy => integer().references(Users, #id)();
  TextColumn get reason => text()(); // wrong_product|allergic|defective|other
  RealColumn get refundAmount => real()();
  TextColumn get refundMethod => text()(); // Cash|Store Credit|Bank Transfer
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ReturnItem')
class ReturnItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get returnTxnId => integer().references(ReturnTransactions, #id)();
  IntColumn get saleItemId => integer().references(SaleItems, #id)();
  IntColumn get qtyReturned => integer()();
  BoolColumn get restocked => boolean().withDefault(const Constant(false))();
}

@DataClassName('Supplier')
class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get contactPerson => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('PurchaseOrder')
class PurchaseOrders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get poNumber => text().unique()();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  TextColumn get status => text()(); // draft|sent|received|cancelled
  RealColumn get totalAmount => real()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get receivedAt => dateTime().nullable()();
}

@DataClassName('PurchaseOrderItem')
class PurchaseOrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseOrderId => integer().references(PurchaseOrders, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get qtyOrdered => integer()();
  IntColumn get qtyReceived => integer().withDefault(const Constant(0))();
  RealColumn get unitCost => real()();
}

@DriftDatabase(tables: [
  Users,
  StorageLocations,
  Products,
  StockBatches,
  StockAdjustments,
  SaleTransactions,
  SaleItems,
  AuditLogs,
  BackupLogs,
  CashierShifts,
  ReturnTransactions,
  ReturnItems,
  Suppliers,
  PurchaseOrders,
  PurchaseOrderItems,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.defaultConnection() => AppDatabase(openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(stockAdjustments);
          }
        },
      );
}
