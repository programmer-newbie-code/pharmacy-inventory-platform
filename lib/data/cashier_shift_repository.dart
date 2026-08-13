import 'package:drift/drift.dart';
import 'database.dart';

class CashierShiftRepository {
  CashierShiftRepository(this._db);

  final AppDatabase _db;

  static const _discrepancyReasonRequired =
      'A discrepancy reason is required before closing an unbalanced shift.';

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
    String? discrepancyReason,
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

    // Calculate cash in and cash out movements
    final movements = await getCashMovementsForShift(shiftId);
    double totalCashIn = 0.0;
    double totalCashOut = 0.0;
    for (final m in movements) {
      if (m.movementType == 'cash_in') {
        totalCashIn += m.amount;
      } else if (m.movementType == 'cash_out') {
        totalCashOut += m.amount;
      }
    }

    final expectedCash = shift.openingBalance + totalCashSales + totalCashIn - totalCashOut;
    final discrepancy = actualCash - expectedCash;
    if (discrepancy != 0 && (discrepancyReason == null || discrepancyReason.trim().isEmpty)) {
      throw ArgumentError(_discrepancyReasonRequired);
    }

    final updated = shift.copyWith(
      expectedCash: Value(expectedCash),
      actualCash: Value(actualCash),
      discrepancy: Value(discrepancy),
      discrepancyReason: Value(discrepancy == 0 ? null : discrepancyReason!.trim()),
      status: 'closed',
      closedAt: Value(now),
    );

    await _db.update(_db.cashierShifts).replace(updated);
    return updated;
  }

  Future<CashierShift> reviewShift({
    required int shiftId,
    required int reviewedBy,
    String? reviewNote,
  }) async {
    return _db.transaction(() async {
      final shift = await (_db.select(_db.cashierShifts)..where((tbl) => tbl.id.equals(shiftId))).getSingle();
      if (shift.status != 'closed') throw StateError('Only closed shifts can be reviewed.');
      final reviewer = await (_db.select(_db.users)..where((tbl) => tbl.id.equals(reviewedBy))).getSingle();
      if (reviewer.role != 'admin') throw StateError('Only administrators can review shifts.');
      final updated = shift.copyWith(
        reviewedBy: Value(reviewedBy),
        reviewedAt: Value(DateTime.now()),
        reviewNote: Value(reviewNote == null || reviewNote.trim().isEmpty ? null : reviewNote.trim()),
      );
      await _db.update(_db.cashierShifts).replace(updated);
      return updated;
    });
  }

  /// Records a cash in or cash out movement (e.g. Owner profit withdrawal / Prive, operational expense, bank deposit, top-up).
  Future<CashMovement> recordCashMovement({
    required int shiftId,
    required String movementType,
    required String category,
    required double amount,
    String? notes,
    required int performedBy,
  }) async {
    final id = await _db.into(_db.cashMovements).insert(
          CashMovementsCompanion.insert(
            shiftId: shiftId,
            movementType: movementType,
            category: category,
            amount: amount,
            notes: Value(notes),
            performedBy: performedBy,
            createdAt: Value(DateTime.now()),
          ),
        );
    return (_db.select(_db.cashMovements)..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }

  /// Returns all cash movements for a given shift.
  Future<List<CashMovement>> getCashMovementsForShift(int shiftId) async {
    return (_db.select(_db.cashMovements)
          ..where((tbl) => tbl.shiftId.equals(shiftId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
  }

  /// Returns all cash movements within a date range.
  Future<List<CashMovement>> getCashMovementsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return (_db.select(_db.cashMovements)
          ..where((tbl) =>
              tbl.createdAt.isBiggerOrEqual(Variable(startDate)) &
              tbl.createdAt.isSmallerOrEqual(Variable(endDate)))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
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
