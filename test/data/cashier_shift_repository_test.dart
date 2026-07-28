import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/cashier_shift_repository.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/sale_repository.dart';

void main() {
  late AppDatabase db;
  late CashierShiftRepository shiftRepo;
  late SaleRepository saleRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    shiftRepo = CashierShiftRepository(db);
    saleRepo = SaleRepository(db);

    // Setup base user & product & batch
    await db.into(db.users).insert(
          UsersCompanion.insert(
            id: const Value(1),
            username: 'cashier1',
            passwordHash: 'hash',
            role: 'kasir',
          ),
        );
    await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: const Value(10),
            barcode: '899123456701',
            internalCode: 'P001',
            name: 'Amoxicillin 500mg',
            activeIngredient: 'Amoxicillin',
            ingredientPct: 100,
            baseUnit: 'tablet',
            purchaseUnit: 'box',
            unitsPerPurchaseUnit: 100,
            costPricePerBaseUnit: 5000,
            marginPct: 20,
            reorderThreshold: 10,
            category: 'Obat Bebas',
            createdBy: 'admin',
          ),
        );
    await db.into(db.stockBatches).insert(
          StockBatchesCompanion.insert(
            id: const Value(101),
            productId: 10,
            batchNo: 'B001',
            receivedDate: DateTime.now(),
            expiryDate: DateTime.now().add(const Duration(days: 365)),
            qtyReceived: 100,
            qtyRemaining: 100,
            costPricePerBaseUnit: 5000,
            supplier: 'PT Pharm',
            createdBy: 'admin',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('openShift creates an active shift and getActiveShift returns it', () async {
    final shift = await shiftRepo.openShift(cashierId: 1, openingBalance: 100000);

    expect(shift.status, equals('open'));
    expect(shift.openingBalance, equals(100000));

    final active = await shiftRepo.getActiveShift(1);
    expect(active, isNotNull);
    expect(active?.id, equals(shift.id));

    // Calling openShift again while active returns same active shift
    final secondCall = await shiftRepo.openShift(cashierId: 1, openingBalance: 200000);
    expect(secondCall.id, equals(shift.id));
  });

  test('closeShift calculates expected cash and discrepancy correctly', () async {
    final shift = await shiftRepo.openShift(cashierId: 1, openingBalance: 100000);

    // Fetch product
    final prod = await (db.select(db.products)..where((p) => p.id.equals(10))).getSingle();

    // Perform cash sale of Rp 12,000
    await saleRepo.createSaleTransaction(
      cashierId: 1,
      items: [
        CartItemInput(product: prod, qtyBaseUnit: 2, unitPrice: 6000),
      ],
      paymentMethod: 'Cash',
    );

    // Counted actual cash = 112,000 (perfect balance)
    final closed = await shiftRepo.closeShift(shiftId: shift.id, actualCash: 112000);

    expect(closed.status, equals('closed'));
    expect(closed.expectedCash, equals(112000));
    expect(closed.actualCash, equals(112000));
    expect(closed.discrepancy, equals(0));

    final all = await shiftRepo.listShifts();
    expect(all, isNotEmpty);
  });

  test('closeShift handles shortage and overage correctly', () async {
    final shift = await shiftRepo.openShift(cashierId: 1, openingBalance: 50000);

    // Shortage case (Counted 45,000 when expected 50,000) -> disc = -5,000
    final closedShortage = await shiftRepo.closeShift(shiftId: shift.id, actualCash: 45000);
    expect(closedShortage.discrepancy, equals(-5000));

    // Overage case
    final shift2 = await shiftRepo.openShift(cashierId: 1, openingBalance: 50000);
    final closedOverage = await shiftRepo.closeShift(shiftId: shift2.id, actualCash: 55000);
    expect(closedOverage.discrepancy, equals(5000));
  });
}
