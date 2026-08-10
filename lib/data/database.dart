import 'package:drift/drift.dart';

import 'connection/connection.dart';

part 'database.g.dart';

@DataClassName('User')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get role => text()(); // admin|inventory|kasir|audit
  TextColumn get photoPath => text().nullable()();
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
  BoolColumn get isControlled => boolean().withDefault(const Constant(false))();
  TextColumn get controlledCategory => text().nullable()(); // Narkotika | Psikotropika | Prekursor | OOT
  TextColumn get nationalDrugCode => text().nullable()();
  IntColumn get storageLocationId =>
      integer().nullable().references(StorageLocations, #id)();
  TextColumn get category => text()();
  TextColumn get createdBy => text()();
  TextColumn get updatedBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get deviceId => text().nullable()();
  TextColumn get imagePath => text().nullable()();
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
  IntColumn get patientId => integer().nullable().references(Patients, #id)();
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

@DataClassName('CsvImportLog')
class CsvImportLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get importedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get sourceName => text()();
  TextColumn get createdBy => text()();
  IntColumn get totalRows => integer()();
  IntColumn get importedRows => integer()();
  IntColumn get rejectedRows => integer()();
  TextColumn get status => text()(); // success|failed
  TextColumn get errorSummary => text().nullable()();
}

@DataClassName('CashierShift')
class CashierShifts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cashierId => integer().references(Users, #id)();
  RealColumn get openingBalance => real()();
  RealColumn get expectedCash => real().nullable()(); // calculated on close
  RealColumn get actualCash => real().nullable()(); // entered by cashier
  RealColumn get discrepancy => real().nullable()(); // actual - expected
  TextColumn get discrepancyReason => text().nullable()();
  TextColumn get status => text()(); // open|closed
  DateTimeColumn get openedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get closedAt => dateTime().nullable()();
}

@DataClassName('CashMovement')
class CashMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get shiftId => integer().references(CashierShifts, #id)();
  TextColumn get movementType => text()(); // cash_in|cash_out
  TextColumn get category => text()(); // owner_draw|operational_expense|bank_deposit|topup|other
  RealColumn get amount => real()();
  TextColumn get notes => text().nullable()();
  IntColumn get performedBy => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
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
  TextColumn get paymentTerms => text().nullable()(); // e.g. "Net 30", "COD"
  IntColumn get leadTimeDays => integer().withDefault(const Constant(7))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
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

@DataClassName('PurchaseReceivingItem')
class PurchaseReceivingItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseOrderId => integer().references(PurchaseOrders, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get qtyOrdered => integer()();
  IntColumn get qtyReceived => integer()();
  TextColumn get batchNo => text()();
  DateTimeColumn get expiryDate => dateTime()();
  RealColumn get costPricePerBaseUnit => real()();
  TextColumn get discrepancyReason => text().nullable()();
  IntColumn get receivedBy => integer().nullable().references(Users, #id)();
  DateTimeColumn get receivedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get deviceId => text().nullable()();
}

@DataClassName('Patient')
class Patients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get allergies => text().nullable()(); // comma-separated or text
  TextColumn get chronicConditions => text().nullable()(); // e.g. "Diabetes, Hipertensi"
  TextColumn get notes => text().nullable()();
  IntColumn get createdBy => integer().nullable().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get deviceId => text().nullable()();
}

@DataClassName('Prescription')
class Prescriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get patientId => integer().references(Patients, #id)();
  IntColumn get transactionId => integer().nullable().references(SaleTransactions, #id)();
  TextColumn get doctorName => text()();
  TextColumn get doctorSipNo => text().nullable()();
  TextColumn get clinicName => text().nullable()();
  DateTimeColumn get prescriptionDate => dateTime()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isChronic => boolean().withDefault(const Constant(false))();
  IntColumn get refillIntervalDays => integer().nullable()();
  DateTimeColumn get nextRefillDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get deviceId => text().nullable()();
}

@DataClassName('CompoundingFormula')
class CompoundingFormulas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()(); // e.g. "Puyer Batuk Anak"
  TextColumn get description => text().nullable()();
  TextColumn get dosageForm => text()(); // "puyer"|"kapsul"|"salep"|"sirup"
  IntColumn get yieldQuantity => integer()(); // e.g. 10
  TextColumn get yieldUnit => text()(); // e.g. "bungkus", "kapsul"
  TextColumn get preparationNotes => text().nullable()();
  IntColumn get createdBy => integer().nullable().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get deviceId => text().nullable()();
}

@DataClassName('CompoundingIngredient')
class CompoundingIngredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get formulaId => integer().references(CompoundingFormulas, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get qtyPerYield => real()(); // quantity in base_unit needed for yieldQuantity
  BoolColumn get isActiveIngredient => boolean().withDefault(const Constant(true))();
  TextColumn get notes => text().nullable()();
}

@DataClassName('CompoundingTransaction')
class CompoundingTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get formulaId => integer().nullable().references(CompoundingFormulas, #id)();
  IntColumn get transactionId => integer().references(SaleTransactions, #id)();
  TextColumn get customName => text().nullable()(); // for ad-hoc compounding
  RealColumn get totalComponentCost => real()();
  RealColumn get sellPrice => real()();
  IntColumn get qtyPrepared => integer()();
  IntColumn get preparedBy => integer().nullable().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get deviceId => text().nullable()();
}

@DataClassName('CompoundingTransactionItem')
class CompoundingTransactionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get compoundingTransactionId => integer().references(CompoundingTransactions, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get batchId => integer().references(StockBatches, #id)();
  RealColumn get qtyUsed => real()(); // base_unit used
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
  CsvImportLogs,
  CashierShifts,
  CashMovements,
  ReturnTransactions,
  ReturnItems,
  Suppliers,
  PurchaseOrders,
  PurchaseOrderItems,
  PurchaseReceivingItems,
  Patients,
  Prescriptions,
  CompoundingFormulas,
  CompoundingIngredients,
  CompoundingTransactions,
  CompoundingTransactionItems,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.defaultConnection() => AppDatabase(openConnection());

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(stockAdjustments);
          }
          if (from < 3) {
            await m.addColumn(cashierShifts, cashierShifts.discrepancyReason);
          }
          if (from < 4) {
            await m.createTable(csvImportLogs);
          }
          if (from < 5) {
            await m.addColumn(suppliers, suppliers.paymentTerms);
            await m.addColumn(suppliers, suppliers.leadTimeDays);
            await m.addColumn(suppliers, suppliers.isActive);
            await m.addColumn(suppliers, suppliers.updatedAt);
            await m.createTable(purchaseReceivingItems);
          }
          if (from < 6) {
            await m.createTable(patients);
            await m.createTable(prescriptions);
            await m.addColumn(saleTransactions, saleTransactions.patientId);
          }
          if (from < 7) {
            await m.createTable(compoundingFormulas);
            await m.createTable(compoundingIngredients);
            await m.createTable(compoundingTransactions);
            await m.createTable(compoundingTransactionItems);
          }
          if (from < 8) {
            await m.addColumn(products, products.controlledCategory);
          }
          if (from < 9) {
            await m.createTable(cashMovements);
          }
          if (from < 10) {
            await m.addColumn(products, products.imagePath);
            await m.addColumn(users, users.photoPath);
          }
        },
      );
}
