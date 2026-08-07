import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/sipnap_export_service.dart';

void main() {
  late AppDatabase db;
  late SipnapExportService sipnapService;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    sipnapService = SipnapExportService(db);

    // Controlled narcotic drug
    await db.into(db.products).insert(
          ProductsCompanion.insert(
            id: const Value(20),
            barcode: '8999990001',
            internalCode: 'NAR-01',
            name: 'Codeine 10mg',
            activeIngredient: 'Codeine Phosphate',
            ingredientPct: 100,
            baseUnit: 'tablet',
            purchaseUnit: 'box',
            unitsPerPurchaseUnit: 100,
            costPricePerBaseUnit: 1000,
            marginPct: 30,
            reorderThreshold: 50,
            isControlled: const Value(true),
            controlledCategory: const Value('Narkotika'),
            category: 'Narcotic',
            createdBy: 'admin',
          ),
        );

    // Add stock batch
    await db.into(db.stockBatches).insert(
          StockBatchesCompanion.insert(
            productId: 20,
            batchNo: 'BATCH-CODEINE-01',
            receivedDate: DateTime(2026, 7, 1),
            expiryDate: DateTime(2028, 1, 1),
            qtyReceived: 200,
            qtyRemaining: 150,
            costPricePerBaseUnit: 1000,
            supplier: 'PT Kimia Farma',
            createdBy: 'admin',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('generateMonthlyReport and exportSipnapExcel calculate stock math correctly',
      () async {
    final rows = await sipnapService.generateMonthlyReport(year: 2026, month: 8);

    expect(rows, hasLength(1));
    expect(rows.first.productName, equals('Codeine 10mg'));
    expect(rows.first.category, equals('Narkotika'));
    expect(rows.first.closingStock, equals(150));

    final bytes = await sipnapService.exportSipnapExcel(
      year: 2026,
      month: 8,
      pharmacyName: 'Apotek Tes',
      siaNo: 'SIA-001',
    );

    expect(bytes, isNotEmpty);
  });
}
