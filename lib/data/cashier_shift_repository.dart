import 'package:drift/drift.dart';
import 'database.dart';

class CashierShiftRepository {
  CashierShiftRepository(this._db);

  final AppDatabase _db;

  /// Opens a new cashier shift with an opening cash balance.
  Future<CashierShift> openShift({
    required int cashierId,
    required double openingBalance,
  }) async {
    final active = await getActiveShift(cashierId);
    if (active != null) {
      return active;
    }

    final id = await _db.into(_db.cashierShifts).insert(
          CashierShiftsCompanion.insert(
            cashierId: cashierId,
            openingBalance: openingBalance,
            status: 'open',
            openedAt: Value(DateTime.now()),
          ),
        );

    return (_db.select(_db.cashierShifts)..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }

  /// Closes an active cashier shift and calculates expected cash and discrepancy.
  Future<CashierShift> closeShift({
    required int shiftId,
    required double actualCash,
  }) async {
    final shift = await (_db.select(_db.cashierShifts)
          ..where((tbl) => tbl.id.equals(shiftId)))
        .getSingle();

    final now = DateTime.now();

    // Calculate total cash sales during this shift period
    final cashTxns = await (_db.select(_db.saleTransactions)
          ..where((tbl) =>
              tbl.cashierId.equals(shift.cashierId) &
              tbl.paymentMethod.equals('Cash') &
              tbl.createdAt.isBiggerOrEqualValue(shift.openedAt)))
        .get();

    final totalCashSales = cashTxns.fold<double>(0, (sum, t) => sum + t.totalAmount);
    final expectedCash = shift.openingBalance + totalCashSales;
    final discrepancy = actualCash - expectedCash;

    final updated = shift.copyWith(
      expectedCash: Value(expectedCash),
      actualCash: Value(actualCash),
      discrepancy: Value(discrepancy),
      status: 'closed',
      closedAt: Value(now),
    );

    await _db.update(_db.cashierShifts).replace(updated);
    return updated;
  }

  /// Returns the currently active (open) shift for a cashier, or null if none.
  Future<CashierShift?> getActiveShift(int cashierId) async {
    return (_db.select(_db.cashierShifts)
          ..where((tbl) =>
              tbl.cashierId.equals(cashierId) & tbl.status.equals('open')))
        .getSingleOrNull();
  }

  /// Returns all past and active cashier shifts ordered by open date DESC.
  Future<List<CashierShift>> listShifts() async {
    return (_db.select(_db.cashierShifts)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.openedAt)]))
        .get();
  }
}
